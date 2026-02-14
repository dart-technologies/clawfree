import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/voice/tts_service.dart';

void main() {
  group('E2E: Multi-turn refinement flow', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      session = ChatSession(aiClient: demoClient, ttsService: MockTtsService());
    });

    tearDown(() {
      session.dispose();
    });

    test('create agent then rename produces updateComponents response', () async {
      // Turn 1: Create
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have at least user + AI messages
      expect(session.messages.length, greaterThanOrEqualTo(2));

      // User message
      final user1 = session.messages.firstWhere((m) => m.isUser);
      expect(user1.text, 'Create an agent');

      // AI text should mention agent creation
      final ai1 = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .first;
      expect(ai1.text, isNotNull);
      expect(ai1.text!.toLowerCase(), contains('agent'));

      // Turn 2: Rename
      await session.sendMessage('Rename it to GitDigest Bot');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have more messages now
      final userMessages = session.messages.where((m) => m.isUser).toList();
      expect(userMessages.length, 2);
      expect(userMessages[1].text, 'Rename it to GitDigest Bot');

      // The AI response for rename should be present
      final aiMessages = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .toList();
      expect(aiMessages.length, greaterThanOrEqualTo(2));

      // The second turn's AI text should mention renaming.
      // Due to async text streaming, the text may be in any of the AI messages.
      final allAiText = aiMessages.map((m) => m.text ?? '').join(' ');
      expect(allAiText.toLowerCase(), contains('updated'));
    });

    test(
      'create agent then add browser tool produces updateComponents response',
      () async {
        // Turn 1: Create
        await session.sendMessage('Create an agent');
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Turn 2: Add tool
        await session.sendMessage('Add browser tool');
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Should have user messages for both turns
        final userMessages = session.messages.where((m) => m.isUser).toList();
        expect(userMessages.length, 2);
        expect(userMessages[0].text, 'Create an agent');
        expect(userMessages[1].text, 'Add browser tool');

        // The AI response for "add" should mention browser
        final aiMessages = session.messages
            .where((m) => !m.isUser && !m.isSurface)
            .toList();
        expect(aiMessages.length, greaterThanOrEqualTo(2));

        // Due to async text streaming, the text may be in any of the AI messages.
        final allAiText = aiMessages.map((m) => m.text ?? '').join(' ');
        expect(allAiText.toLowerCase(), contains('browser'));
      },
    );

    test('help command returns help text', () async {
      await session.sendMessage('help');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .toList();
      expect(aiMessages, isNotEmpty);

      final helpText = aiMessages.first.text ?? '';
      expect(helpText, contains('Create an agent'));
    });

    test('test the agent returns confirmation text', () async {
      await session.sendMessage('test the agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .toList();
      expect(aiMessages, isNotEmpty);

      final testText = aiMessages.first.text ?? '';
      expect(testText.toLowerCase(), contains('ready to test'));
    });

    test('deploy command returns deployment confirmation', () async {
      await session.sendMessage('deploy the agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .toList();
      expect(aiMessages, isNotEmpty);

      final deployText = aiMessages.first.text ?? '';
      expect(deployText.toLowerCase(), contains('deploy'));
    });

    test('multi-turn: create -> rename -> add -> test', () async {
      // Simulate a full multi-turn conversation
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await session.sendMessage('Rename it to MyBot');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await session.sendMessage('Add browser tool');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await session.sendMessage('Test the agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have 4 user messages
      final userMessages = session.messages.where((m) => m.isUser).toList();
      expect(userMessages.length, 4);

      // Session should not be stuck processing
      expect(session.isProcessing, isFalse);

      // All turns should have AI responses
      final aiMessages = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .toList();
      expect(aiMessages.length, greaterThanOrEqualTo(4));
    });

    test('delete command after creation', () async {
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await session.sendMessage('Delete the agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages
          .where((m) => !m.isUser && !m.isSurface)
          .toList();
      expect(aiMessages.length, greaterThanOrEqualTo(2));

      final deleteText = aiMessages.last.text ?? '';
      expect(deleteText.toLowerCase(), contains('deleted'));
    });

    test('session is never stuck processing after all turns', () async {
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(session.isProcessing, isFalse);

      await session.sendMessage('Rename it');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(session.isProcessing, isFalse);

      await session.sendMessage('help');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(session.isProcessing, isFalse);
    });
  });
}
