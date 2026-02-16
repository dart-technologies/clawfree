import 'package:flutter/foundation.dart';

/// Text-to-speech service interface.
abstract class TtsService {
  /// Whether TTS is currently available on this platform.
  Future<bool> get isAvailable;

  /// Whether the service is currently speaking.
  bool get isSpeaking;

  /// Speak the given text aloud.
  Future<void> speak(String text);

  /// Stop speaking immediately.
  Future<void> stop();

  /// Set speech rate (0.0 to 1.0).
  Future<void> setRate(double rate);

  /// Set speech pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch);

  /// Set a specific voice by name. Returns true if voice was found and set.
  Future<bool> setVoice(String name);

  void dispose();
}

/// Mock TTS service for development and web testing.
class MockTtsService implements TtsService {
  bool _isSpeaking = false;

  @override
  Future<bool> get isAvailable async => true;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    _isSpeaking = true;
    debugPrint('[MockTTS] Speaking: "$text"');
    // Simulate speech duration (~100ms per word)
    final duration = text.split(' ').length * 100;
    await Future<void>.delayed(Duration(milliseconds: duration));
    _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    debugPrint('[MockTTS] Stopped');
  }

  @override
  Future<void> setRate(double rate) async {
    debugPrint('[MockTTS] Rate set to $rate');
  }

  @override
  Future<void> setPitch(double pitch) async {
    debugPrint('[MockTTS] Pitch set to $pitch');
  }

  @override
  Future<bool> setVoice(String name) async {
    debugPrint('[MockTTS] Voice set to $name');
    return true;
  }

  @override
  void dispose() {}
}
