import 'dart:async';

import 'package:flutter/foundation.dart';

/// Callback when speech is recognized.
typedef SttResultCallback = void Function(String transcript, bool isFinal);

/// Speech-to-text service interface.
abstract class SttService {
  /// Whether STT is currently available on this platform.
  Future<bool> get isAvailable;

  /// Whether the service is actively listening.
  bool get isListening;

  /// Start listening for speech.
  Future<void> startListening({required SttResultCallback onResult});

  /// Stop listening.
  Future<void> stopListening();

  void dispose();
}

/// Mock STT service for development and web testing.
/// Simulates voice input with pre-defined phrases.
class MockSttService implements SttService {
  bool _isListening = false;
  Timer? _timer;
  SttResultCallback? _activeCallback;

  @override
  Future<bool> get isAvailable async => true;

  @override
  bool get isListening => _isListening;

  @override
  Future<void> startListening({required SttResultCallback onResult}) async {
    _isListening = true;
    _activeCallback = onResult;
    debugPrint('[MockSTT] Listening started');
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _activeCallback = null;
    _timer?.cancel();
    debugPrint('[MockSTT] Listening stopped');
  }

  /// Simulate a voice input (for testing/demo mode).
  ///
  /// When [onResult] is omitted, the stored callback from [startListening] is
  /// used, allowing VoiceController.simulateVoiceCommand to drive word-by-word
  /// emission through the normal listening pipeline.
  void simulateInput(
    String text, [
    SttResultCallback? onResult,
    Duration wordDelay = const Duration(milliseconds: 200),
  ]) {
    final callback = onResult ?? _activeCallback;
    assert(
      callback != null,
      'No callback: pass onResult or call startListening first',
    );
    debugPrint('[MockSTT] Simulating: "$text"');
    final words = text.split(' ');
    var spoken = '';
    var wordIndex = 0;

    _timer = Timer.periodic(wordDelay, (timer) {
      if (wordIndex >= words.length) {
        timer.cancel();
        callback!(text, true);
        return;
      }
      spoken += (spoken.isEmpty ? '' : ' ') + words[wordIndex];
      wordIndex++;
      callback!(spoken, wordIndex >= words.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}
