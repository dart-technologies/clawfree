import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_service.dart';

/// Real STT service using speech_to_text package.
/// Works on iOS, macOS, Android, and web.
class PlatformSttService implements SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _initialized = false;

  @override
  Future<bool> get isAvailable async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (error) {
          debugPrint('[PlatformSTT] Error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('[PlatformSTT] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
    }
    return _initialized;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<void> startListening({required SttResultCallback onResult}) async {
    if (!await isAvailable) {
      debugPrint('[PlatformSTT] Speech recognition not available');
      return;
    }
    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
