import 'earcon_service.dart';
import 'stt_service.dart';
import 'tts_service.dart';

/// Coordinates STT and TTS lifecycle to prevent conflicts.
class VoiceController {
  VoiceController({
    required SttService stt,
    required TtsService tts,
    EarconService? earcon,
  })  : _stt = stt,
        _tts = tts,
        _earcon = earcon;

  final SttService _stt;
  final TtsService _tts;
  final EarconService? _earcon;

  SttService get stt => _stt;
  TtsService get tts => _tts;

  /// When true, STT auto-starts after TTS finishes speaking.
  bool continuousMode = false;

  /// Hands-free wake word mode (iOS "Always-on" parity).
  ///
  /// When enabled the controller stays in a listening loop, discarding
  /// transcripts that don't begin with [wakePhrase].  Once the wake phrase
  /// is detected, the remaining transcript (after the phrase) is forwarded to
  /// [_handsFreeCallback].
  bool _handsFreeMode = false;
  bool get handsFreeMode => _handsFreeMode;

  /// The keyword that activates command processing in hands-free mode.
  static const wakePhrase = 'hey clawfree';

  SttResultCallback? _handsFreeCallback;

  /// Enable or disable hands-free wake word mode.
  ///
  /// When [enabled] is `true`, the controller starts a persistent listening
  /// loop that filters for [wakePhrase].  Recognised commands (text after the
  /// wake phrase) are forwarded to [onCommand].
  Future<void> setHandsFreeMode({
    required bool enabled,
    SttResultCallback? onCommand,
  }) async {
    _handsFreeMode = enabled;
    _handsFreeCallback = onCommand;

    if (enabled && onCommand != null) {
      await _startWakeLoop();
    } else {
      await _stt.stopListening();
    }
  }

  Future<void> _startWakeLoop() async {
    if (_tts.isSpeaking) await _tts.stop();

    await _stt.startListening(onResult: (transcript, isFinal) {
      if (!_handsFreeMode || _handsFreeCallback == null) return;

      final lower = transcript.toLowerCase();
      if (!lower.startsWith(wakePhrase)) {
        // Not a wake command — keep listening. If the recognition is final
        // (silence detected) restart the loop so the mic stays open.
        if (isFinal) _restartWakeLoop();
        return;
      }

      // Strip the wake phrase and forward the command portion.
      final command = transcript.substring(wakePhrase.length).trim();
      if (command.isNotEmpty || isFinal) {
        _handsFreeCallback!(
          command.isEmpty ? transcript : command,
          isFinal,
        );
      }
      // Re-enter the wake loop after a final result so we're always listening.
      if (isFinal) _restartWakeLoop();
    });
  }

  void _restartWakeLoop() {
    // Small delay to prevent rapid restart churn.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (_handsFreeMode) _startWakeLoop();
    });
  }

  /// Start listening for speech, pausing TTS if it's speaking.
  Future<void> startListening({required SttResultCallback onResult}) async {
    if (_tts.isSpeaking) {
      await _tts.stop();
    }
    _earcon?.playMicOpen();
    await _stt.startListening(onResult: onResult);
  }

  /// Stop listening for speech.
  Future<void> stopListening() async {
    _earcon?.playMicClose();
    await _stt.stopListening();
  }

  /// Speak text via TTS. If [continuousMode] is on, starts STT after speech.
  /// If [handsFreeMode] is on, restarts the wake loop after speech.
  Future<void> speak(String text, {SttResultCallback? onResult}) async {
    await _tts.speak(text);
    if (_handsFreeMode) {
      await _startWakeLoop();
    } else if (continuousMode && onResult != null) {
      await _stt.startListening(onResult: onResult);
    }
  }

  void dispose() {
    _handsFreeMode = false;
    _handsFreeCallback = null;
    _earcon?.dispose();
    _stt.dispose();
    _tts.dispose();
  }
}
