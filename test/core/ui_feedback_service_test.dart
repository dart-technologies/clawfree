import 'package:clawfree/src/core/ui_feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UIFeedbackService', () {
    late UIFeedbackService service;

    setUp(() {
      service = UIFeedbackService();
    });

    test('success creates message (not error)', () {
      final msg = service.success('Agent saved!');
      expect(msg.text, 'Agent saved!');
      expect(msg.isUser, false);
      expect(msg.isError, false);
    });

    test('error creates Error:-prefixed message', () {
      final msg = service.error('Something failed');
      expect(msg.text, 'Error: Something failed');
      expect(msg.isError, true);
    });

    test('info creates message (not error)', () {
      final msg = service.info('Processing...');
      expect(msg.text, 'Processing...');
      expect(msg.isError, false);
    });

    test('works without TTS service', () {
      final noTts = UIFeedbackService();
      final msg = noTts.success('No crash');
      expect(msg.text, 'No crash');
    });
  });
}
