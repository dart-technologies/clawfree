import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/voice_controller.dart';

import '../fixtures/mock_ai_client.dart';

void main() {
  group('ChatSession', () {
    late MockAiClient mockClient;
    late MockTtsService mockTts;
    late MockSttService mockStt;
    late VoiceController voiceController;
    late AgentStore agentStore;

    setUp(() {
      mockClient = MockAiClient();
      mockTts = MockTtsService();
      mockStt = MockSttService();
      voiceController = VoiceController(stt: mockStt, tts: mockTts);
      agentStore = AgentStore();
    });

    test('starts with empty messages', () {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      expect(session.messages, isEmpty);
      expect(session.isProcessing, isFalse);
      session.dispose();
    });

    test('sendMessage adds user message', () async {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      await session.sendMessage('Hello');
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Hello'),
        isTrue,
      );
      session.dispose();
    });

    test('sendMessage adds AI response', () async {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      await session.sendMessage('Hello');
      // Wait for debounce to flush
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      session.dispose();
    });

    test('empty message is ignored', () async {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      await session.sendMessage('');
      expect(session.messages, isEmpty);
      expect(mockClient.sendCount, 0);
      session.dispose();
    });

    test('isProcessing becomes true during generation', () async {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      var wasProcessing = false;
      session.addListener(() {
        if (session.isProcessing) wasProcessing = true;
      });
      await session.sendMessage('Test');
      expect(wasProcessing, isTrue);
      expect(session.isProcessing, isFalse); // After completion
      session.dispose();
    });

    test('agentStore is accessible', () {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      expect(session.agentStore, same(agentStore));
      session.dispose();
    });

    test('creates default agentStore if not provided', () {
      final session = ChatSession(aiClient: mockClient, ttsService: mockTts);
      expect(session.agentStore, isNotNull);
      session.dispose();
    });

    test('notifies listeners on message changes', () async {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      var notifyCount = 0;
      session.addListener(() => notifyCount++);
      await session.sendMessage('Hello');
      expect(notifyCount, greaterThan(0));
      session.dispose();
    });

    test('messages list is unmodifiable', () {
      final session = ChatSession(
        aiClient: mockClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      expect(
        () => (session.messages as List).add(MessageItem.user(text: 'hack')),
        throwsUnsupportedError,
      );
      session.dispose();
    });
  });

  group('ChatSession error handling', () {
    test('retries on error up to maxRetries', () async {
      final client = FailThenSucceedClient(failCount: 2);
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );
      await session.sendMessage('Test');
      // Should have called 3 times: 1 initial + 2 retries
      expect(client.callCount, 3);
      session.dispose();
    });

    test('shows error message after max retries exhausted', () async {
      final client = FailThenSucceedClient(failCount: 10); // Always fails
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );
      await session.sendMessage('Test');
      final errorMessages = session.messages.where(
        (m) => !m.isUser && m.text?.startsWith('Error:') == true,
      );
      expect(errorMessages, isNotEmpty);
      session.dispose();
    });
  });

  group('ChatSession self-correction', () {
    test('does not retry when no JSON in response', () async {
      final client = MockAiClient(responses: ['Just plain text response']);
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );
      await session.sendMessage('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Should not have retried — no JSON block detected
      expect(client.sendCount, 1);
      session.dispose();
    });

    test('plain text response does not trigger correction', () async {
      final client = MockAiClient(
        responses: ['I can help you create an agent!'],
      );
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Only 1 call — no JSON means no self-correction
      expect(client.sendCount, 1);
      // Should have user message + AI text message
      expect(session.messages.length, greaterThanOrEqualTo(2));
      session.dispose();
    });
  });

  group('ChatSession exportAgentConfig', () {
    test('returns null when no agent config in history', () {
      final session = ChatSession(
        aiClient: MockAiClient(),
        voiceController: VoiceController(
          stt: MockSttService(),
          tts: MockTtsService(),
        ),
      );
      expect(session.exportAgentConfig(), isNull);
      session.dispose();
    });
  });

  group('MessageItem', () {
    test('user message has correct properties', () {
      final msg = MessageItem.user(text: 'Hello');
      expect(msg.isUser, isTrue);
      expect(msg.isSurface, isFalse);
      expect(msg.text, 'Hello');
      expect(msg.surfaceId, isNull);
    });

    test('aiText message has correct properties', () {
      final msg = MessageItem.aiText(text: 'Response');
      expect(msg.isUser, isFalse);
      expect(msg.isSurface, isFalse);
      expect(msg.text, 'Response');
    });

    test('surface message has correct properties', () {
      final msg = MessageItem.surface(surfaceId: 'form-001');
      expect(msg.isUser, isFalse);
      expect(msg.isSurface, isTrue);
      expect(msg.surfaceId, 'form-001');
      expect(msg.text, isNull);
    });

    test('text is mutable', () {
      final msg = MessageItem.aiText(text: '');
      msg.text = 'Updated';
      expect(msg.text, 'Updated');
    });
  });
}
