import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/chat_session.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';
import 'package:clawfree/src/core/interaction_router.dart';
import 'package:clawfree/src/core/prompt_library.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/voice_controller.dart';

/// E2E integration tests simulating the full hackathon demo workflow with
/// mocked voice commands:
///
/// **Story 1 — Agent Creation**:
/// 1. Watch user says: "Plan a 3-day foodie trip to Tokyo"
/// 2. Clawfree creates "Travel Concierge" agent (name, model, tools, channels pre-filled)
/// 3. User says "Save Agent"
/// 4. Travel Concierge appears in agent store, session returns to home mode
///
/// **Story 2 — Plan Trip**:
/// 5. Travel Concierge narrates "Now planning trip" and shows travel setup genUI
/// 6. Travel setup shows 5 cities with Tokyo, 3-day, foodie pre-selected
/// 7. User says "Generate Itinerary"
/// 8. Itinerary shows with ANA flight pre-selected (above JAL)
/// 9. User says "Book Trip"
///
/// Voice commands are simulated via `ChatSession.sendVoiceCommand()` which
/// drives the full STT visual pipeline (VoiceOrb pulsing, interim transcript
/// building word-by-word). Surface interactions are simulated by constructing
/// `ChatMessage` JSON events.
void main() {
  group('E2E: Demo Workflow — Story 1: Agent Creation', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;
    late AgentStore agentStore;
    late VoiceController voiceController;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      agentStore = AgentStore();
      voiceController = VoiceController(
        stt: MockSttService(),
        tts: MockTtsService(),
      );
      session = ChatSession(
        aiClient: demoClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      // Start in agentBuilder mode (standard chat UI).
      session.setMode(SessionMode.agentBuilder);
    });

    tearDown(() => session.dispose());

    test(
      'Step 1: "Plan a 3-day foodie trip to Tokyo" triggers Travel Concierge agent form',
      () async {
        // Simulated Watch voice command — drives VoiceOrb + interim transcript.
        await session.sendVoiceCommand(
          'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
          pauseAfterStt: Duration.zero,
        );

        // Should produce text mentioning "Travel Concierge".
        final aiMessages = session.messages.where(
          (m) => !m.isUser && !m.isSurface,
        );
        expect(aiMessages, isNotEmpty);
        final aiText = aiMessages.first.text ?? '';
        expect(aiText.toLowerCase(), contains('travel concierge'));

        // Should produce an agent form surface.
        final surfaces = session.messages.where((m) => m.isSurface).toList();
        expect(
          surfaces,
          isNotEmpty,
          reason: 'Should create agent form surface',
        );
        expect(surfaces.first.surfaceId, 'agent-form-001');
      },
    );

    test('Step 2: Agent form response mentions pre-filled fields', () async {
      await session.sendVoiceCommand(
        'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
        pauseAfterStt: Duration.zero,
      );

      // Verify the AI response mentions pre-populated values.
      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText, contains('Travel Concierge'));
      expect(aiText, contains('pre-filled'));
    });

    test(
      'Step 3: "Save Agent" interaction stores agent and switches to home mode',
      () async {
        await session.sendVoiceCommand(
          'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
          pauseAfterStt: Duration.zero,
        );

        // Verify agent form surface exists.
        expect(
          session.messages.any(
            (m) => m.isSurface && m.surfaceId == 'agent-form-001',
          ),
          isTrue,
        );

        // Simulate the save_agent interaction event.
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
        final result = router.handle(saveEvent);

        // Should return ModeSwitchResult → home mode.
        expect(result, isA<ModeSwitchResult>());
        final modeSwitch = result as ModeSwitchResult;
        expect(modeSwitch.targetMode, SessionMode.home);

        // Agent should be saved in the store.
        expect(agentStore.agents.length, 1);
        expect(agentStore.agents.first['name'], 'Travel Concierge');
        expect(agentStore.agents.first['model'], 'claude-opus-4-6');
      },
    );

    test('Step 4: Saved agent has all tools and channels checked', () async {
      // Trigger save directly via router.
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
      router.handle(saveEvent);

      final agent = agentStore.agents.first;
      expect(agent['tools'], ['browser', 'code', 'search', 'api']);
      expect(agent['channels'], ['telegram', 'slack', 'discord']);
      expect(agent['model'], 'claude-opus-4-6');
    });
  });

  group('E2E: Demo Workflow — Story 2: Plan Trip', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;
    late AgentStore agentStore;
    late VoiceController voiceController;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      agentStore = AgentStore();
      voiceController = VoiceController(
        stt: MockSttService(),
        tts: MockTtsService(),
      );
      session = ChatSession(
        aiClient: demoClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      // Start from home mode (as if agent was just saved).
      session.setMode(SessionMode.home);
    });

    tearDown(() => session.dispose());

    test('Step 5: "Plan a trip" shows travel setup with narration', () async {
      await session.sendVoiceCommand(
        'Plan a trip',
        pauseAfterStt: Duration.zero,
      );

      // AI narrates concierge activation.
      final aiMessages = session.messages.where(
        (m) => !m.isUser && !m.isSurface,
      );
      expect(aiMessages, isNotEmpty);
      final aiText = aiMessages.first.text ?? '';
      expect(aiText.toLowerCase(), contains('concierge'));
    });

    test(
      'Step 6: Travel setup surface has 5 cities with Tokyo pre-selected',
      () async {
        await session.sendVoiceCommand(
          'Plan a trip',
          pauseAfterStt: Duration.zero,
        );

        // Surface created: travel-setup-001.
        final surfaces = session.messages.where((m) => m.isSurface).toList();
        expect(surfaces, isNotEmpty);
        expect(surfaces.first.surfaceId, 'travel-setup-001');

        // Verify the raw response structure has all 5 cities via the static map.
        final responses = DemoCacheAiClient.defaultResponses;
        final response = responses['trip']!;
        expect(response, contains('Tokyo'));
        expect(response, contains('London'));
        expect(response, contains('Paris'));
        expect(response, contains('New York'));
        expect(response, contains('San Francisco'));

        // Verify Tokyo is pre-selected.
        expect(response, contains('"value": ["tokyo"]'));

        // Verify foodie is pre-selected.
        expect(response, contains('"value": ["foodie"]'));

        // Verify 3-day is pre-selected.
        expect(response, contains('"value": ["3"]'));
      },
    );

    test(
      'Step 7: "Generate Itinerary" produces itinerary user input',
      () async {
        // Simulate generate_itinerary interaction.
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

        final router = session.interactionRouterForTest;
        final result = router.handle(genEvent);

        // Should produce a UserInputResult that feeds back into the AI.
        expect(result, isA<UserInputResult>());
        final input = result as UserInputResult;
        expect(input.text.toLowerCase(), contains('foodie'));
        expect(input.text.toLowerCase(), contains('tokyo'));
      },
    );

    test('Step 8: Itinerary response has ANA flight above JAL', () async {
      // Send the compound keyword that generate_itinerary would produce.
      await session.sendVoiceCommand(
        'Show me the foodie plan for tokyo',
        pauseAfterStt: Duration.zero,
      );

      // Should produce tokyo-itin-001 surface.
      final surfaces = session.messages.where((m) => m.isSurface).toList();
      expect(surfaces, isNotEmpty);
      expect(surfaces.first.surfaceId, 'tokyo-itin-001');

      // Verify ANA (ticket1) appears before JAL (ticket2) in the response.
      final responses = DemoCacheAiClient.defaultResponses;
      final response = responses['foodie plan']!;
      final anaIndex = response.indexOf('Selected ANA');
      final jalIndex = response.indexOf('Select JAL');
      expect(
        anaIndex,
        lessThan(jalIndex),
        reason: 'ANA option should appear above JAL in the itinerary',
      );
    });

    test('Step 9: "Book Trip" interaction completes workflow', () async {
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

      final router = session.interactionRouterForTest;
      final result = router.handle(bookEvent);

      // Should return ModeSwitchResult → home mode with booking confirmation.
      expect(result, isA<ModeSwitchResult>());
      final modeSwitch = result as ModeSwitchResult;
      expect(modeSwitch.targetMode, SessionMode.home);
      expect(modeSwitch.message.text?.toLowerCase(), contains('booked'));
    });
  });

  group('E2E: Demo Workflow — Full End-to-End', () {
    late DemoCacheAiClient demoClient;
    late ChatSession session;
    late AgentStore agentStore;
    late VoiceController voiceController;

    setUp(() {
      demoClient = DemoCacheAiClient(chunkDelay: Duration.zero);
      agentStore = AgentStore();
      voiceController = VoiceController(
        stt: MockSttService(),
        tts: MockTtsService(),
      );
      session = ChatSession(
        aiClient: demoClient,
        voiceController: voiceController,
        agentStore: agentStore,
      );
      session.setMode(SessionMode.agentBuilder);
    });

    tearDown(() => session.dispose());

    test(
      'complete demo: create agent → save → plan trip → generate → book',
      () async {
        // === STORY 1: Agent Creation ===

        // Step 1: Voice command from Watch — VoiceOrb pulses, interim builds.
        await session.sendVoiceCommand(
          'Create a travel concierge to plan a 3-day foodie trip to Tokyo',
          pauseAfterStt: Duration.zero,
        );

        // Verify agent form surface appeared.
        expect(
          session.messages.any(
            (m) => m.isSurface && m.surfaceId == 'agent-form-001',
          ),
          isTrue,
          reason: 'Agent form should appear after create command',
        );

        // Step 3: Simulate "Save Agent" via router.
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
        final saveResult = session.interactionRouterForTest.handle(saveEvent);
        expect(saveResult, isA<ModeSwitchResult>());

        // Step 4: Verify agent is saved.
        expect(agentStore.agents.length, 1);
        expect(agentStore.agents.first['name'], 'Travel Concierge');

        // === STORY 2: Plan Trip ===

        // Step 5: "Plan a trip" — now as saved agent's suggested command.
        await session.sendVoiceCommand(
          'Plan a trip',
          pauseAfterStt: Duration.zero,
        );

        // Verify travel setup surface.
        expect(
          session.messages.any(
            (m) => m.isSurface && m.surfaceId == 'travel-setup-001',
          ),
          isTrue,
          reason: 'Travel setup should appear after "Plan a trip"',
        );

        // Step 7: Simulate "Generate Itinerary".
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
        final genResult = session.interactionRouterForTest.handle(genEvent);
        expect(genResult, isA<UserInputResult>());
        final genInput = genResult as UserInputResult;

        // Feed the generated prompt back to get the itinerary.
        await session.sendMessage(genInput.text);
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Step 8: Verify itinerary surface.
        expect(
          session.messages.any(
            (m) => m.isSurface && m.surfaceId == 'tokyo-itin-001',
          ),
          isTrue,
          reason: 'Itinerary should appear after generate',
        );

        // Step 9: Simulate "Book Trip".
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
        final bookResult = session.interactionRouterForTest.handle(bookEvent);
        expect(bookResult, isA<ModeSwitchResult>());
        final bookSwitch = bookResult as ModeSwitchResult;
        expect(bookSwitch.targetMode, SessionMode.home);
        expect(bookSwitch.message.text?.toLowerCase(), contains('booked'));

        // === Verify final state ===
        // 1 agent in store.
        expect(agentStore.agents.length, 1);

        // Multiple surfaces created during the workflow.
        final allSurfaces = session.messages.where((m) => m.isSurface).toList();
        expect(allSurfaces.length, greaterThanOrEqualTo(2));

        // Surface IDs include both steps.
        final surfaceIds = allSurfaces.map((s) => s.surfaceId).toSet();
        expect(surfaceIds, contains('agent-form-001'));
        expect(surfaceIds, contains('travel-setup-001'));
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [ChatMessage] simulating a surface interaction event with JSON.
ChatMessage _buildInteractionEvent(Map<String, dynamic> payload) {
  return ChatMessage(
    role: ChatMessageRole.user,
    parts: [TextPart(jsonEncode(payload))],
  );
}
