import 'package:clawfree/src/core/ai_client.dart';
import 'package:clawfree/src/core/demo_ai_client.dart';

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

/// A mock AI client that captures the systemPrompt for inspection.
class CapturingAiClient extends MockAiClient {
  CapturingAiClient({super.responses});

  String? lastSystemPrompt;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    lastSystemPrompt = systemPrompt;
    yield* super.sendStream(
      prompt,
      systemPrompt: systemPrompt,
      history: history,
    );
  }
}

/// A slow AI client that takes time to respond (to test isProcessing guard).
class SlowAiClient implements MockAiClient {
  @override
  int sendCount = 0;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    sendCount++;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    yield 'Slow response';
  }

  @override
  bool disposed = false;

  @override
  List<String> receivedPrompts = [];

  @override
  List<String> get responses => ['Slow response'];

  @override
  void dispose() {
    disposed = true;
  }
}

/// Client that always throws on every call.
class AlwaysFailClient implements DemoCacheAiClient {
  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    throw Exception('Always fails');
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Client that fails on the first call, then succeeds with plain text.
class FailOnceClient implements DemoCacheAiClient {
  int _callCount = 0;

  @override
  Stream<String> sendStream(
    String prompt, {
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async* {
    _callCount++;
    if (_callCount == 1) {
      throw Exception('First call fails');
    }
    yield 'Recovered successfully!';
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
