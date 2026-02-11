import 'stt_service.dart';
import 'tts_service.dart';

/// Creates platform-appropriate voice services.
abstract final class VoiceServiceFactory {
  static ({TtsService tts, SttService stt}) create({bool isDemo = false}) {
    // TODO: swap for real PlatformTtsService / PlatformSttService on device
    return (tts: MockTtsService(), stt: MockSttService());
  }
}
