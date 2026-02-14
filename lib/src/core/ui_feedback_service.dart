import '../voice/sound_service.dart';
import 'message_item.dart';

/// Unified service for user-facing feedback: combines earcon tones and
/// message creation into single calls.
///
/// TTS is handled centrally by [ChatSession] after processing interaction
/// results, so this service focuses on message creation and audio earcons.
class UIFeedbackService {
  UIFeedbackService({SoundService? soundService})
    : _soundService = soundService;

  final SoundService? _soundService;

  /// Create a success feedback message and play success earcon.
  MessageItem success(String msg) {
    _soundService?.success();
    return MessageItem.aiText(text: msg);
  }

  /// Create an error feedback message (prefixed with "Error:") and play error earcon.
  MessageItem error(String msg) {
    _soundService?.error();
    return MessageItem.error(text: 'Error: $msg');
  }

  /// Create an informational feedback message.
  MessageItem info(String msg) {
    return MessageItem.aiText(text: msg);
  }
}
