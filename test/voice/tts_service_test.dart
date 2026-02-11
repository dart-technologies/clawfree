import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/voice/tts_service.dart';

void main() {
  group('MockTtsService', () {
    late MockTtsService tts;

    setUp(() {
      tts = MockTtsService();
    });

    test('isAvailable returns true', () async {
      expect(await tts.isAvailable, isTrue);
    });

    test('isSpeaking is initially false', () {
      expect(tts.isSpeaking, isFalse);
    });

    test('speak sets isSpeaking then resets', () async {
      final future = tts.speak('Hi');
      // During speak, isSpeaking should be true
      expect(tts.isSpeaking, isTrue);
      await future;
      expect(tts.isSpeaking, isFalse);
    });

    test('stop resets isSpeaking', () async {
      // Start speaking (don't await — it's async)
      unawaited(tts.speak('A long sentence with many words here'));
      expect(tts.isSpeaking, isTrue);
      await tts.stop();
      expect(tts.isSpeaking, isFalse);
    });

    test('setRate completes without error', () async {
      await tts.setRate(0.5);
      await tts.setRate(1.0);
      await tts.setRate(0.0);
    });

    test('dispose completes without error', () {
      tts.dispose();
    });
  });
}

// Helper to avoid lint warning on unawaited futures in tests
void unawaited(Future<void> future) {}
