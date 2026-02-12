import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';

import '../fixtures/mock_ai_client.dart';
import '../test_helpers.dart';

void main() {
  group('ChatScreen', () {
    late ChatSession session;

    setUp(() {
      session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
      );
      // Tests expect the standard chat UI, not onboarding.
      session.setMode(SessionMode.agentBuilder);
    });

    tearDown(() {
      session.dispose();
    });

    testWidgets('shows empty state with suggestions',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      // Empty state
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(
        find.text('Say or type something to get started'),
        findsOneWidget,
      );

      // Suggestion chips
      expect(find.text('Create a GitHub automation agent'), findsOneWidget);
      expect(find.text('Show my agents'), findsOneWidget);
      expect(find.text('Plan a trip'), findsOneWidget);

      // Input bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // App bar
      expect(find.text('clawfree'), findsOneWidget);
    });

    testWidgets('send button is enabled when not processing',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('typing text and sending adds user message',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      // Type a message
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // User message should appear in session
      expect(session.messages.any((m) => m.isUser && m.text == 'Hello'), isTrue);

      // Pump frames to let generation complete
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('tapping suggestion chip sends message',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      // Tap a suggestion chip
      await tester.tap(find.text('Show my agents'));
      await tester.pump();

      // Message should be in session
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Show my agents'),
        isTrue,
      );

      // Pump frames
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('initially shows no processing indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('export button is shown', (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('export button shows snackbar when no config',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();

      expect(find.text('No agent config to export. Create an agent first.'),
          findsOneWidget);
    });
  });

  group('ChatScreen with STT', () {
    late ChatSession session;
    late MockSttService sttService;

    setUp(() {
      session = ChatSession(
        aiClient: MockAiClient(),
        ttsService: MockTtsService(),
      );
      session.setMode(SessionMode.agentBuilder);
      sttService = MockSttService();
    });

    tearDown(() {
      session.dispose();
      sttService.dispose();
    });

    testWidgets('shows mic button when STT is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session, sttService: sttService));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('no mic button when STT is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byIcon(Icons.mic_none), findsNothing);
    });

    testWidgets('mic button toggles to listening state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session, sttService: sttService));

      // Tap mic button
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();

      // Should now show active mic icon
      expect(find.byIcon(Icons.mic), findsAtLeast(1));
    });

    testWidgets('text field shows listening hint when listening',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildChatTestApp(session, sttService: sttService));

      // Tap mic to start listening
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();

      expect(find.text('Listening...'), findsOneWidget);
    });
  });
}
