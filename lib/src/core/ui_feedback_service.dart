import '../voice/sound_service.dart';
import '../voice/tts_service.dart';
import 'message_item.dart';

/// Unified service for user-facing feedback: combines TTS speech, earcon
/// tones, and message creation into single calls.
class UIFeedbackService {
  UIFeedbackService({TtsService? ttsService, SoundService? soundService})
      : _ttsService = ttsService,
        _soundService = soundService;

  final TtsService? _ttsService;
  final SoundService? _soundService;

  /// Create a success feedback message and speak it via TTS.
  MessageItem success(String msg) {
    _ttsService?.speak(msg);
    _soundService?.success();
    return MessageItem.aiText(text: msg);
  }

  /// Create an error feedback message (prefixed with "Error:") and speak it.
  MessageItem error(String msg) {
    _ttsService?.speak(msg);
    _soundService?.error();
    return MessageItem.aiText(text: 'Error: $msg');
  }

  /// Create an informational feedback message and speak it.
  MessageItem info(String msg) {
    _ttsService?.speak(msg);
    return MessageItem.aiText(text: msg);
  }
}
