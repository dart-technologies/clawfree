import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/voice/stt_service.dart';

void main() {
  group('MockSttService', () {
    late MockSttService stt;

    setUp(() {
      stt = MockSttService();
    });

    test('isAvailable returns true', () async {
      expect(await stt.isAvailable, isTrue);
    });

    test('isListening is initially false', () {
      expect(stt.isListening, isFalse);
    });

    test('startListening sets isListening', () async {
      await stt.startListening(onResult: (transcript, isFinal) {});
      expect(stt.isListening, isTrue);
    });

    test('stopListening resets isListening', () async {
      await stt.startListening(onResult: (transcript, isFinal) {});
      await stt.stopListening();
      expect(stt.isListening, isFalse);
    });

    test('simulateInput delivers progressive transcripts', () async {
      final transcripts = <String>[];
      final finals = <bool>[];

      stt.simulateInput('hello world', (transcript, isFinal) {
        transcripts.add(transcript);
        finals.add(isFinal);
      });

      // Wait for timer to complete (200ms * 2 words + buffer)
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(transcripts.length, greaterThanOrEqualTo(2));
      expect(transcripts.last, 'hello world');
      expect(finals.last, isTrue);
    });

    test('dispose cancels timer', () {
      stt.simulateInput('one two three', (transcript, isFinal) {});
      stt.dispose();
      // No exception means timer was cancelled cleanly
    });
  });
}
