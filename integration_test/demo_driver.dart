import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:integration_test/integration_test.dart';

import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/core/interaction_router.dart';
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

    // Let TTS finish reading + breathing room.
    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Step 2: Save Agent (button click simulation via router)
    //   → Success chime, TTS confirms save, mode → home.
    // -----------------------------------------------------------------------
    final saveEvent = _buildInteractionEvent({
      'action': {
        'name': 'save_agent',
        'context': {
          'name': 'Travel Concierge',
          'model': ['claude-opus-4-6'],
          'tools': ['browser', 'code', 'search', 'api'],
          'channels': ['telegram', 'slack', 'discord'],
        },
      },
    });

    final router = session.interactionRouterForTest;
    final saveResult = router.handle(saveEvent);
    expect(saveResult, isA<ModeSwitchResult>());

    final modeSwitchResult = saveResult as ModeSwitchResult;
    session.setMode(modeSwitchResult.targetMode);

    // Speak the feedback and play success chime (as _handleSurfaceInteraction would).
    earcon.playBookingConfirm();
    voiceController.speak(modeSwitchResult.message.text ?? '');
    await _pumpSettle(tester);

    expect(agentStore.agents.length, 1);
    expect(agentStore.agents.first['name'], 'Travel Concierge');
    expect(session.sessionMode, SessionMode.home);

    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Step 3: "Plan a trip"
    //   → Travel setup surface renders with persona/city/duration pickers.
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
    // Step 4: Generate Itinerary (button click → sendMessage)
    //   → Full itinerary with map, flights, hotels renders.
    // -----------------------------------------------------------------------
    final genEvent = _buildInteractionEvent({
      'action': {
        'name': 'generate_itinerary',
        'context': {
          'city': ['tokyo'],
          'persona': ['foodie'],
          'days': ['3'],
        },
      },
    });

    final genResult = router.handle(genEvent);
    expect(genResult, isA<UserInputResult>());
    final genInput = genResult as UserInputResult;

    await _pumpSendMessage(tester, session, genInput.text);

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
    // Step 5: Book Trip (button click)
    //   → Booking confirmation, success chime, mode → home.
    // -----------------------------------------------------------------------
    final bookEvent = _buildInteractionEvent({
      'action': {
        'name': 'book_trip',
        'context': {
          'city': 'tokyo',
          'days': 3,
          'persona': 'foodie',
          'flight': 'ANA',
        },
      },
    });

    final bookResult = router.handle(bookEvent);
    expect(bookResult, isA<ModeSwitchResult>());
    final bookSwitch = bookResult as ModeSwitchResult;
    expect(bookSwitch.targetMode, SessionMode.home);
    expect(bookSwitch.message.text?.toLowerCase(), contains('booked'));

    session.setMode(bookSwitch.targetMode);

    // Speak booking confirmation and play success chime.
    earcon.playBookingConfirm();
    voiceController.speak(bookSwitch.message.text ?? '');
    await _pumpSettle(tester);

    // Let final TTS play out before cleanup.
    await _pumpUntilTtsDone(tester, ttsService);
    await _pumpBreathing(tester);

    // -----------------------------------------------------------------------
    // Final assertions
    // -----------------------------------------------------------------------
    expect(agentStore.agents.length, 1);
    expect(session.sessionMode, SessionMode.home);

    final allSurfaces = session.messages.where((m) => m.isSurface).toList();
    expect(allSurfaces.length, greaterThanOrEqualTo(2));

    final surfaceIds = allSurfaces.map((s) => s.surfaceId).toSet();
    expect(surfaceIds, contains('agent-form-001'));
    expect(surfaceIds, contains('travel-setup-001'));
    expect(surfaceIds, contains('tokyo-itin-001'));

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

/// Drives a sendMessage while pumping frames so AI streaming text and
/// surface creation are visible.
Future<void> _pumpSendMessage(
  WidgetTester tester,
  ChatSession session,
  String text,
) async {
  var done = false;
  session.sendMessage(text).whenComplete(() => done = true);

  for (var i = 0; i < _maxPumps && !done; i++) {
    await tester.pump(_frameDuration);
  }
  expect(done, isTrue, reason: 'sendMessage should complete');
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

/// Builds a [ChatMessage] simulating a surface interaction event with JSON.
ChatMessage _buildInteractionEvent(Map<String, dynamic> payload) {
  return ChatMessage(
    role: ChatMessageRole.user,
    parts: [TextPart(jsonEncode(payload))],
  );
}
