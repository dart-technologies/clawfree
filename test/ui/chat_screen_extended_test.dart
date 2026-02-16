import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/voice/tts_service.dart';

import '../fixtures/mock_ai_client.dart';
import '../test_helpers.dart';

void main() {
  group('ChatScreen error + retry', () {
    testWidgets('error message shows retry button after retries exhausted', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      final client = ErrorAiClient();
      final session = ChatSession(aiClient: client);

      await tester.pumpWidget(buildChatTestApp(session));

      // runAsync runs real async; sendMessage retries up to _maxRetries (2)
      // so 3 total attempts, each with microtask flushes.
      await tester.runAsync(() async {
        await session.sendMessage('Hello');
        // Extra delay to let all retries + finally blocks settle
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      // Pump multiple frames to process notifyListeners from retries
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should have an error message in the session
      final errorMessages = session.messages.where((m) => m.isError);
      expect(
        errorMessages,
        isNotEmpty,
        reason: 'Expected at least one error message after retries',
      );

      // The retry ("Try again") button should be rendered
      expect(find.text('Try again'), findsOneWidget);

      session.dispose();
    });

    testWidgets('retry button has refresh icon', (WidgetTester tester) async {
      setTestViewport(tester);
      final client = ErrorAiClient();
      final session = ChatSession(aiClient: client);

      await tester.pumpWidget(buildChatTestApp(session));

      await tester.runAsync(() async {
        await session.sendMessage('test');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byIcon(Icons.refresh), findsOneWidget);

      session.dispose();
    });

    testWidgets('error message text contains "Error:"', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      final client = ErrorAiClient();
      final session = ChatSession(aiClient: client);

      await tester.pumpWidget(buildChatTestApp(session));

      await tester.runAsync(() async {
        await session.sendMessage('trigger error');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('Error:'), findsOneWidget);

      session.dispose();
    });
  });

  group('ChatScreen shimmer skeleton', () {
    testWidgets('ChatScreen renders without crash when message is sent', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      final session = ChatSession(
        aiClient: MockAiClient(responses: ['Just text']),
      );

      await tester.pumpWidget(buildChatTestApp(session));

      await tester.runAsync(() => session.sendMessage('Hello'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No crash -- the screen is stable
      expect(find.text('CLAWFREE'), findsOneWidget);

      session.dispose();
    });
  });

  group('ChatScreen platform-adaptive input', () {
    testWidgets('on macOS, CupertinoTextField is used for input', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
      );

      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      session.dispose();
      debugDefaultTargetPlatformOverride = null;
    }, skip: true);

    testWidgets('on Android, TextField is used for input', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
      );

      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNothing);

      session.dispose();
      debugDefaultTargetPlatformOverride = null;
    }, skip: true);

    testWidgets('on macOS, send button is CupertinoButton', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
      );

      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byType(CupertinoButton), findsAtLeast(1));

      session.dispose();
      debugDefaultTargetPlatformOverride = null;
    }, skip: true);
  });

  group('ChatScreen export dialog', () {
    testWidgets('export dialog shows agent name in title', (
      WidgetTester tester,
    ) async {
      final agentStore = AgentStore();
      agentStore.addAgent({
        'name': 'GitDigest Bot',
        'model': 'claude-opus-4-6',
        'tools': ['browser'],
        'channels': ['telegram'],
      });

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );

      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Export Agent Config'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('GitDigest Bot (OpenClaw)'), findsOneWidget);

      session.dispose();
    }, skip: true);

    testWidgets('export dialog has Copy button text and Close button', (
      WidgetTester tester,
    ) async {
      final agentStore = AgentStore();
      agentStore.addAgent({
        'name': 'TestAgent',
        'model': 'claude-opus-4-6',
        'tools': [],
        'channels': [],
      });

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );

      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Export Agent Config'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      session.dispose();
    }, skip: true);

    testWidgets('export dialog has copy icon', (WidgetTester tester) async {
      final agentStore = AgentStore();
      agentStore.addAgent({
        'name': 'TestAgent',
        'model': 'opus',
        'tools': [],
        'channels': [],
      });

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );

      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Export Agent Config'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.copy), findsOneWidget);

      session.dispose();
    }, skip: true);

    testWidgets('export dialog shows JSON content', (
      WidgetTester tester,
    ) async {
      final agentStore = AgentStore();
      agentStore.addAgent({
        'name': 'MyBot',
        'model': 'claude-opus-4-6',
        'tools': ['browser', 'search'],
        'channels': ['telegram'],
      });

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );

      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Export Agent Config'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('MyBot'), findsWidgets);
      expect(find.textContaining('claude-opus-4-6'), findsWidgets);

      session.dispose();
    }, skip: true);

    testWidgets('Close button dismisses the export dialog', (
      WidgetTester tester,
    ) async {
      final agentStore = AgentStore();
      agentStore.addAgent({
        'name': 'Bot',
        'model': 'opus',
        'tools': [],
        'channels': [],
      });

      final session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );

      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Export Agent Config'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Bot (OpenClaw)'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Bot (OpenClaw)'), findsNothing);

      session.dispose();
    }, skip: true);
  });
}
