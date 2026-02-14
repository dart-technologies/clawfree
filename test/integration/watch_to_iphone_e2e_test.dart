// Watch → iPhone voice command E2E tests.
//
// Verifies that voice commands processed by DemoCacheAiClient produce the
// correct responses (text + A2UI surfaces) for the Watch → iPhone pipeline.
//
// Tests DemoCacheAiClient keyword matching directly. The keyword matching
// order in defaultResponses means some compound keywords are shadowed by
// earlier broad keys (e.g. 'trip' matches before 'create trip').

import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';

Future<String> getResponse(DemoCacheAiClient client, String prompt) async {
  final buf = StringBuffer();
  await for (final chunk in client.sendStream(prompt, systemPrompt: '', history: [])) {
    buf.write(chunk);
  }
  return buf.toString();
}

String? extractSurfaceId(String response) {
  final m = RegExp(r'"surfaceId"\s*:\s*"([^"]+)"').firstMatch(response);
  return m?.group(1);
}

void main() {
  late DemoCacheAiClient aiClient;

  setUp(() => aiClient = DemoCacheAiClient(chunkDelay: Duration.zero));
  tearDown(() => aiClient.dispose());

  group('Watch voice command → DemoCacheAiClient routing', () {
    test('"rename" triggers rename response', () async {
      final r = await getResponse(aiClient, 'rename my agent');
      expect(r, contains('agent-form-001'));
      expect(r, contains('GitHub Digest Bot'));
    });

    test('"plan a trip" triggers travel setup', () async {
      final r = await getResponse(aiClient, 'plan a trip to somewhere');
      expect(extractSurfaceId(r), 'travel-setup-001');
      expect(r, contains('city-picker'));
      expect(r, contains('persona-picker'));
      expect(r, contains('days-picker'));
    });

    test('"plan a 3 day visit" triggers Tokyo itinerary', () async {
      final r = await getResponse(aiClient, 'plan a 3 day visit');
      expect(extractSurfaceId(r), 'trip-itin-001');
      expect(r, contains('day1-card'));
      expect(r, contains('day2-card'));
      expect(r, contains('day3-card'));
    });

    test('"sushi class" triggers sushi class update', () async {
      final r = await getResponse(aiClient, 'I want a sushi class on day 2');
      expect(extractSurfaceId(r), 'trip-itin-001');
      expect(r, contains('day2-sushi'));
      expect(r, contains('Sushi Making Class'));
      expect(r, contains('"updateComponents"'));
    });

    test('"create a travel concierge" triggers travel agent creation', () async {
      // Special-cased: contains both "create" and "travel"
      final r = await getResponse(aiClient, 'create a travel concierge');
      expect(extractSurfaceId(r), 'agent-form-001');
      expect(r, contains('Travel Concierge'));
    });

    test('"create agent" triggers generic agent creation', () async {
      final r = await getResponse(aiClient, 'create agent');
      expect(extractSurfaceId(r), 'agent-form-001');
      expect(r, contains('CREATE AGENT'));
    });
  });

  group('Watch voice: multi-command ordering', () {
    test('sequential commands produce distinct responses', () async {
      final r1 = await getResponse(aiClient, 'create agent');
      final r2 = await getResponse(aiClient, 'plan a 3 day visit');
      final r3 = await getResponse(aiClient, 'I want a sushi class');

      expect(extractSurfaceId(r1), 'agent-form-001');
      expect(extractSurfaceId(r2), 'trip-itin-001');
      expect(extractSurfaceId(r3), 'trip-itin-001');

      expect(r1, isNot(equals(r2)));
      expect(r2, isNot(equals(r3)));
    });

    test('commands process without interference', () async {
      final responses = <String>[];
      for (final p in ['create agent', 'plan a 3 day visit', 'I want a sushi class']) {
        responses.add(await getResponse(aiClient, p));
      }
      expect(responses[0], contains('CREATE AGENT'));
      expect(responses[1], contains('Day 1'));
      expect(responses[2], contains('Sushi Making Class'));
    });
  });

  group('Watch voice: response content', () {
    test('agent creation form has model and tool pickers', () async {
      final r = await getResponse(aiClient, 'create agent');
      expect(r, contains('model-picker'));
      expect(r, contains('tools-picker'));
      expect(r, contains('channels-picker'));
    });

    test('itinerary has budget and 3 day cards', () async {
      final r = await getResponse(aiClient, 'plan a 3 day visit');
      expect(r, contains('budget'));
      expect(r, contains('Day 1'));
      expect(r, contains('Day 2'));
      expect(r, contains('Day 3'));
    });

    test('sushi class update modifies Day 2', () async {
      final r = await getResponse(aiClient, 'I want a sushi class');
      expect(r, contains('Day 2'));
      expect(r, contains('Updated'));
      expect(r, contains('day2-sushi'));
    });

    test('self-correction triggers fallback', () async {
      final r = await getResponse(aiClient, 'could not be parsed');
      expect(r.toLowerCase(), contains('different approach'));
      expect(r.contains('```json'), isFalse);
    });

    test('help command returns capabilities', () async {
      final r = await getResponse(aiClient, 'help');
      expect(r.toLowerCase(), contains('create'));
      expect(r.toLowerCase(), contains('plan a trip'));
      expect(r.toLowerCase(), contains('skill'));
    });
  });
}
