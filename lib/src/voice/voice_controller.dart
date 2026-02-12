import 'package:flutter/foundation.dart';

import 'stt_service.dart';
import 'tts_service.dart';

/// Coordinates STT and TTS lifecycle to prevent conflicts.
class VoiceController extends ChangeNotifier {
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
  bool _continuousMode = false;
  bool get continuousMode => _continuousMode;
  set continuousMode(bool value) {
    if (_continuousMode == value) return;
    _continuousMode = value;
    notifyListeners();
  }

  /// Callback stored for continuous-mode auto-restart.
  SttResultCallback? _onResultCallback;

  /// Start listening for speech, pausing TTS if it's speaking.
  Future<void> startListening({required SttResultCallback onResult}) async {
    _onResultCallback = onResult;
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
    if (onResult != null) _onResultCallback = onResult;
    await _tts.speak(text);
    if (_continuousMode && _onResultCallback != null) {
      await _stt.startListening(onResult: _onResultCallback!);
    }
  }

  @override
  void dispose() {
    _stt.dispose();
    _tts.dispose();
    super.dispose();
  }
}
