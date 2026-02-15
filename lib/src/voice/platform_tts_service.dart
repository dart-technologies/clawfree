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

  void _init() {
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('[PlatformTTS] Error: $msg');
    });
    _tts.setLanguage('en-AU');
    // _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);

    if (kDebugMode) {
      _printDiscovery();
    }
  }

  Future<void> _printDiscovery() async {
    final languages = await _tts.getLanguages;
    if (languages is List) {
      final enLangs = languages.where((l) => l.toString().startsWith('en')).toList();
      debugPrint('[PlatformTTS] Available EN languages: $enLangs');
    }
    final voices = await _tts.getVoices;
    if (voices is List) {
      final enVoices = voices.where((v) {
        final lang = v['locale']?.toString() ?? '';
        return lang.startsWith('en');
      }).toList();
      debugPrint('[PlatformTTS] Available EN voices: $enVoices');
    }
  }

  @override
  Future<bool> get isAvailable async {
    final engines = await _tts.getEngines;
    return engines is List && engines.isNotEmpty;
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    _isSpeaking = true;
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
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
