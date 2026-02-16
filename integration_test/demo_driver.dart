import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/ui/chat_screen.dart';
import 'package:clawfree/src/ui/theme.dart';
import 'package:clawfree/src/voice/earcon_service.dart';
import 'package:clawfree/src/voice/platform_tts_service.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/voice_controller.dart';

/// macOS integration test that launches the real app UI as a desktop window
/// and drives the full demo workflow with simulated voice commands.
///
/// Ideal for screen recording the hackathon video — the VoiceOrb pulses,
/// word-by-word transcript builds, AI text streams with visible typing,
/// earcon chimes play on mic/surface events, and macOS TTS reads responses.
///
/// Run: flutter test integration_test/demo_driver.dart -d macos
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Render every vsync frame so the macOS window shows live UI (not just
  // "Test starting..."). Without this, frames only appear on pump() calls
  // which don't reliably push to the native window.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Demo workflow: create agent → save → plan trip → generate → book', (
    WidgetTester tester,
  ) async {
    // -----------------------------------------------------------------------
    // Set a consistent large window size for the two-panel layout.
    // Must be inside testWidgets to avoid 'inTest' assertion failure.
    // -----------------------------------------------------------------------
    debugPrint('[DemoDriver] Step 0: Setting surface size...');
    await binding.setSurfaceSize(const Size(1280, 800));
    // NOTE: Do NOT override tester.view.physicalSize / devicePixelRatio —
    // those create a virtual render target detached from the native macOS
    // NSView, causing the window to stay stuck on "Test starting...".
    await tester.pump();
    debugPrint('[DemoDriver] Step 0: Surface size set.');

    // -----------------------------------------------------------------------
    // Build demo dependencies with real audio
    // -----------------------------------------------------------------------

    // Earcon chimes: synthesised WAV tones for mic open/close, surface arrival,
    // thinking, booking confirm.
    final earcon = EarconService();
    await tester.runAsync(() => earcon.init());

    // Real macOS TTS (AVSpeechSynthesizer) for spoken AI responses.
    // MockSttService for controlled voice input simulation.
    final ttsService = PlatformTtsService();
    final voiceController = VoiceController(
      stt: MockSttService(),
      tts: ttsService,
      earcon: earcon,
    );

    // Slow chunk params for visible typing effect:
    //   chunkSize=8 (~1-2 words per chunk), chunkDelay=50ms between chunks.
    //   A 200-char response → ~25 chunks over 1.25 seconds of visible streaming.
    final demoClient = DemoCacheAiClient(
      chunkSize: 8,
      chunkDelay: const Duration(milliseconds: 50),
    );

    final agentStore = AgentStore();
    final session = ChatSession(
      aiClient: demoClient,
      voiceController: voiceController,
      agentStore: agentStore,
    );
    session.setMode(SessionMode.agentBuilder);

    // -----------------------------------------------------------------------
    // Pump the real app UI — dark mode for screen recording.
    // IMPORTANT: Never use pumpAndSettle() — VoiceOrb shader loops forever.
    // -----------------------------------------------------------------------
    await tester.pumpWidget(
      MaterialApp(
        theme: ClawfreeTheme.dark,
        home: ChatScreen(chatSession: session, showOnboarding: false),
      ),
    );
    await _pumpSettle(tester);

    // Ensure Agent voice is initialized at the start.
    await _setVoiceProfile(ttsService, isUser: false, tester: tester);

    // -----------------------------------------------------------------------
    // Step 1: User initiates flow
    //   → User speaks command (Male voice), Orb pulses, transcript builds,
    //     surface renders, Agent speaks response (Female voice).
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(
      tester,
      session,
      'Plan a 3-day foodie trip to Tokyo',
      ttsService,
    );

    expect(
      session.messages.any(
        (m) => m.isSurface && m.surfaceId == 'agent-form-001',
      ),
      isTrue,
      reason: 'Agent form surface should appear after create command',
    );

    // Let TTS finish reading + breathing room for widget init.
    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester, frames: 20);

    // -----------------------------------------------------------------------
    // Step 2: Save Agent
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(tester, session, 'Save Agent', ttsService);
    
    final nameFieldFinder = find.descendant(
      of: find.byKey(const Key('agent-form-001')),
      matching: find.byType(TextField),
    );
    expect(find.text('Travel Concierge'), findsOneWidget);
    await tester.enterText(nameFieldFinder, 'Travel Concierge');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpSettle(tester);
    
    final saveBtn = find.text('SAVE AGENT');
    expect(saveBtn, findsOneWidget);
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pump(const Duration(milliseconds: 1000));
    await _pumpSettle(tester);

    expect(agentStore.agents.length, 1);
    expect(session.sessionMode, SessionMode.home);

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Step 3: Activate Travel Concierge
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(tester, session, 'Plan a trip', ttsService);

    expect(
      session.messages.any(
        (m) => m.isSurface && m.surfaceId == 'travel-setup-001',
      ),
      isTrue,
      reason: 'Travel setup surface should appear after "Plan a trip"',
    );

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Step 4: Generate Itinerary
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(tester, session, 'Generate Itinerary', ttsService);

    expect(find.text('TOKYO'), findsWidgets);
    expect(find.text('FOODIE'), findsWidgets);
    expect(find.text('3 DAYS'), findsWidgets);

    final genBtn = find.text('GENERATE ITINERARY');
    expect(genBtn, findsOneWidget);
    await tester.ensureVisible(genBtn);
    await tester.tap(genBtn);
    await tester.pump(const Duration(milliseconds: 1000));
    
    await _pumpUntilSurface(tester, session, 'tokyo-itin-001');

    expect(
      session.messages.any(
        (m) => m.isSurface && m.surfaceId == 'tokyo-itin-001',
      ),
      isTrue,
      reason: 'Itinerary surface should appear after generate',
    );

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester, frames: 10);

    // -----------------------------------------------------------------------
    // Step 5: Smooth Slow Scroll through Itinerary
    // -----------------------------------------------------------------------
    // Wait for the surface to render its key.
    await _pumpUntilText(tester, 'DAY 1');

    debugPrint('[DemoDriver] Attempting to find scrollable for itinerary...');
    // The Scrollable is an ancestor of the ChatSurfaceView inside the panel.
    final itinView = find.byKey(const Key('surface-panel-tokyo-itin-001'));
    final scrollableFinder = find.ancestor(
      of: itinView,
      matching: find.byType(Scrollable),
    ).first;
    
    await _pumpUntilScrollable(tester, scrollableFinder);
    debugPrint('[DemoDriver] Found scrollable for itinerary.');

    // Slowly review the plan (Timeline -> Hotel -> Flights -> Booking)
    final scrollState = tester.state<ScrollableState>(scrollableFinder);
    final maxScroll = scrollState.position.maxScrollExtent;
    
    debugPrint('[DemoDriver] Calculated maxScrollExtent: $maxScroll');
    await _pumpSlowScroll(tester, scrollableFinder, offset: maxScroll);
    await _pumpBreathing(tester, frames: 20);

    // -----------------------------------------------------------------------
    // Step 6: Book Trip
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(tester, session, 'Book Trip', ttsService);

    await _pumpUntilText(tester, 'CONFIRM BOOKING');
    final bookBtn = find.text('CONFIRM BOOKING');
    await tester.ensureVisible(bookBtn);
    await _pumpBreathing(tester, frames: 20);

    await tester.tap(bookBtn);
    await tester.pump(const Duration(milliseconds: 1000));
    
    await _pumpUntilMode(tester, session, SessionMode.home);

    expect(session.sessionMode, SessionMode.home);
    expect(session.messages.last.text?.toLowerCase(), contains('booked'));

    await earcon.playBookingConfirm();
    await _pumpSettle(tester);

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // Cleanup.
    session.dispose();
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Simulates a human-like continuous smooth scroll using TestGesture.
Future<void> _pumpSlowScroll(
  WidgetTester tester,
  Finder scrollable, {
  double offset = 1000,
  int steps = 150,
}) async {
  final Offset start = tester.getCenter(scrollable);
  debugPrint('[DemoDriver] Starting slow scroll at $start, total offset: $offset');
  
  // Start the drag gesture.
  final TestGesture gesture = await tester.startGesture(start);
  final double stepOffset = offset / steps;
  
  for (int i = 0; i < steps; i++) {
    // Negative Y to scroll DOWN (pushing content UP).
    await gesture.moveBy(Offset(0, -stepOffset));
    // Pump a real frame duration for smooth visual motion.
    await tester.pump(const Duration(milliseconds: 16));
    
    if (i % 50 == 0) {
      debugPrint('[DemoDriver] Scroll progress: ${((i / steps) * 100).toStringAsFixed(0)}%');
    }
  }
  
  // Finish the gesture without lifting too fast (prevents "fling").
  await gesture.up();
  debugPrint('[DemoDriver] Scroll gesture complete');
  await tester.pump(const Duration(milliseconds: 100));
}

