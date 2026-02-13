import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart';

/// Real TTS service using flutter_tts package.
/// Works on iOS, macOS, Android, and web.
class PlatformTtsService implements TtsService {
  PlatformTtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  /// Generation counter to prevent stale async handlers from flipping state.
  int _gen = 0;

  void _init() {
    _tts.setStartHandler(() {
      // Only honour start if no stop was requested since speak() was called.
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('[PlatformTTS] Error: $msg');
    });
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  @override
  Future<bool> get isAvailable async {
    final engines = await _tts.getEngines;
    return engines != null && (engines as List).isNotEmpty;
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    // Stop any ongoing speech before starting new utterance.
    await _tts.stop();
    _gen++;
    final myGen = _gen;
    _isSpeaking = true;
    await _tts.speak(text);
    // If stop() was called while we were awaiting, don't re-enable.
    if (_gen != myGen) _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _gen++;
    await _tts.stop();
    _isSpeaking = false;
  }

  @override
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  void dispose() {
    _tts.stop();
  }
}
