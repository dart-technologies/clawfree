import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../voice/stt_service.dart';
import '../../voice/voice_controller.dart';
import '../clawfree_icons.dart';
import '../theme.dart';
import '../voice_input_widget.dart';

/// Platform-adaptive input bar with text field, voice button, and send button.
///
/// When [handsFreeMode] is true, only the voice widget is shown (no text field).
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    this.sttService,
    this.voiceController,
    required this.isProcessing,
    required this.onSend,
    this.handsFreeMode = false,
  });

  final TextEditingController controller;
  final SttService? sttService;
  final VoiceController? voiceController;
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final bool handsFreeMode;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isListening = false;
  String _interimTranscript = '';

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ClawfreeTheme.isApple
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.85)
            : Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: widget.handsFreeMode
          ? _buildHandsFreeBar()
          : Row(
              children: [
                if (widget.sttService != null)
                  VoiceInputWidget(
                    sttService: widget.sttService!,
                    voiceController: widget.voiceController,
                    enabled: !widget.isProcessing,
                    onTranscript: widget.onSend,
                    onListeningChanged: (listening) {
                      setState(() {
                        _isListening = listening;
                        if (!listening) _interimTranscript = '';
                      });
                    },
                  ),
                Expanded(child: _buildInputField()),
                const SizedBox(width: 8),
                _buildSendButton(),
              ],
            ),
    );

    if (ClawfreeTheme.isApple) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: bar,
        ),
      );
    }
    return bar;
  }

  /// Hands-free bar: large centered mic button with animated waveform ring.
  Widget _buildHandsFreeBar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _interimTranscript.isNotEmpty
                      ? _interimTranscript
                      : 'Listening...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (widget.sttService != null)
              _HandsFreeWaveformRing(
                isListening: _isListening,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: VoiceInputWidget(
                    sttService: widget.sttService!,
                    voiceController: widget.voiceController,
                    enabled: !widget.isProcessing,
                    onTranscript: widget.onSend,
                    onListeningChanged: (listening) {
                      setState(() {
                        _isListening = listening;
                        if (!listening) _interimTranscript = '';
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.controller.clear();
    widget.onSend(text);
  }

  Widget _buildInputField() {
    final hintText = _isListening
        ? (_interimTranscript.isNotEmpty ? _interimTranscript : 'Listening...')
        : 'Type or speak a command...';
    final enabled = !widget.isProcessing && !_isListening;

    if (ClawfreeTheme.isApple) {
      return CupertinoTextField(
        controller: widget.controller,
        placeholder: hintText,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        enabled: enabled,
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.send,
      );
    }

    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      enabled: enabled,
      onSubmitted: (_) => _submit(),
      textInputAction: TextInputAction.send,
    );
  }

  Widget _buildSendButton() {
    if (ClawfreeTheme.isApple) {
      return Tooltip(
        message: 'Send message (\u2318Enter)',
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          onPressed: widget.isProcessing ? null : _submit,
          child: Icon(
            ClawfreeIcons.send,
            size: 32,
            color: widget.isProcessing
                ? CupertinoColors.systemGrey
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return IconButton.filled(
      icon: Icon(ClawfreeIcons.send),
      tooltip: 'Send message (\u2318Enter)',
      onPressed: widget.isProcessing ? null : _submit,
    );
  }
}

/// Animated concentric rings that pulse outward when listening in hands-free mode.
class _HandsFreeWaveformRing extends StatefulWidget {
  const _HandsFreeWaveformRing({
    required this.isListening,
    required this.child,
  });

  final bool isListening;
  final Widget child;

  @override
  State<_HandsFreeWaveformRing> createState() =>
      _HandsFreeWaveformRingState();
}

class _HandsFreeWaveformRingState extends State<_HandsFreeWaveformRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isListening) _controller.repeat();
  }

  @override
  void didUpdateWidget(_HandsFreeWaveformRing old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && old.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: widget.isListening
              ? _WaveformRingPainter(
                  progress: _controller.value,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _WaveformRingPainter extends CustomPainter {
  _WaveformRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * (0.6 + 0.4 * ringProgress);
      final opacity = (1.0 - ringProgress).clamp(0.0, 0.5);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformRingPainter old) =>
      old.progress != progress || old.color != color;
}