/// Voice profiles for differentiating the User and Agent.
Future<void> _setVoiceProfile(
  TtsService tts, {
  required bool isUser,
  required WidgetTester tester,
}) async {
  await tester.runAsync(() async {
    if (isUser) {
      final maleVoices = ['Daniel', 'Alex', 'Fred', 'Oliver'];
      for (final name in maleVoices) {
        if (await tts.setVoice(name)) break;
      }
      await tts.setPitch(0.9);
      await tts.setRate(0.45);
    } else {
      final femaleVoices = ['Karen', 'Samantha', 'Siri', 'Victoria', 'Moira'];
      for (final name in femaleVoices) {
        if (await tts.setVoice(name)) break;
      }
      await tts.setPitch(1.0);
      await tts.setRate(0.5);
    }
  });
  // Small pump to let platform state settle.
  await tester.pump();
}

const _frameDuration = Duration(milliseconds: 50);
const _maxPumps = 1200;

Future<void> _pumpSettle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var i = 0; i < _maxPumps; i++) {
    await tester.pump(_frameDuration);
    // Use textContaining for substring match — rendered labels often include
    // surrounding context (e.g. "THU MAR 20 • DAY 1 • TSUKIJI ...").
    if (find.textContaining(text).evaluate().isNotEmpty) return;
  }
  throw Exception('Timeout waiting for text containing "$text"');
}

