import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_stt_service.dart';
import 'platform_tts_service.dart';
import 'stt_service.dart';
import 'tts_service.dart';

/// Creates platform-appropriate voice services.
abstract final class VoiceServiceFactory {
  static ({TtsService tts, SttService stt}) create({bool isDemo = false}) {
    if (isDemo || kIsWeb) {
      return (tts: MockTtsService(), stt: MockSttService());
    }
    return (tts: PlatformTtsService(), stt: PlatformSttService());
  }
}
