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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? ClawfreeTheme.darkSurface.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
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
      ),
    );

    // Frosted glass effect on Apple platforms
    if (ClawfreeTheme.isApple) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                        color: ClawfreeTheme.lobsterOrange,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(ClawfreeTheme.radiusXL),
        ),
        enabled: enabled,
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.send,
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: hintText,
        // Uses theme's inputDecorationTheme (rounded, filled)
      ),
      enabled: enabled,
      onSubmitted: (_) => _submit(),
      textInputAction: TextInputAction.send,
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildSendButton() {
    final canSend = !widget.isProcessing;

    if (ClawfreeTheme.isApple) {
      return Tooltip(
        message: 'Send message (\u2318Enter)',
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          onPressed: canSend ? _submit : null,
          child: AnimatedContainer(
            duration: ClawfreeTheme.hoverDuration,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: canSend
                  ? ClawfreeTheme.lobsterOrange
                  : ClawfreeTheme.lobsterOrange.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.arrow_up,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Send message (\u2318Enter)',
      child: AnimatedContainer(
        duration: ClawfreeTheme.hoverDuration,
        decoration: BoxDecoration(
          color: canSend
              ? ClawfreeTheme.lobsterOrange
              : ClawfreeTheme.lobsterOrange.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(ClawfreeIcons.send, size: 20),
          color: Colors.white,
          onPressed: canSend ? _submit : null,
        ),
      ),
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
                  color: ClawfreeTheme.lobsterOrange,
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
