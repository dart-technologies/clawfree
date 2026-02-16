import 'dart:async';

import 'package:flutter/foundation.dart';
import 'earcon_service.dart';
import 'stt_service.dart';
import 'tts_service.dart';

/// Coordinates STT and TTS lifecycle to prevent conflicts and manage shared state.
class VoiceController extends ChangeNotifier {
  VoiceController({SttService? stt, TtsService? tts, EarconService? earcon})
    : _stt = stt,
      _tts = tts,
      _earcon = earcon;

  final SttService? _stt;
  final TtsService? _tts;
  final EarconService? _earcon;

  /// The underlying speech-to-text service.
  SttService? get stt => _stt;

  /// The underlying text-to-speech service.
  TtsService? get tts => _tts;

  /// The earcon service for acoustic feedback.
  EarconService? get earcon => _earcon;

  /// Whether voice services are available.
  Future<bool> get isAvailable async {
    if (_stt == null) return false;
    return await _stt.isAvailable;
  }

  /// Whether the service is currently listening for speech.
  bool get isListening => _stt?.isListening ?? false;

  /// Whether the service is currently speaking.
  bool get isSpeaking => _tts?.isSpeaking ?? false;

  /// Current partial transcript during listening.
  String _interimTranscript = '';
  String get interimTranscript => _interimTranscript;

  /// When true, STT auto-starts after TTS finishes speaking.
  bool continuousMode = false;

  /// When true, the microphone remains active during TTS playback to allow
  /// the user to interrupt the AI.
  bool bargeInEnabled = true;

  /// Hands-free wake word mode (iOS "Always-on" parity).
  bool _handsFreeMode = false;
  bool get handsFreeMode => _handsFreeMode;

  /// The keyword that activates command processing in hands-free mode.
  static const wakePhrase = 'hey clawfree';

  SttResultCallback? _handsFreeCallback;

  /// Enable or disable hands-free wake word mode.
  ///
  /// When enabled, the controller continuously listens for [wakePhrase]
  /// and dispatches following speech to [onCommand].
  Future<void> setHandsFreeMode({
    required bool enabled,
    SttResultCallback? onCommand,
  }) async {
    _handsFreeMode = enabled;
    _handsFreeCallback = onCommand;

    if (enabled && onCommand != null) {
      await _startWakeLoop();
    } else {
      await _stt?.stopListening();
    }
    notifyListeners();
  }

  Future<void> _startWakeLoop() async {
    if (isSpeaking) await _tts?.stop();

    await _stt?.startListening(
      onResult: (transcript, isFinal) {
        if (!_handsFreeMode || _handsFreeCallback == null) return;

        final lower = transcript.toLowerCase();

        // Fuzzy match or basic startsWith
        if (!lower.startsWith(wakePhrase)) {
          if (isFinal) _restartWakeLoop();
          return;
        }

        final command = transcript.length > wakePhrase.length
            ? transcript.substring(wakePhrase.length).trim()
            : '';

        if (command.isNotEmpty || isFinal) {
          _handsFreeCallback!(command.isEmpty ? transcript : command, isFinal);
        }
        if (isFinal) _restartWakeLoop();
      },
    );
    notifyListeners();
  }

  void _restartWakeLoop() {
    unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (_handsFreeMode) unawaited(_startWakeLoop());
    }));
  }

  /// Toggle the listening state.
  Future<void> toggleListening({required SttResultCallback onResult}) async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening(onResult: onResult);
    }
  }

  /// Start listening for speech, pausing TTS if it's speaking.
  Future<void> startListening({required SttResultCallback onResult}) async {
    if (isSpeaking) {
      await _tts?.stop();
    }

    _interimTranscript = '';
    unawaited(_earcon?.playMicOpen());

    await _stt?.startListening(
      onResult: (transcript, isFinal) {
        _interimTranscript = transcript;
        onResult(transcript, isFinal);
        if (isFinal) {
          _interimTranscript = '';
        }
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// Simulate a full STT voice command: enters listening state, emits words
  /// progressively via [MockSttService], and resolves with the final transcript.
  ///
  /// All UI layers react automatically because [startListening] updates
  /// [_interimTranscript] and calls [notifyListeners] on each word.
  Future<String> simulateVoiceCommand(
    String text, {
    Duration wordDelay = const Duration(milliseconds: 200),
  }) {
    assert(
      _stt is MockSttService,
      'simulateVoiceCommand requires MockSttService',
    );
    final completer = Completer<String>();

    unawaited(startListening(
      onResult: (transcript, isFinal) {
        if (isFinal && !completer.isCompleted) {
          completer.complete(transcript);
        }
      },
    ).then((_) {
      (_stt! as MockSttService).simulateInput(text, null, wordDelay);
    }));

    return completer.future;
  }

  /// Stop listening for speech.
  Future<void> stopListening() async {
    unawaited(_earcon?.playMicClose());
    await _stt?.stopListening();
    _interimTranscript = '';

    notifyListeners();
  }

  /// Stop everything (TTS and STT).
  Future<void> stop() async {
    await _tts?.stop();
    await _stt?.stopListening();
    _interimTranscript = '';

    notifyListeners();
  }

  /// Speak text via TTS.
  /// If [continuousMode] is on, starts STT after speech completion.
  /// If [bargeInEnabled] is on, keeps mic active during speech.
  Future<void> speak(String text, {SttResultCallback? onResult}) async {
    if (text.isEmpty || _tts == null) return;

    // If barge-in is enabled, we start listening BEFORE speaking.
    if (bargeInEnabled && _stt != null && !isListening) {
      await startListening(
        onResult: (transcript, isFinal) {
          // If the user speaks during TTS, we stop TTS immediately.
          if (transcript.isNotEmpty && isSpeaking) {
            _tts.stop();
            if (!_disposed) notifyListeners();
          }
          onResult?.call(transcript, isFinal);
        },
      );
    }

    await _tts.speak(text);
    if (!_disposed) notifyListeners();

    if (_handsFreeMode) {
      // In hands-free mode, we always go back to wake word loop
      await _startWakeLoop();
    } else if (continuousMode && !isListening && onResult != null) {
      // In continuous mode, we auto-start listening for the next turn
      await startListening(onResult: onResult);
    }
    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _handsFreeMode = false;
    _handsFreeCallback = null;

    _earcon?.dispose();
    _stt?.dispose();
    _tts?.dispose();
    super.dispose();
  }
}
