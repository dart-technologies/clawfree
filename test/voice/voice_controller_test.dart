import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/voice_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ManualMockSttService mockStt;
  late ManualMockTtsService mockTts;
  late VoiceController controller;

  setUp(() {
    mockStt = ManualMockSttService();
    mockTts = ManualMockTtsService();
    controller = VoiceController(stt: mockStt, tts: mockTts);
  });

  tearDown(() {
    controller.dispose();
  });

  group('VoiceController Orchestration', () {
    test('isListening updates when start/stop listening called', () async {
      await controller.startListening(onResult: (_, _) {});
      expect(controller.isListening, isTrue);

      await controller.stopListening();
      expect(controller.isListening, isFalse);
    });

    test('isSpeaking updates when speak completes', () async {
      final speakFuture = controller.speak('Hello world');
      // Give it a microtask to start
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSpeaking, isTrue);

      await speakFuture;
      expect(controller.isSpeaking, isFalse);
    });

    test('continuousMode starts listening after TTS completes', () async {
      controller.continuousMode = true;
      controller.bargeInEnabled = false;

      await controller.speak('Hello', onResult: (transcript, isFinal) {});

      expect(mockTts.speakCount, 1);
      expect(mockStt.startListeningCount, 1);
    });

    test('bargeIn starts listening BEFORE TTS and stops TTS on speech', () async {
      controller.bargeInEnabled = true;
      controller.continuousMode = false;

      final speakFuture = controller.speak(
        'Long response',
        onResult: (t, f) {},
      );

      // Wait for it to start
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mockStt.startListeningCount, 1);
      expect(mockTts.speakCount, 1);
      expect(controller.isSpeaking, isTrue);

      // Simulate user speaking
      mockStt.simulateSpeech('Stop');

      // The speakFuture should now complete quickly because _tts.stop() was called
      await speakFuture;

      expect(mockTts.stopCount, 1);
      expect(controller.isSpeaking, isFalse);
    });

    test('stop() halts both services', () async {
      await controller.startListening(onResult: (_, _) {});
      final speakFuture = controller.speak('Infinite loop');

      await controller.stop();
      await speakFuture;

      expect(controller.isListening, isFalse);
      expect(controller.isSpeaking, isFalse);
      expect(mockTts.stopCount, 1);
      expect(mockStt.stopListeningCount, 1);
    });
  });
}

class ManualMockSttService implements SttService {
  bool isListeningValue = false;
  int startListeningCount = 0;
  int stopListeningCount = 0;
  SttResultCallback? activeCallback;

  @override
  bool get isListening => isListeningValue;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> startListening({required SttResultCallback onResult}) async {
    isListeningValue = true;
    startListeningCount++;
    activeCallback = onResult;
  }

  @override
  Future<void> stopListening() async {
    isListeningValue = false;
    stopListeningCount++;
    activeCallback = null;
  }

  void simulateSpeech(String transcript) {
    activeCallback?.call(transcript, false);
  }

  @override
  void dispose() {}
}

class ManualMockTtsService implements TtsService {
  bool isSpeakingValue = false;
  int speakCount = 0;
  int stopCount = 0;
  bool _shouldStop = false;

  @override
  bool get isSpeaking => isSpeakingValue;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> speak(String text) async {
    isSpeakingValue = true;
    speakCount++;
    _shouldStop = false;

    // Simulate speech duration with chunks to allow interruption
    for (var i = 0; i < 10; i++) {
      if (_shouldStop) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    isSpeakingValue = false;
  }

  @override
  Future<void> stop() async {
    _shouldStop = true;
    isSpeakingValue = false;
    stopCount++;
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  void dispose() {}
}
