// genUI demo flow E2E tests.
//
// Verifies the full genUI demo interaction with DemoCacheAiClient,
// testing A2UI surface creation, multi-turn flows, fallback, and
// streaming behavior.

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

  group('genUI: agent creation flow', () {
    test('"create agent" → A2UI with createSurface + updateComponents', () async {
      final r = await getResponse(aiClient, 'create agent');
      expect(r, contains('"createSurface"'));
      expect(r, contains('"updateComponents"'));
      expect(extractSurfaceId(r), 'agent-form-001');
    });

    test('agent form contains all required fields', () async {
      final r = await getResponse(aiClient, 'create agent');
      expect(r, contains('name-field'));
      expect(r, contains('model-picker'));
      expect(r, contains('tools-picker'));
      expect(r, contains('channels-picker'));
      expect(r, contains('save-btn'));
    });

    test('"create a travel agent" returns Travel Concierge form', () async {
      final r = await getResponse(aiClient, 'create a travel agent');
      expect(extractSurfaceId(r), 'agent-form-001');
      expect(r, contains('Travel Concierge'));
    });
  });

  group('genUI: travel planning flow', () {
    test('"plan a trip" → travel setup with pickers', () async {
      final r = await getResponse(aiClient, 'plan a trip');
      expect(extractSurfaceId(r), 'travel-setup-001');
      expect(r, contains('city-picker'));
      expect(r, contains('persona-picker'));
      expect(r, contains('days-picker'));
    });

    test('"plan a 3 day visit" → itinerary with Day 1/2/3', () async {
      final r = await getResponse(aiClient, 'plan a 3 day visit');
      expect(extractSurfaceId(r), 'trip-itin-001');
      expect(r, contains('day1-card'));
      expect(r, contains('day2-card'));
      expect(r, contains('day3-card'));
    });
  });

  group('genUI: multi-turn conversation', () {
    test('create agent → plan itinerary → add sushi class', () async {
      final r1 = await getResponse(aiClient, 'create agent');
      expect(extractSurfaceId(r1), 'agent-form-001');

      final r2 = await getResponse(aiClient, 'plan a 3 day visit');
      expect(extractSurfaceId(r2), 'trip-itin-001');
      expect(r2, contains('Day 1'));

      final r3 = await getResponse(aiClient, 'I want a sushi class on day 2');
      expect(extractSurfaceId(r3), 'trip-itin-001');
      expect(r3, contains('Sushi Making Class'));
      expect(r3, contains('"updateComponents"'));
      // updateComponents only, no createSurface
      expect(r3.indexOf('"createSurface"'), -1);
    });

    test('each response is distinct and contextually correct', () async {
      final r1 = await getResponse(aiClient, 'create agent');
      final r2 = await getResponse(aiClient, 'plan a 3 day visit');
      final r3 = await getResponse(aiClient, 'I want a sushi class');

      expect(r1, isNot(equals(r2)));
      expect(r2, isNot(equals(r3)));

      expect(r1, contains('CREATE AGENT'));
      expect(r2.toLowerCase(), contains('tokyo'));
      expect(r3.toLowerCase(), contains('sushi'));
    });
  });

  group('genUI: fallback and error handling', () {
    test('parse error → "different approach" response', () async {
      final r = await getResponse(aiClient, 'could not be parsed');
      expect(r.toLowerCase(), contains('different approach'));
      expect(r.contains('```json'), isFalse);
    });

    test('unknown command → default response', () async {
      final r = await getResponse(aiClient, 'xyzzy foobar nonsense');
      expect(r, isNotEmpty);
      expect(r.toLowerCase(), contains('help'));
    });
  });

  group('genUI: help and skill library', () {
    test('help → capabilities list with skill mention', () async {
      final r = await getResponse(aiClient, 'help');
      expect(r.toLowerCase(), contains('skill'));
      expect(r.toLowerCase(), contains('create'));
    });

    test('skill library → surface with 53 skills across 9 categories', () async {
      final r = await getResponse(aiClient, 'Show skill library');
      expect(extractSurfaceId(r), 'skill-library-001');
      expect(r, contains('SKILL LIBRARY'));
      expect(r, contains('53 SKILLS'));
      expect(r, contains('9 CATEGORIES'));
    });
  });

  group('genUI: other demo surfaces', () {
    test('audit → audit log surface', () async {
      final r = await getResponse(aiClient, 'Show audit log');
      expect(extractSurfaceId(r), 'audit-log-001');
    });

    test('analytics → telemetry surface', () async {
      final r = await getResponse(aiClient, 'Show analytics');
      expect(extractSurfaceId(r), 'analytics-001');
    });

    test('security → security scan surface', () async {
      final r = await getResponse(aiClient, 'security overview');
      expect(extractSurfaceId(r), 'security-001');
    });

    test('dashboard → agent list surface', () async {
      final r = await getResponse(aiClient, 'show my agents');
      expect(extractSurfaceId(r), 'dashboard-001');
    });
  });

  group('genUI: streaming behavior', () {
    test('response is delivered in multiple chunks', () async {
      final slow = DemoCacheAiClient(chunkSize: 20, chunkDelay: const Duration(milliseconds: 1));
      final chunks = <String>[];
      await for (final c in slow.sendStream('help', systemPrompt: '', history: [])) {
        chunks.add(c);
      }
      expect(chunks.length, greaterThan(1));
      expect(chunks.join().toLowerCase(), contains('create'));
      slow.dispose();
    });

    test('JSON block is delivered in one shot', () async {
      final slow = DemoCacheAiClient(chunkSize: 20, chunkDelay: const Duration(milliseconds: 1));
      final chunks = <String>[];
      await for (final c in slow.sendStream('create agent', systemPrompt: '', history: [])) {
        chunks.add(c);
      }
      final last = chunks.last;
      expect(last, contains('```json'));
      expect(last, contains('createSurface'));
      slow.dispose();
    });
  });
}
