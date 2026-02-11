import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/core/ai_client.dart';

import '../fixtures/mock_ai_client.dart';

void main() {
  group('MockAiClient', () {
    test('yields all response chunks', () async {
      final client = MockAiClient(responses: ['a', 'b', 'c']);
      final chunks = await client
          .sendStream('test', systemPrompt: '', history: [])
          .toList();
      expect(chunks, ['a', 'b', 'c']);
    });

    test('tracks send count', () async {
      final client = MockAiClient();
      await client.sendStream('q1', systemPrompt: '', history: []).drain<void>();
      await client.sendStream('q2', systemPrompt: '', history: []).drain<void>();
      expect(client.sendCount, 2);
    });

    test('dispose marks client as disposed', () {
      final client = MockAiClient();
      client.dispose();
      expect(client.disposed, isTrue);
    });
  });

  group('ErrorAiClient', () {
    test('throws on sendStream', () {
      final client = ErrorAiClient();
      expect(
        () => client.sendStream('test', systemPrompt: '', history: []).drain<void>(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AnthropicAiClient', () {
    test('constructor sets model and apiKey', () {
      final client = AnthropicAiClient(apiKey: 'test-key');
      expect(client.apiKey, 'test-key');
      expect(client.model, 'claude-opus-4-6');
      client.dispose();
    });

    test('custom model is respected', () {
      final client = AnthropicAiClient(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-5-20250929',
      );
      expect(client.model, 'claude-sonnet-4-5-20250929');
      client.dispose();
    });
  });
}
