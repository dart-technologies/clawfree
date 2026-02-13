import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_service.dart';

/// Real STT service using speech_to_text package.
/// Works on iOS, macOS, Android, and web.
class PlatformSttService implements SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _initialized = false;
  bool _initResult = false;
  SttResultCallback? _activeCallback;

  @override
  Future<bool> get isAvailable async {
    if (!_initialized) {
      debugPrint('[PlatformSTT] Initializing speech_to_text...');
      _initResult = await _speech.initialize(
        onError: (error) {
          debugPrint('[PlatformSTT] Error: ${error.errorMsg} (permanent=${error.permanent})');
          _isListening = false;
          // If the error is "not permitted", notify the active callback with empty final result
          // so the UI resets from listening state
          if (error.permanent && _activeCallback != null) {
            _activeCallback!('', true);
            _activeCallback = null;
          }
        },
        onStatus: (status) {
          debugPrint('[PlatformSTT] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      _initialized = true;
      debugPrint('[PlatformSTT] Init result: $_initResult, locales: ${_speech.locales().then((l) => l.map((e) => e.localeId).take(3).toList())}');
    }
    return _initResult;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<void> startListening({required SttResultCallback onResult}) async {
    if (!await isAvailable) {
      debugPrint('[PlatformSTT] Speech recognition not available — permission denied or unsupported');
      return;
    }
    debugPrint('[PlatformSTT] Starting listening...');
    _isListening = true;
    _activeCallback = onResult;
    await _speech.listen(
      onResult: (result) {
        debugPrint('[PlatformSTT] Result: "${result.recognizedWords}" final=${result.finalResult}');
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) _activeCallback = null;
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
    debugPrint('[PlatformSTT] Stopping listening');
    _isListening = false;
    _activeCallback = null;
    await _speech.stop();
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
