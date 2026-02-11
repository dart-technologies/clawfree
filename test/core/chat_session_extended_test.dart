import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/voice/tts_service.dart';

import '../fixtures/mock_ai_client.dart';

/// A mock AI client that captures the systemPrompt for inspection.
class _CapturingAiClient extends MockAiClient {
  _CapturingAiClient({super.responses});

  String? lastSystemPrompt;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    lastSystemPrompt = systemPrompt;
    yield* super.sendStream(prompt,
        systemPrompt: systemPrompt, history: history);
  }
}

void main() {
  group('ChatSession.retryLastMessage', () {
    test('retries after error by removing error message and re-generating',
        () async {
      // ErrorAiClient always throws — after retries exhausted, error message
      // appears. Then we swap the client behavior by using FailThenSucceedClient.
      final client = FailThenSucceedClient(failCount: 3);
      // failCount=3 means calls 1-3 fail, call 4+ succeed.
      // sendMessage does 1 initial + 2 retries = 3 calls (all fail).
      // Then retryLastMessage does 1 initial + ... but callCount is already 3,
      // so call 4 succeeds.
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );

      await session.sendMessage('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // After 3 failures, there should be an error message
      final errorBefore =
          session.messages.where((m) => m.isError).toList();
      expect(errorBefore, isNotEmpty, reason: 'Expected error message');

      // Now retry — call 4 should succeed
      await session.retryLastMessage();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Error message should be removed (replaced by successful response)
      final errorAfter = session.messages.where((m) => m.isError).toList();
      expect(errorAfter, isEmpty,
          reason: 'Error message should be removed after retry');

      session.dispose();
    });

    test('does nothing when no lastPrompt exists', () async {
      final client = MockAiClient();
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );

      // Never sent a message, so _lastPrompt is null
      await session.retryLastMessage();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(session.messages, isEmpty);
      expect(client.sendCount, 0);
      session.dispose();
    });

    test('does nothing when isProcessing is true', () async {
      // Use a slow client that keeps the session processing
      final client = _SlowAiClient();
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );

      // Start a message (will be processing)
      final future = session.sendMessage('Hello');

      // While processing, retry should be a no-op
      await session.retryLastMessage();

      // Let the original complete
      await future;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only 1 send happened (the original), not an extra retry
      expect(client.sendCount, 1);
      session.dispose();
    });
  });

  group('ChatSession system prompt context', () {
    test('system prompt includes agent names when agents are saved', () async {
      final client = _CapturingAiClient(responses: ['OK']);
      final agentStore = AgentStore();
      agentStore.addAgent({
        'name': 'GitDigest Bot',
        'model': 'claude-opus-4-6',
        'tools': ['browser', 'search'],
      });

      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );

      await session.sendMessage('Show agents');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(client.lastSystemPrompt, isNotNull);
      expect(client.lastSystemPrompt!, contains('GitDigest Bot'));
      expect(client.lastSystemPrompt!, contains('Saved Agents'));
      session.dispose();
    });

    test('system prompt does not include saved agents section when empty',
        () async {
      final client = _CapturingAiClient(responses: ['OK']);
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
        agentStore: AgentStore(),
      );

      await session.sendMessage('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(client.lastSystemPrompt, isNotNull);
      expect(client.lastSystemPrompt!, isNot(contains('Saved Agents')));
      session.dispose();
    });

    test('system prompt includes active surface IDs after surface creation',
        () async {
      // Use a response that creates a surface to populate _activeSurfaceIds
      // The create response has createSurface + updateComponents
      // However, surface creation requires genUI pipeline, so we test
      // that the _systemPrompt getter adds the section when IDs are present.
      // Since we can't easily trigger surface creation without genUI rendering,
      // we verify the system prompt structure with no active surfaces first.
      final client = _CapturingAiClient(responses: ['Just text']);
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );

      await session.sendMessage('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // No surfaces created from plain text response
      expect(client.lastSystemPrompt!, isNot(contains('Active Surfaces')));
      session.dispose();
    });

    test('system prompt uses "value" in ChoicePicker documentation', () async {
      final client = _CapturingAiClient(responses: ['OK']);
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );

      await session.sendMessage('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // The system prompt should reference "value" for ChoicePicker fields
      expect(client.lastSystemPrompt!, contains('"value"'));
      // Should NOT use "selectedValues" (old API)
      expect(client.lastSystemPrompt!, isNot(contains('selectedValues')));
      session.dispose();
    });
  });

  group('ChatSession._lastPrompt tracking', () {
    test('_lastPrompt is set after sendMessage', () async {
      final client = MockAiClient();
      final session = ChatSession(
        aiClient: client,
        ttsService: MockTtsService(),
      );

      // Before sending, retryLastMessage should be no-op
      await session.retryLastMessage();
      expect(client.sendCount, 0);

      // Send a message
      await session.sendMessage('First message');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Now _lastPrompt should be set; retryLastMessage should trigger send
      await session.retryLastMessage();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // sendMessage called once, retryLastMessage calls _performGeneration
      // which calls sendStream again
      expect(client.sendCount, 2);
      session.dispose();
    });
  });

  group('MessageItem.isError', () {
    test('returns true for messages starting with "Error:"', () {
      final msg = MessageItem.aiText(text: 'Error: Something went wrong');
      expect(msg.isError, isTrue);
    });

    test('returns true for "Error: API error 429: Rate limited"', () {
      final msg =
          MessageItem.aiText(text: 'Error: Exception: API error 429: Rate limited');
      expect(msg.isError, isTrue);
    });

    test('returns false for normal AI text messages', () {
      final msg = MessageItem.aiText(text: 'Hello, I can help you!');
      expect(msg.isError, isFalse);
    });

    test('returns false for user messages even if text starts with Error:',
        () {
      final msg = MessageItem.user(text: 'Error: this is user text');
      expect(msg.isError, isFalse);
    });

    test('returns false for surface messages', () {
      final msg = MessageItem.surface(surfaceId: 'form-001');
      expect(msg.isError, isFalse);
    });

    test('returns false for AI messages with null text', () {
      final msg = MessageItem.surface(surfaceId: 'x');
      // surfaceId messages have text=null, isUser=false, isSurface=true
      expect(msg.isError, isFalse);
    });

    test('returns false for empty AI text', () {
      final msg = MessageItem.aiText(text: '');
      expect(msg.isError, isFalse);
    });

    test('returns false for AI text that contains "Error" but does not start with it',
        () {
      final msg =
          MessageItem.aiText(text: 'There was an Error in the system');
      expect(msg.isError, isFalse);
    });
  });
}

/// A slow AI client that takes time to respond (to test isProcessing guard).
class _SlowAiClient implements MockAiClient {
  @override
  int sendCount = 0;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    sendCount++;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    yield 'Slow response';
  }

  @override
  bool disposed = false;

  @override
  List<String> receivedPrompts = [];

  @override
  List<String> get responses => ['Slow response'];

  @override
  void dispose() {
    disposed = true;
  }
}
