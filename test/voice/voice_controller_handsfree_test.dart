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

  group('VoiceController Hands-free Mode', () {
    test('enabling hands-free mode starts listening', () async {
      await controller.setHandsFreeMode(enabled: true, onCommand: (t, f) {});
      expect(controller.handsFreeMode, isTrue);
      expect(mockStt.isListening, isTrue);
      expect(mockStt.startListeningCount, 1);
    });

    test('disabling hands-free mode stops listening', () async {
      await controller.setHandsFreeMode(enabled: true, onCommand: (t, f) {});
      await controller.setHandsFreeMode(enabled: false);
      expect(controller.handsFreeMode, isFalse);
      expect(mockStt.stopListeningCount, 1);
    });

    test('ignores speech that does not contain wake word', () async {
      String? detectedCommand;
      await controller.setHandsFreeMode(
        enabled: true,
        onCommand: (t, f) => detectedCommand = t,
      );

      mockStt.simulateSpeech('hello there', isFinal: false);
      expect(detectedCommand, isNull);
    });

    test('triggers callback when wake word detected', () async {
      String? detectedCommand;
      await controller.setHandsFreeMode(
        enabled: true,
        onCommand: (t, f) => detectedCommand = t,
      );

      mockStt.simulateSpeech('hey clawfree what is the time', isFinal: false);
      expect(detectedCommand, 'what is the time');
    });

    test('restarts wake loop after final result', () async {
      await controller.setHandsFreeMode(enabled: true, onCommand: (t, f) {});
      
      final initialStartCount = mockStt.startListeningCount;
      
      mockStt.simulateSpeech('hey clawfree do something', isFinal: true);
      
      // Wait for the restart delay (300ms)
      await Future<void>.delayed(const Duration(milliseconds: 400));
      
      expect(mockStt.startListeningCount, initialStartCount + 1);
    });

    test('restarts wake loop even if no wake word was detected but result is final', () async {
      await controller.setHandsFreeMode(enabled: true, onCommand: (t, f) {});
      
      final initialStartCount = mockStt.startListeningCount;
      
      mockStt.simulateSpeech('random noise', isFinal: true);
      
      await Future<void>.delayed(const Duration(milliseconds: 400));
      
      expect(mockStt.startListeningCount, initialStartCount + 1);
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

  void simulateSpeech(String transcript, {required bool isFinal}) {
    activeCallback?.call(transcript, isFinal);
  }

  @override
  void dispose() {}
}

class ManualMockTtsService implements TtsService {
  bool isSpeakingValue = false;

  @override
  bool get isSpeaking => isSpeakingValue;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> speak(String text) async {
    isSpeakingValue = true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    isSpeakingValue = false;
  }

  @override
  Future<void> stop() async {
    isSpeakingValue = false;
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<bool> setVoice(String name) async {
    return true;
  }

  @override
  void dispose() {}
}
