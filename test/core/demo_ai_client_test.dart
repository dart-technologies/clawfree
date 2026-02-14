import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';

void main() {
  group('DemoCacheAiClient', () {
    test('returns create response for "create" prompt', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('Create an agent', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('agent'));
      expect(response, contains('```json'));
    });

    test('returns dashboard response for "show" prompt', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('Show my agents', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('dashboard'));
    });

    test('returns default response for unknown prompt', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('What is the weather?', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('help'));
    });

    test('matches case-insensitively', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('CREATE A BOT', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('```json'));
    });

    test('streams in chunks of specified size', () async {
      final client = DemoCacheAiClient(chunkSize: 5, chunkDelay: Duration.zero);
      final chunks = await client
          .sendStream('something unknown', systemPrompt: '', history: [])
          .toList();
      // Each chunk should be at most 5 characters (except possibly the last)
      for (var i = 0; i < chunks.length - 1; i++) {
        expect(chunks[i].length, 5);
      }
      expect(chunks.last.length, lessThanOrEqualTo(5));
    });

    test('custom cached responses work', () async {
      final client = DemoCacheAiClient(
        cachedResponses: {
          'foo': 'Bar response',
          '_default': 'Default response',
        },
      );
      final chunks = await client
          .sendStream('foo bar', systemPrompt: '', history: [])
          .toList();
      expect(chunks.join(), 'Bar response');
    });

    test('falls back to _default when no pattern matches', () async {
      final client = DemoCacheAiClient(
        cachedResponses: {
          'specific': 'Specific response',
          '_default': 'Fallback',
        },
      );
      final chunks = await client
          .sendStream('no match', systemPrompt: '', history: [])
          .toList();
      expect(chunks.join(), 'Fallback');
    });

    // Trip planning demo scenario tests
    test('returns trip planning response for "plan tokyo trip"', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('plan a 3 day trip to tokyo', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('```json'));
      expect(response.toLowerCase(), contains('tokyo'));
    });

    test('returns trip agent response for "create trip agent"', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('create trip agent', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('```json'));
    });

    test('returns sushi class response for "add sushi class"', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('add sushi class to the itinerary', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('```json'));
      expect(response.toLowerCase(), contains('sushi'));
    });

    test('self-correction prompts do not trigger cached surface responses', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('The createSurface could not be parsed. Please regenerate.', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, isNot(contains('```json')));
    });

    test('JSON block is yielded as single chunk', () async {
      final client = DemoCacheAiClient(chunkSize: 10, chunkDelay: Duration.zero);
      final chunks = await client
          .sendStream('show dashboard', systemPrompt: '', history: [])
          .toList();
      // The last chunk should contain the entire JSON block
      final jsonChunks = chunks.where((c) => c.contains('```json'));
      expect(jsonChunks.length, 1);
    });

    test('dispose completes without error', () {
      final client = DemoCacheAiClient();
      expect(() => client.dispose(), returnsNormally);
    });

    test('defaultResponses contains expected keys', () {
      expect(DemoCacheAiClient.defaultResponses, contains('create'));
      expect(DemoCacheAiClient.defaultResponses, contains('show'));
      expect(DemoCacheAiClient.defaultResponses, contains('_default'));
    });

    test('matches telegram keyword', () async {
      final client = DemoCacheAiClient();
      final chunks = await client
          .sendStream('Make a Telegram bot', systemPrompt: '', history: [])
          .toList();
      final response = chunks.join();
      expect(response, contains('```json'));
    });
  });
}
