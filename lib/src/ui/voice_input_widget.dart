import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../voice/earcon_service.dart';
import '../voice/stt_service.dart';

/// Encapsulates the mic button + voice listening state for the input bar.
class VoiceInputWidget extends StatefulWidget {
  const VoiceInputWidget({
    super.key,
    required this.sttService,
    required this.enabled,
    required this.onTranscript,
    required this.onListeningChanged,
    this.earconService,
  });

  final SttService sttService;
  final bool enabled;
  final EarconService? earconService;

  /// Called with the final transcript when the user finishes speaking.
  final ValueChanged<String> onTranscript;

  /// Called when the listening state changes (for UI hints like "Listening...").
  final ValueChanged<bool> onListeningChanged;

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _interimTranscript = '';

  late final AnimationController _pulseController;

  String get interimTranscript => _interimTranscript;
  bool get isListening => _isListening;

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

  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return; // prevent rapid double-tap
    _toggling = true;
    try {
      await _doToggle();
    } finally {
      _toggling = false;
    }
  }

  Future<void> _doToggle() async {
    HapticFeedback.selectionClick();
    if (_isListening) {
      widget.earconService?.playMicClose();
      await widget.sttService.stopListening();
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _isListening = false;
        widget.onListeningChanged(false);
        if (_interimTranscript.isNotEmpty) {
          widget.onTranscript(_interimTranscript);
          _interimTranscript = '';
        }
      });
    } else {
      // Check availability BEFORE updating UI state
      final available = await widget.sttService.isAvailable;
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition unavailable. Check microphone permissions in Settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      widget.earconService?.playMicOpen();
      setState(() {
        _isListening = true;
        _interimTranscript = '';
        widget.onListeningChanged(true);
      });
      _pulseController.repeat(reverse: true);
      await widget.sttService.startListening(
        onResult: (transcript, isFinal) {
          if (!mounted) return;
          setState(() => _interimTranscript = transcript);
          if (isFinal && transcript.isNotEmpty) {
            widget.sttService.stopListening();
            _pulseController.stop();
            _pulseController.reset();
            setState(() {
              _isListening = false;
              _interimTranscript = '';
              widget.onListeningChanged(false);
            });
            widget.onTranscript(transcript);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isListening ? 'Stop listening' : 'Start voice input',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: widget.enabled ? _toggle : null,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale =
                  _isListening ? 1.0 + 0.15 * _pulseController.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening
                    ? Theme.of(context).colorScheme.onError
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
