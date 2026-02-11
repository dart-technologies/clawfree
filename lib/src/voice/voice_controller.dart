import 'stt_service.dart';
import 'tts_service.dart';

/// Coordinates STT and TTS lifecycle to prevent conflicts.
class VoiceController {
  VoiceController({
    required SttService stt,
    required TtsService tts,
  })  : _stt = stt,
        _tts = tts;

  final SttService _stt;
  final TtsService _tts;

  SttService get stt => _stt;
  TtsService get tts => _tts;

  /// When true, STT auto-starts after TTS finishes speaking.
  bool continuousMode = false;

  /// Start listening for speech, pausing TTS if it's speaking.
  Future<void> startListening({required SttResultCallback onResult}) async {
    if (_tts.isSpeaking) {
      await _tts.stop();
    }
    await _stt.startListening(onResult: onResult);
  }

  /// Stop listening for speech.
  Future<void> stopListening() async {
    await _stt.stopListening();
  }

  /// Speak text via TTS. If [continuousMode] is on, starts STT after speech.
  Future<void> speak(String text, {SttResultCallback? onResult}) async {
    await _tts.speak(text);
    if (continuousMode && onResult != null) {
      await _stt.startListening(onResult: onResult);
    }
  }

  void dispose() {
    _stt.dispose();
    _tts.dispose();
  }
}