Future<void> _pumpUntilSurface(
  WidgetTester tester,
  ChatSession session,
  String surfaceId,
) async {
  for (var i = 0; i < _maxPumps; i++) {
    await tester.pump(_frameDuration);
    if (session.messages.any((m) => m.surfaceId == surfaceId)) return;
  }
  throw Exception('Timeout waiting for surface $surfaceId');
}

Future<void> _pumpUntilMode(
  WidgetTester tester,
  ChatSession session,
  SessionMode mode,
) async {
  for (var i = 0; i < _maxPumps; i++) {
    await tester.pump(_frameDuration);
    if (session.sessionMode == mode) return;
  }
  throw Exception('Timeout waiting for mode $mode');
}

Future<void> _pumpUntilScrollable(
  WidgetTester tester,
  Finder scrollable,
) async {
  for (var i = 0; i < _maxPumps; i++) {
    await tester.pump(_frameDuration);
    if (scrollable.evaluate().isNotEmpty) return;
  }
  throw Exception('Timeout waiting for scrollable');
}

Future<void> _pumpVoiceCommand(
  WidgetTester tester,
  ChatSession session,
  String text,
  TtsService tts,
) async {
  // 1. User speaks command (Male voice)
  await _setVoiceProfile(tts, isUser: true, tester: tester);
  await tester.runAsync(() => tts.speak(text));

  // Wait for speech to actually start (asynchronous lag)
  for (int i = 0; i < 20 && !tts.isSpeaking; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }

  // Ensure User TTS finishes before we proceed to STT simulation/AI response
  await _pumpUntilTtsDone(tester, tts);

  // 2. Switch back to Agent profile BEFORE AI response starts
  await _setVoiceProfile(tts, isUser: false, tester: tester);

  // 3. Drive STT simulation (word-by-word visual)
  var done = false;
  unawaited(session.sendVoiceCommand(text).whenComplete(() => done = true));

  for (var i = 0; i < _maxPumps && !done; i++) {
    await tester.pump(_frameDuration);
  }
  
  expect(done, isTrue, reason: 'Voice command "$text" should complete');
  await _pumpSettle(tester);
}

Future<void> _pumpUntilTtsDone(
  WidgetTester tester,
  TtsService tts,
) async {
  for (var i = 0; i < 200 && tts.isSpeaking; i++) {
    await tester.pump(_frameDuration);
  }
}

Future<void> _pumpBreathing(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(_frameDuration);
  }
}
