import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/ui/clawfree_icons.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/voice_controller.dart';
import 'package:clawfree/src/ui/layouts/voice_orb.dart';

import '../fixtures/mock_ai_client.dart';
import '../test_helpers.dart';

void main() {
  group('ChatScreen', () {
    late ChatSession session;
    late VoiceController voiceController;

    setUp(() {
      voiceController = VoiceController(
        stt: MockSttService(),
        tts: MockTtsService(),
      );
      session = ChatSession(
        aiClient: MockAiClient(),
        voiceController: voiceController,
      );
      // Tests expect the standard chat UI, not onboarding.
      session.setMode(SessionMode.agentBuilder);
    });

    tearDown(() {
      session.dispose();
    });

    testWidgets('shows empty state with suggestions', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Empty state
      expect(find.text('READY FOR COMMANDS'), findsOneWidget);

      // Suggestion chips
      expect(find.text('CREATE AN AGENT'), findsOneWidget);
      expect(find.text('MANAGE OPENCLAW'), findsOneWidget);

      // Unified Bar (default)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(VoiceOrb), findsOneWidget);

      // App bar (contains CLAWFREE in technical font)
      expect(find.text('CLAWFREE'), findsOneWidget);
    });

    testWidgets('send button is enabled when not processing', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Type some text to show send button
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      final sendButton = find.byIcon(ClawfreeIcons.send);
      expect(sendButton, findsOneWidget);
    });

    testWidgets('typing text and sending adds user message', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Type a message
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump(); // flush text into controller
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(); // process submit

      // User message should appear in session
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Hello'),
        isTrue,
      );

      // Pump frames to let generation complete
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('tapping suggestion chip sends message', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Tap a suggestion chip
      await tester.tap(find.text('MANAGE OPENCLAW'));
      await tester.pump(); // dispatch tap
      await tester.pump(); // process async callback

      // Message should be in session
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Manage OpenClaw'),
        isTrue,
      );

      // Pump frames
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('initially shows no processing indicator', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('export button is shown in drawer', (WidgetTester tester) async {
      setTestViewport(tester, size: const Size(599, 800));
      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer directly
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.download), findsOneWidget);
    }, skip: true);

    testWidgets('export button shows snackbar when no config', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester, size: const Size(599, 800));
      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer directly
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pump(const Duration(seconds: 2));

      // Tap Export ListTile
      await tester.ensureVisible(find.text('Export Agent Config'));
      await tester.tap(find.text('Export Agent Config'));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('No agent config to export. Create an agent first.'),
        findsOneWidget,
      );
    }, skip: true);
  });

  group('ChatScreen with STT', () {
    late ChatSession session;
    late VoiceController voiceController;
    late MockSttService sttService;

    setUp(() {
      sttService = MockSttService();
      voiceController = VoiceController(stt: sttService, tts: MockTtsService());
      session = ChatSession(
        aiClient: MockAiClient(),
        voiceController: voiceController,
      );
      session.setMode(SessionMode.agentBuilder);
    });

    tearDown(() {
      session.dispose();
      sttService.dispose();
    });

    testWidgets('shows mic button when VoiceController has STT', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(
        buildChatTestApp(session, voiceController: voiceController),
      );

      // VoiceOrb is the mic button
      expect(find.byType(VoiceOrb), findsOneWidget);
    });

    testWidgets('mic button toggles to listening state', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(
        buildChatTestApp(session, voiceController: voiceController),
      );

      // Tap mic button (VoiceOrb)
      await tester.tap(find.byType(VoiceOrb));
      await tester.pump();

      expect(voiceController.isListening, isTrue);
    });

    testWidgets('text field shows listening hint when listening', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(
        buildChatTestApp(session, voiceController: voiceController),
      );

      // Start listening (VoiceOrb in ChatInputBar)
      await tester.tap(find.byType(VoiceOrb));
      await tester.pump();

      expect(find.text('Listening...'), findsOneWidget);
    });
  });
}
