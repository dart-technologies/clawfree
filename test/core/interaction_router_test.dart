import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/core/agent_store.dart';
import 'package:clawfree/src/core/interaction_router.dart';
import 'package:clawfree/src/core/prompt_library.dart';

ChatMessage _actionMessage(String actionName, Map<String, dynamic> context) {
  final json = jsonEncode({
    'action': {'name': actionName, 'context': context},
  });
  return ChatMessage(role: ChatMessageRole.user, parts: [TextPart(json)]);
}

void main() {
  late AgentStore agentStore;
  late A2uiInteractionRouter router;

  setUp(() {
    agentStore = AgentStore();
    router = A2uiInteractionRouter(agentStore: agentStore);
  });

  group('A2uiInteractionRouter Actions', () {
    test('save_agent adds agent to store and switches mode', () {
      final result = router.handle(_actionMessage('save_agent', {
        'name': 'Test Agent',
        'model': ['claude-opus-4-6'],
        'tools': ['browser', 'search'],
        'channels': ['slack'],
      }));

      expect(result, isA<ModeSwitchResult>());
      final msr = result as ModeSwitchResult;
      expect(msr.targetMode, SessionMode.home);
      expect(agentStore.agents.length, 1);
      expect(agentStore.agents.first['name'], 'Test Agent');
      expect(agentStore.agents.first['tools'], contains('browser'));
    });

    test('save_config returns userInput for next onboarding stage', () {
      final result = router.handle(_actionMessage('save_config', {}));
      expect(result, isA<UserInputResult>());
      expect((result as UserInputResult).text, contains('Configuration saved'));
    });

    test('confirm_setup returns userInput for next onboarding stage', () {
      final result = router.handle(_actionMessage('confirm_setup', {
        'api_key': 'test-key',
      }));
      expect(result, isA<UserInputResult>());
      expect((result as UserInputResult).text, contains('Setup confirmed'));
    });

    test('generate_itinerary returns vibe-specific plan query', () {
      final result = router.handle(_actionMessage('generate_itinerary', {
        'vibe': ['foodie'],
        'city': ['Tokyo'],
        'days': ['3'],
      }));
      expect(result, isA<UserInputResult>());
      expect((result as UserInputResult).text, 'Show me the foodie plan for 3 days in Tokyo');
    });

    test('save_itin returns success message and switches mode', () {
      final result = router.handle(_actionMessage('save_itin', {
        'vibe': ['foodie'],
        'city': ['Tokyo'],
      }));
      expect(result, isA<ModeSwitchResult>());
      final modeSwitchResult = result as ModeSwitchResult;
      expect(modeSwitchResult.targetMode, SessionMode.home);
      expect(modeSwitchResult.message.text, contains('booked'));
    });

    test('navigate returns userInput if text is provided', () {
      final result = router.handle(_actionMessage('navigate', {'text': 'go home'}));
      expect(result, isA<UserInputResult>());
      expect((result as UserInputResult).text, 'go home');
    });

    test('navigate returns ignored if no text provided', () {
      final result = router.handle(_actionMessage('navigate', {}));
      expect(result, isA<IgnoredResult>());
    });
  });

  group('A2uiInteractionRouter Manage Actions', () {
    test('check_health returns SystemActionResult', () {
      final result = router.handle(_actionMessage('check_health', {}));
      expect(result, isA<SystemActionResult>());
      expect((result as SystemActionResult).action, 'check_health');
    });

    test('system_notify returns SystemActionResult', () {
      final result = router.handle(_actionMessage('system_notify', {
        'title': 'Test',
        'body': 'Message',
      }));
      expect(result, isA<SystemActionResult>());
      expect((result as SystemActionResult).action, 'system_notify');
    });

    test('location_request returns SystemActionResult', () {
      final result = router.handle(_actionMessage('location_request', {}));
      expect(result, isA<SystemActionResult>());
      expect((result as SystemActionResult).action, 'location_request');
    });
  });

  group('A2uiInteractionRouter Validation Errors', () {
    test('returns CorrectionResult on validation error', () {
      final msg = ChatMessage(role: ChatMessageRole.user, parts: [
        TextPart(jsonEncode({
          'error': {'code': 'MISSING_ID', 'message': 'Root id missing'}
        }))
      ]);
      
      final result = router.handle(msg);
      expect(result, isA<CorrectionResult>());
      expect((result as CorrectionResult).prompt, contains('MISSING_ID'));
    });

    test('switches to maxCorrectionsReached after limit', () {
      final msg = ChatMessage(role: ChatMessageRole.user, parts: [
        TextPart(jsonEncode({
          'error': {'code': 'ERROR', 'message': 'Again'}
        }))
      ]);
      
      // Attempt 1
      router.handle(msg);
      // Attempt 2
      router.handle(msg);
      // Attempt 3 -> Max reached
      final result = router.handle(msg);
      
      expect(result, isA<MaxCorrectionsResult>());
    });
  });
}
