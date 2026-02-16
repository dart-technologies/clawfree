import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Abstract interface for AI clients compatible with genUI v0.9.
abstract interface class AiClient {
  /// Sends a streaming request and yields text chunks.
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  });

  /// Releases resources used by the AI client.
  void dispose();
}

/// Anthropic Claude Opus 4.6 client using HTTP SSE streaming.
///
/// Set [baseUrl] to a CORS gateway (e.g. `http://localhost:18789`) for web,
/// or leave as default for native platforms (direct API).
class AnthropicAiClient implements AiClient {
  AnthropicAiClient({
    required this.apiKey,
    this.model = 'claude-opus-4-6',
    this.baseUrl = 'https://api.anthropic.com',
  });

  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _httpClient = http.Client();

  static const _apiVersion = '2023-06-01';
  static const _timeout = Duration(seconds: 30);

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    final messages = [
      ...history,
      {'role': 'user', 'content': prompt},
    ];

    final body = jsonEncode({
      'model': model,
      'max_tokens': 8192,
      'stream': true,
      'system': systemPrompt,
      'messages': messages,
    });

    final request = http.Request('POST', Uri.parse('$baseUrl/v1/messages'))
      ..headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
        'content-type': 'application/json',
      })
      ..body = body;

    final response = await _httpClient.send(request).timeout(_timeout);

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Anthropic API error ${response.statusCode}: $errorBody');
    }

    // Parse SSE stream
    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      if (data == '[DONE]') break;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final type = json['type'] as String?;

        if (type == 'content_block_delta') {
          final delta = json['delta'] as Map<String, dynamic>?;
          final text = delta?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        }
      } catch (_) {
        // Skip malformed SSE lines
      }
    }
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}
