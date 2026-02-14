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
      expect(response, contains('agents'));
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
