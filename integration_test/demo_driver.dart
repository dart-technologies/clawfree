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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Demo workflow: create agent → save → plan trip → generate → book', (
    WidgetTester tester,
  ) async {
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
        home: ChatScreen(chatSession: session),
      ),
    );
    await _pumpSettle(tester);

    // -----------------------------------------------------------------------
    // Step 1: "Create a travel concierge…"
    //   → Orb pulses, transcript builds word-by-word, AI text streams in,
    //     surface renders, TTS reads response aloud.
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(
      tester,
      session,
      'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
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
    // Step 2: Save Agent (True UI Interaction)
    //   → Verify pre-populated fields, then tap "Save Agent".
    // -----------------------------------------------------------------------
    
    // Verify "Travel Concierge" is in the name field and ensure it's synced.
    // Use a specific finder to avoid the bottom ChatInputBar's TextField.
    final nameFieldFinder = find.descendant(
      of: find.byKey(const Key('agent-form-001')),
      matching: find.byType(TextField),
    );
    expect(find.text('Travel Concierge'), findsOneWidget);
    await tester.enterText(nameFieldFinder, 'Travel Concierge');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpSettle(tester);
    
    // Find and tap the "SAVE AGENT" button.
    final saveBtn = find.text('SAVE AGENT');
    expect(saveBtn, findsOneWidget);
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    // Wait for the 500ms interaction debounce in ChatSession to fire.
    await tester.pump(const Duration(milliseconds: 1000));
    await _pumpSettle(tester);

    // ChatSession._handleSurfaceInteraction handles mode switching.
    
    expect(agentStore.agents.length, 1);
    expect(agentStore.agents.first['name'], 'Travel Concierge');
    expect(session.sessionMode, SessionMode.home);

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // Step 3: "Plan a trip"
    //   → Travel setup surface renders with vibe/city/duration pickers.
    // -----------------------------------------------------------------------
    await _pumpVoiceCommand(tester, session, 'Plan a trip');

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
    // Step 4: Generate Itinerary (True UI Interaction)
    //   → Verify "Tokyo", "Foodie", "3 Days" are pre-selected, then tap.
    // -----------------------------------------------------------------------
    
    // Verify pre-selected values are visible.
    expect(find.text('TOKYO'), findsWidgets);
    expect(find.text('FOODIE'), findsWidgets);
    expect(find.text('3 DAYS'), findsWidgets);

    final genBtn = find.text('GENERATE ITINERARY');
    expect(genBtn, findsOneWidget);
    await tester.ensureVisible(genBtn);
    await tester.tap(genBtn);
    // Wait for the 500ms interaction debounce in ChatSession to fire.
    await tester.pump(const Duration(milliseconds: 1000));
    
    // Wait for the itinerary surface to appear (AI generation takes time).
    await _pumpUntilSurface(tester, session, 'tokyo-itin-001');

    expect(
      session.messages.any(
        (m) => m.isSurface && m.surfaceId == 'tokyo-itin-001',
      ),
      isTrue,
      reason: 'Itinerary surface should appear after generate',
    );

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Step 5: Book Trip (True UI Interaction)
    //   → Scroll to and tap "Confirm Booking".
    // -----------------------------------------------------------------------
    
    // Poll until "Confirm Booking" button renders (surface components load async).
    await _pumpUntilText(tester, 'CONFIRM BOOKING');

    final bookBtn = find.text('CONFIRM BOOKING');
    expect(bookBtn, findsOneWidget);

    // Ensure button is visible before tapping (it's at the bottom of a scrollable list).
    await tester.ensureVisible(bookBtn);
    await tester.tap(bookBtn);
    // Wait for the 500ms interaction debounce in ChatSession to fire.
    await tester.pump(const Duration(milliseconds: 1000));
    
    // Wait for mode switch back to home.
    await _pumpUntilMode(tester, session, SessionMode.home);

    expect(session.sessionMode, SessionMode.home);
    expect(session.messages.last.text?.toLowerCase(), contains('booked'));

    // Play booking confirm earcon.
    earcon.playBookingConfirm();
    await _pumpSettle(tester);

    // Let final TTS play out before cleanup.
    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Final assertions
    // -----------------------------------------------------------------------
    expect(agentStore.agents.length, 1);
    expect(agentStore.agents.first['name'], 'Travel Concierge');
    expect(session.sessionMode, SessionMode.home);

    // Note: ChatSession clears messages/surfaces when switching to home mode
    // to provide a clean state for the user. So we don't assert on message count here.

    // Cleanup.
    session.dispose();
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Frame pump interval — fast enough for smooth animation, slow enough to
/// let real timers (MockSttService word-by-word, DemoCacheAiClient chunks)
/// fire between frames.
const _frameDuration = Duration(milliseconds: 50);

/// Max pump iterations to prevent infinite hangs (60 seconds at 50ms/frame).
const _maxPumps = 1200;

/// Bounded settle: pumps a fixed number of frames to let layout and
/// animations render, without hanging on the VoiceOrb's continuous shader
/// animation (which would cause pumpAndSettle() to loop forever).
Future<void> _pumpSettle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Pumps frames until a widget with the given text appears in the tree.
Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var i = 0; i < _maxPumps; i++) {
    await tester.pump(_frameDuration);
    if (find.text(text).evaluate().isNotEmpty) return;
  }
  throw Exception('Timeout waiting for text "$text"');
}

/// Pumps frames until a specific surface ID appears in the session.
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

/// Pumps frames until the session enters a specific mode.
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

/// Drives a voice command while pumping frames so the VoiceOrb animation
/// and word-by-word transcript are visible during screen recording.
///
/// IntegrationTestWidgetsFlutterBinding uses real async (not fake), so
/// Timer.periodic inside MockSttService fires at real intervals. Each
/// [tester.pump] renders a frame showing the latest state.
Future<void> _pumpVoiceCommand(
  WidgetTester tester,
  ChatSession session,
  String text,
) async {
  var done = false;
  session.sendVoiceCommand(text).whenComplete(() => done = true);

  for (var i = 0; i < _maxPumps && !done; i++) {
    await tester.pump(_frameDuration);
  }
  expect(done, isTrue, reason: 'Voice command "$text" should complete');
  await _pumpSettle(tester);
}

/// Pump frames until TTS finishes speaking (bounded to 10 seconds).
/// Prevents the next step from cutting off the current utterance.
Future<void> _pumpUntilTtsDone(
  WidgetTester tester,
  PlatformTtsService tts,
) async {
  for (var i = 0; i < 200 && tts.isSpeaking; i++) {
    await tester.pump(_frameDuration);
  }
}

/// 2-second breathing room with frame pumping (keeps animations alive
/// during screen recording pauses between steps).
Future<void> _pumpBreathing(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(_frameDuration);
  }
}
