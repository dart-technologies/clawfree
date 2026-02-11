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

  @override
  Future<bool> get isAvailable async => true;

  @override
  bool get isListening => _isListening;

  @override
  Future<void> startListening({required SttResultCallback onResult}) async {
    _isListening = true;
    debugPrint('[MockSTT] Listening started');
    // In mock mode, do nothing -- the UI text field is the input method.
    // Real STT will call onResult with transcripts.
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _timer?.cancel();
    debugPrint('[MockSTT] Listening stopped');
  }

  /// Simulate a voice input (for testing/demo mode).
  void simulateInput(String text, SttResultCallback onResult) {
    debugPrint('[MockSTT] Simulating: "$text"');
    // Simulate progressive recognition
    final words = text.split(' ');
    var spoken = '';
    var wordIndex = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (wordIndex >= words.length) {
        timer.cancel();
        onResult(text, true);
        return;
      }
      spoken += (spoken.isEmpty ? '' : ' ') + words[wordIndex];
      wordIndex++;
      onResult(spoken, wordIndex >= words.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}
