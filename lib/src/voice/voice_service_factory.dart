import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_stt_service.dart';
import 'platform_tts_service.dart';
import 'stt_service.dart';
import 'tts_service.dart';

/// Creates platform-appropriate voice services.
abstract final class VoiceServiceFactory {
  static ({TtsService tts, SttService stt}) create({
    bool isDemo = false,
    bool forceRealTts = false,
  }) {
    final tts =
        (isDemo && !forceRealTts) || kIsWeb
            ? MockTtsService()
            : PlatformTtsService();
    final stt = (isDemo || kIsWeb) ? MockSttService() : PlatformSttService();
    return (tts: tts, stt: stt);
  }
}
