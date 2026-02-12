import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../voice/stt_service.dart';
import '../voice/voice_controller.dart';
import 'theme.dart';

/// Encapsulates the mic button + voice listening state for the input bar.
///
/// - Short tap: toggle continuous mode
/// - Long press: push-to-talk (hold to record, release to send)
class VoiceInputWidget extends StatefulWidget {
  const VoiceInputWidget({
    super.key,
    required this.sttService,
    required this.enabled,
    required this.onTranscript,
    required this.onListeningChanged,
    this.voiceController,
  });

  final SttService sttService;
  final bool enabled;

  /// Called with the final transcript when the user finishes speaking.
  final ValueChanged<String> onTranscript;

  /// Called when the listening state changes (for UI hints like "Listening...").
  final ValueChanged<bool> onListeningChanged;

  /// Optional voice controller for continuous mode integration.
  final VoiceController? voiceController;

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _interimTranscript = '';
  bool _isPushToTalk = false;

  late final AnimationController _pulseController;

  String get interimTranscript => _interimTranscript;
  bool get isListening => _isListening;

  bool get _isContinuousMode =>
      widget.voiceController?.continuousMode ?? false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Short tap: toggle continuous mode.
  void _onTap() {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();

    final vc = widget.voiceController;
    if (vc != null) {
      vc.continuousMode = !vc.continuousMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vc.continuousMode
                ? 'Continuous listening ON'
                : 'Continuous listening OFF',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      // If turning on continuous mode, start listening immediately.
      if (vc.continuousMode && !_isListening) {
        _startListening();
      } else if (!vc.continuousMode && _isListening) {
        _stopAndSend();
      }
    } else {
      // Fallback: toggle listening (original behavior).
      if (_isListening) {
        _stopAndSend();
      } else {
        _startListening();
      }
    }
  }

  /// Long press start: push-to-talk begin.
  void _onLongPressStart(LongPressStartDetails _) {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    _isPushToTalk = true;
    _startListening();
  }

  /// Long press end: push-to-talk release → stop and send.
  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_isPushToTalk) return;
    _isPushToTalk = false;
    HapticFeedback.lightImpact();
    _stopAndSend();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _interimTranscript = '';
      widget.onListeningChanged(true);
    });
    _pulseController.repeat(reverse: true);

    widget.sttService.startListening(
      onResult: (transcript, isFinal) {
        setState(() => _interimTranscript = transcript);
        if (isFinal && transcript.isNotEmpty && !_isPushToTalk) {
          // Auto-finalize for non-push-to-talk.
          _finishListening(transcript);
        }
      },
    );
  }

  void _stopAndSend() {
    widget.sttService.stopListening();
    final transcript = _interimTranscript;
    _finishListening(transcript);
  }

  void _finishListening(String transcript) {
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isListening = false;
      _interimTranscript = '';
      widget.onListeningChanged(false);
    });
    if (transcript.isNotEmpty) {
      widget.onTranscript(transcript);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContinuous = _isContinuousMode;

    return Tooltip(
      message: _isListening
          ? 'Listening... (release to send)'
          : isContinuous
              ? 'Continuous mode ON (tap to toggle, hold to talk)'
              : 'Hold to talk, tap to toggle continuous',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: _onTap,
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale =
                  _isListening ? 1.0 + 0.15 * _pulseController.value : 1.0;
              final glowOpacity =
                  _isListening ? 0.3 + 0.4 * _pulseController.value : 0.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: _isListening
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: glowOpacity),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        )
                      : null,
                  child: child,
                ),
              );
            },
            child: AnimatedContainer(
              duration: ClawfreeTheme.hoverDuration,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening
                    ? Theme.of(context).colorScheme.error
                    : isContinuous
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening
                    ? Icons.mic
                    : isContinuous
                        ? Icons.hearing
                        : Icons.mic_none,
                color: _isListening
                    ? Theme.of(context).colorScheme.onError
                    : isContinuous
                        ? Theme.of(context).colorScheme.onTertiary
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
