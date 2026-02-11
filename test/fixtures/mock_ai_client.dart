import 'package:clawfree/src/core/ai_client.dart';

/// A mock AI client that yields predefined chunks for testing.
class MockAiClient implements AiClient {
  MockAiClient({this.responses = const ['Hello ', 'world!']});

  final List<String> responses;
  bool disposed = false;
  int sendCount = 0;
  List<String> receivedPrompts = [];

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    sendCount++;
    receivedPrompts.add(prompt);
    for (final chunk in responses) {
      yield chunk;
    }
  }

  @override
  void dispose() {
    disposed = true;
  }
}

/// A mock AI client that throws an error.
class ErrorAiClient implements AiClient {
  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    throw Exception('API error 429: Rate limited');
  }

  @override
  void dispose() {}
}

/// A mock AI client that throws on first N attempts then succeeds.
class FailThenSucceedClient implements AiClient {
  FailThenSucceedClient({required this.failCount});

  final int failCount;
  int callCount = 0;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    callCount++;
    if (callCount <= failCount) {
      throw Exception('Simulated error');
    }
    yield 'Success after retry';
  }

  @override
  void dispose() {}
}
