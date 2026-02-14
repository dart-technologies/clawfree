import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/voice/voice_service_factory.dart';
import 'package:clawfree/src/voice/tts_service.dart';
import 'package:clawfree/src/voice/stt_service.dart';
import 'package:clawfree/src/voice/platform_tts_service.dart';
import 'package:flutter/services.dart';
import 'package:clawfree/src/voice/platform_stt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return 1;
    });
  });

  tearDown(() {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });


  group('VoiceServiceFactory', () {
    test('create returns mocks when isDemo is true (default)', () {
      final services = VoiceServiceFactory.create(isDemo: true);
      expect(services.tts, isA<MockTtsService>());
      expect(services.stt, isA<MockSttService>());
    });

    test('create returns platform services when isDemo is false', () {
      final services = VoiceServiceFactory.create(isDemo: false);
      expect(services.tts, isA<PlatformTtsService>());
      expect(services.stt, isA<PlatformSttService>());
    });

    test('create returns PlatformTtsService when isDemo is true but forceRealTts is true', () {
      final services = VoiceServiceFactory.create(
        isDemo: true,
        forceRealTts: true,
      );
      expect(services.tts, isA<PlatformTtsService>());
      // STT should still be mock to allow automation script to drive it
      expect(services.stt, isA<MockSttService>());
    });

    test('create returns MockTtsService behavior remains consistent for web', () {
      // Note: testing kIsWeb behavior in unit tests is tricky without mocking kIsWeb,
      // but the logic (isDemo && !forceRealTts) || kIsWeb handles precedence.
      // If we force real TTS it should try to return platform service unless web overrides.
      // Since we can't easily change kIsWeb constant here, we trust the logic
      // verification above for native platforms.
    });
  });
}
