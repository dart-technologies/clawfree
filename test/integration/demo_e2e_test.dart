import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';

import 'package:clawfree/src/ui/clawfree_icons.dart';
import 'package:clawfree/src/ui/layouts/voice_orb.dart';

import '../fixtures/mock_ai_client.dart';
import '../test_helpers.dart';

/// E2E integration tests exercising the full demo pipeline:
/// DemoCacheAiClient -> ChatSession -> ChatScreen widget.
///
/// These tests use real DemoCacheAiClient (not mocks) to verify that
/// cached responses flow correctly through the entire system.

void main() {
  group('E2E: Create agent flow', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;
    late AgentStore agentStore;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      agentStore = AgentStore();
      session = ChatSession(
        aiClient: demoClient,
        ttsService: MockTtsService(),
        agentStore: agentStore,
      );
    });

    tearDown(() {
      session.dispose();
    });

    test('session processes "create agent" and produces messages', () async {
      await session.sendMessage('Create an agent');

      // Wait for streaming + debounce
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have at least: user message + AI text
      expect(session.messages.length, greaterThanOrEqualTo(2));

      // User message present
      final userMsg = session.messages.firstWhere((m) => m.isUser);
      expect(userMsg.text, 'Create an agent');

      // AI text response present (non-empty)
      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText, isNotEmpty);
      expect(aiText.toLowerCase(), contains('agent'));
    });

    test('session is not processing after response completes', () async {
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(session.isProcessing, isFalse);
    });

    testWidgets('ChatScreen displays user message and AI response', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Verify empty state
      expect(find.text('Say something to get started'), findsOneWidget);

      // Send message via text field
      await tester.enterText(find.byType(TextField), 'Create an agent');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // User message should be in session
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Create an agent'),
        isTrue,
      );

      // Pump to let demo streaming complete
      await tester.pump(const Duration(seconds: 3));

      // AI text should appear
      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });

    testWidgets('suggestion chip triggers full demo flow', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Tap create suggestion chip
      await tester.tap(find.text('Create an agent'));
      await tester.pump();

      // User message sent
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Create an agent'),
        isTrue,
      );

      // Let demo client stream complete
      await tester.pump(const Duration(seconds: 3));

      // Should have AI response
      expect(session.messages.length, greaterThanOrEqualTo(2));
    });
  });

  group('E2E: Show dashboard flow', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      session = ChatSession(aiClient: demoClient, ttsService: MockTtsService());
    });

    tearDown(() {
      session.dispose();
    });

    test('session processes "show agents" and produces AI response', () async {
      await session.sendMessage('Show my agents');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // AI text should mention agents
      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('agents'));
    });

    testWidgets('dashboard chip sends and receives demo response', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      await tester.tap(find.text('Show my agents'));
      await tester.pump();

      expect(
        session.messages.any((m) => m.isUser && m.text == 'Show my agents'),
        isTrue,
      );

      await tester.pump(const Duration(seconds: 3));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });
  });

  group('E2E: Multi-turn conversation', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      session = ChatSession(aiClient: demoClient, ttsService: MockTtsService());
    });

    tearDown(() {
      session.dispose();
    });

    test('multiple messages accumulate in history', () async {
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await session.sendMessage('Show my agents');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have: user1, ai1, user2, ai2 (at least 4)
      expect(session.messages.length, greaterThanOrEqualTo(4));

      // Both user messages present
      final userMessages = session.messages.where((m) => m.isUser).toList();
      expect(userMessages.length, 2);
      expect(userMessages[0].text, 'Create an agent');
      expect(userMessages[1].text, 'Show my agents');
    });

    test('fallback response for unmatched prompt', () async {
      await session.sendMessage('What is the meaning of life?');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      // Default response mentions helping
      expect(aiText.toLowerCase(), contains('help'));
    });

    testWidgets('message list updates after sending via chip', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Send via chip (Create an agent is always visible)
      await tester.tap(find.text('Create an agent'));
      await tester.pump(const Duration(seconds: 3));

      // User message should be present
      expect(
        session.messages.any((m) => m.isUser && m.text == 'Create an agent'),
        isTrue,
      );
    });
  });

  group('E2E: Error recovery', () {
    test('session handles error client gracefully', () async {
      final failClient = AlwaysFailClient();
      final session = ChatSession(
        aiClient: failClient,
        ttsService: MockTtsService(),
      );

      await session.sendMessage('Test');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should show error message after retries exhausted
      final errorMessages = session.messages.where(
        (m) => !m.isUser && m.text?.startsWith('Error:') == true,
      );
      expect(errorMessages, isNotEmpty);
      expect(session.isProcessing, isFalse);

      session.dispose();
    });

    test('session continues working after error recovery', () async {
      final failOnce = FailOnceClient();
      final session = ChatSession(
        aiClient: failOnce,
        ttsService: MockTtsService(),
      );

      // First message — will fail then retry and succeed
      await session.sendMessage('First');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Session should not be stuck processing
      expect(session.isProcessing, isFalse);
      expect(session.messages, isNotEmpty);

      // Second message should work normally
      await session.sendMessage('Second');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final userMessages = session.messages.where((m) => m.isUser).toList();
      expect(userMessages.length, 2);

      session.dispose();
    });
  });

  group('E2E: STT integration', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;
    late MockSttService sttService;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      sttService = MockSttService();
      session = ChatSession(
        aiClient: demoClient,
        ttsService: MockTtsService(),
        sttService: sttService,
      );
    });

    tearDown(() {
      session.dispose();
      sttService.dispose();
    });

    testWidgets('mic button starts listening and shows hint', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(
        buildChatTestApp(session, sttService: sttService),
      );

      // VoiceOrb is the mic button in the unified bar
      expect(find.byType(VoiceOrb), findsOneWidget);

      // Tap to start listening
      await tester.tap(find.byType(VoiceOrb));
      await tester.pump();

      // Should show listening indicator
      expect(find.text('Listening...'), findsOneWidget);

      // Text field should be disabled when listening
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('export button works when no config exists', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildChatTestApp(session));

      // Open drawer to find download icon
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();

      expect(
        find.text('No agent config to export. Create an agent first.'),
        findsOneWidget,
      );
    }, skip: true);
  });

  group('E2E: App startup flow', () {
    testWidgets('empty state shows all expected elements', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester);
      final session = ChatSession(
        aiClient: DemoCacheAiClient(),
        ttsService: MockTtsService(),
      );
      // Ensure we are NOT in onboarding mode so the full PhoneLayout renders
      session.setMode(SessionMode.agentBuilder);

      await tester.pumpWidget(buildChatTestApp(session));

      // App bar
      expect(find.text('clawfree'), findsOneWidget);

      // Empty state elements - using ClawfreeIcons.mic
      expect(find.byIcon(ClawfreeIcons.mic), findsOneWidget);
      expect(find.text('Say something to get started'), findsOneWidget);

      // Suggestion chips
      expect(find.text('Create an agent'), findsOneWidget);
      expect(find.text('Show my agents'), findsOneWidget);

      // Unified Input bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(VoiceOrb), findsOneWidget);

      session.dispose();
    }, skip: true);
  });

  group('E2E: Tokyo Travel flow', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      session = ChatSession(aiClient: demoClient, ttsService: MockTtsService());
    });

    tearDown(() => session.dispose());

    test('"trip" keyword triggers travel setup response', () async {
      await session.sendMessage('Plan a trip');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('concierge'));
    });

    test('"trip" produces travel setup surface with city picker', () async {
      await session.sendMessage('Plan a trip');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'trip should produce a surface');
      expect(surfaces.first.surfaceId, 'travel-setup-001');
    });

    test('"travel" keyword triggers setup response', () async {
      await session.sendMessage(
        'Set up a travel agent for me, I\'m a total foodie',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'travel should produce a surface');
      expect(surfaces.first.surfaceId, 'travel-setup-001');
    });

    test('"foodie plan" compound keyword triggers itinerary', () async {
      await session.sendMessage('Show me the foodie plan for tokyo');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty);
      expect(surfaces.first.surfaceId, 'tokyo-itin-001');
    });

    test('"artsy plan" compound keyword triggers artsy itinerary', () async {
      await session.sendMessage('Show me the artsy plan for tokyo');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('art'));
    });

    test(
      '"outdoorsy plan" compound keyword triggers nature itinerary',
      () async {
        await session.sendMessage('Show me the outdoorsy plan for tokyo');
        await Future<void>.delayed(const Duration(milliseconds: 500));

        final aiMessages = session.messages.where(
          (m) => !m.isUser && !m.isSurface,
        );
        expect(aiMessages, isNotEmpty);
        final aiText = aiMessages.first.text ?? '';
        expect(aiText.toLowerCase(), contains('nature'));
      },
    );

    test('multi-turn: persona picker then foodie itinerary', () async {
      await session.sendMessage('Set up a travel agent');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      await session.sendMessage('Show me the foodie plan for tokyo');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Should have both surfaces
      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces.length, greaterThanOrEqualTo(2));

      final surfaceIds = surfaces.map((s) => s.surfaceId).toSet();
      expect(surfaceIds, contains('travel-setup-001'));
      expect(surfaceIds, contains('tokyo-itin-001'));
    });

    test('travel flow can be triggered via sendMessage', () async {
      await session.sendMessage('Plan a trip');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(
        session.messages.any((m) => m.isUser && m.text == 'Plan a trip'),
        isTrue,
      );

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });
  });

  group('E2E: Control Tower surfaces', () {
    late ChatSession session;

    setUp(() {
      session = ChatSession(
        aiClient: DemoCacheAiClient(chunkDelay: Duration.zero),
        ttsService: MockTtsService(),
      );
    });

    tearDown(() => session.dispose());

    // Skill Library
    test('"skill" keyword triggers skill library', () async {
      await session.sendMessage('Show me the skill library');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('skill'));
    });

    test('"skills" produces a genUI surface', () async {
      await session.sendMessage('Browse available skills');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'skills should produce a surface');
      expect(surfaces.first.surfaceId, 'skill-library-001');
    });

    // Audit Trail
    test('"audit" triggers audit log surface', () async {
      await session.sendMessage('Show the audit log');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'audit should produce a surface');
      expect(surfaces.first.surfaceId, 'audit-log-001');
    });

    // Analytics
    test('"analytics" triggers analytics surface', () async {
      await session.sendMessage('Show analytics dashboard');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(
        surfaces,
        isNotEmpty,
        reason: 'analytics should produce a surface',
      );
      expect(surfaces.first.surfaceId, 'analytics-001');
    });

    test('"performance" also triggers analytics', () async {
      await session.sendMessage('Check performance metrics');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(
        surfaces,
        isNotEmpty,
        reason: 'performance should produce a surface',
      );
      expect(surfaces.first.surfaceId, 'analytics-001');
    });

    // Security
    test('"security" triggers security surface', () async {
      await session.sendMessage('Security overview');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'security should produce a surface');
      expect(surfaces.first.surfaceId, 'security-001');
    });

    test('"compliance" also triggers security', () async {
      await session.sendMessage('Show compliance status');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(
        surfaces,
        isNotEmpty,
        reason: 'compliance should produce a surface',
      );
      expect(surfaces.first.surfaceId, 'security-001');
    });

    // Help updated
    test('"help" includes skill library mention', () async {
      await session.sendMessage('help');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('skill'));
    });
  });

  group('E2E: DemoCacheAiClient keyword coverage', () {
    late ChatSession session;

    setUp(() {
      session = ChatSession(
        aiClient: DemoCacheAiClient(chunkDelay: Duration.zero),
        ttsService: MockTtsService(),
      );
    });

    tearDown(() => session.dispose());

    test('"telegram" keyword triggers create response', () async {
      await session.sendMessage('Create a Telegram bot');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });

    test('"github" keyword triggers create response', () async {
      await session.sendMessage('Set up a GitHub integration');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });

    test('"dashboard" keyword triggers dashboard response', () async {
      await session.sendMessage('Open the dashboard');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });

    test('"agents" keyword triggers dashboard response', () async {
      await session.sendMessage('List all agents');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
    });

    test('"browse" triggers skill library', () async {
      await session.sendMessage('Browse what you can do');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty);
      expect(surfaces.first.surfaceId, 'skill-library-001');
    });

    test('"metrics" triggers analytics', () async {
      await session.sendMessage('Show me the metrics');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty);
      expect(surfaces.first.surfaceId, 'analytics-001');
    });

    test('"threats" triggers security', () async {
      await session.sendMessage('Any threats detected?');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty);
      expect(surfaces.first.surfaceId, 'security-001');
    });

    test('"events" triggers audit log', () async {
      await session.sendMessage('Show recent events');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty);
      expect(surfaces.first.surfaceId, 'audit-log-001');
    });
  });

  group('E2E: Surface creation from demo responses', () {
    late ChatSession session;

    setUp(() {
      session = ChatSession(
        aiClient: DemoCacheAiClient(chunkDelay: Duration.zero),
        ttsService: MockTtsService(),
      );
    });

    tearDown(() => session.dispose());

    test('"create" produces a genUI surface', () async {
      await session.sendMessage('Create an agent');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'create should produce a surface');
      expect(surfaces.first.surfaceId, 'agent-form-001');
    });

    test('"pair" produces a genUI surface', () async {
      await session.sendMessage('Pair a device');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'pair should produce a surface');
      expect(surfaces.first.surfaceId, 'pair-qr-001');
    });

    test('"manage" produces a genUI surface', () async {
      await session.sendMessage('Manage OpenClaw');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'manage should produce a surface');
      expect(surfaces.first.surfaceId, 'manage-001');
    });

    test('"health" produces a genUI surface', () async {
      await session.sendMessage('Check system health');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'health should produce a surface');
      expect(surfaces.first.surfaceId, 'health-001');
    });

    test('"health" response uses Vitals terminology', () async {
      await session.sendMessage('Check system health');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('vitals'));
    });

    test('"connect" produces a genUI surface', () async {
      await session.sendMessage('Connect to my gateway');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty, reason: 'connect should produce a surface');
      expect(surfaces.first.surfaceId, 'connect-gw-001');
    });

    test('"dashboard" produces a genUI surface', () async {
      await session.sendMessage('Show my agents');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(
        surfaces,
        isNotEmpty,
        reason: 'dashboard should produce a surface',
      );
      expect(surfaces.first.surfaceId, 'dashboard-001');
    });
  });
}
