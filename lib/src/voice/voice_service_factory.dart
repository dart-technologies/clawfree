import 'stt_service.dart';
import 'tts_service.dart';
import 'platform_stt_service.dart';
import 'platform_tts_service.dart';

/// Creates platform-appropriate voice services.
abstract final class VoiceServiceFactory {
  static ({TtsService tts, SttService stt}) create({bool isDemo = false}) {
    if (isDemo) {
      return (tts: MockTtsService(), stt: MockSttService());
    }
    // 使用真實語音服務
    return (tts: PlatformTtsService(), stt: PlatformSttService());
  }
}
