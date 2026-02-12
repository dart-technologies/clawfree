import 'package:clawfree/src/core/ui_feedback_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UIFeedbackService', () {
    late _RecordingTts tts;
    late UIFeedbackService service;

    setUp(() {
      tts = _RecordingTts();
      service = UIFeedbackService(ttsService: tts);
    });

    test('success creates message and speaks', () {
      final msg = service.success('Agent saved!');
      expect(msg.text, 'Agent saved!');
      expect(msg.isUser, false);
      expect(msg.isError, false);
      expect(tts.spoken, ['Agent saved!']);
    });

    test('error creates Error:-prefixed message and speaks', () {
      final msg = service.error('Something failed');
      expect(msg.text, 'Error: Something failed');
      expect(msg.isError, true);
      expect(tts.spoken, ['Something failed']);
    });

    test('info creates message and speaks', () {
      final msg = service.info('Processing...');
      expect(msg.text, 'Processing...');
      expect(msg.isError, false);
      expect(tts.spoken, ['Processing...']);
    });

    test('works without TTS service', () {
      final noTts = UIFeedbackService();
      final msg = noTts.success('No crash');
      expect(msg.text, 'No crash');
    });
  });
}

class _RecordingTts implements TtsService {
  final List<String> spoken = [];

  @override
  Future<bool> get isAvailable async => true;

  @override
  bool get isSpeaking => false;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  void dispose() {}
}
