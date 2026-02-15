import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../voice/voice_controller.dart';
import '../layouts/voice_orb.dart';
import '../clawfree_icons.dart';
import '../theme.dart';

/// Platform-adaptive input bar with text field, voice button, and send button.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.textController,
    this.voiceController,
    this.focusNode,
    required this.isProcessing,
    required this.onSend,
    this.mood = OrbMood.idle,
    this.accentColor,
    this.handsFreeEnabled = false,
    this.onToggleHandsFree,
  });

  final TextEditingController textController;
  final VoiceController? voiceController;
  final FocusNode? focusNode;
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final OrbMood mood;
  final Color? accentColor;
  final bool handsFreeEnabled;
  final VoidCallback? onToggleHandsFree;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderTraceCtrl;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _borderTraceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _borderTraceCtrl.dispose();
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      _borderTraceCtrl.forward(from: 0);
    } else {
      _borderTraceCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bar = AnimatedBuilder(
      animation: _borderTraceCtrl,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _BorderTracePainter(
            progress: _borderTraceCtrl.value,
            color: Theme.of(context).colorScheme.primary,
            borderRadius: 32,
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: ClawfreeTheme.hudSurfaceFaint,
          borderRadius: ClawfreeBorderRadius.pill,
          border: Border.all(
            color: ClawfreeTheme.hudBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Left: VoiceOrb (compact)
            _buildMicArea(),
            const SizedBox(width: 4),
            // Center: TextField
            Expanded(child: _buildInputField()),
            // Right: Action area
            _buildActionArea(),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: bar,
    );
  }

  Widget _buildMicArea() {
    final isListening = widget.voiceController?.isListening ?? false;
    if (widget.voiceController == null || widget.voiceController!.stt == null) {
      return const SizedBox(width: 8);
    }

    return Transform.scale(
      scale: 0.6,
      child: VoiceOrb(
        isListening: isListening,
        mood: widget.mood,
        onTap: () {
          if (isListening) {
            widget.voiceController!.stopListening();
          } else {
            widget.voiceController!.startListening(
              onResult: (transcript, isFinal) {
                if (isFinal && transcript.isNotEmpty) {
                  widget.onSend(transcript);
                }
              },
            );
          }
        },
        accentColor: widget.accentColor,
        size: 36,
        showTranscript: false,
      ),
    );
  }

  Widget _buildActionArea() {
    return ListenableBuilder(
      listenable: widget.textController,
      builder: (context, _) {
        final hasText = widget.textController.text.trim().isNotEmpty;
        final isListening = widget.voiceController?.isListening ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText && !isListening) ...[
              _buildSendButton(),
            ],
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }

  void _submit() {
    final text = widget.textController.text.trim();
    if (text.isEmpty) return;
    widget.textController.clear();
    widget.onSend(text);
  }

  Widget _buildInputField() {
    final isListening = widget.voiceController?.isListening ?? false;
    final interim = widget.voiceController?.interimTranscript ?? '';
    final hintText = isListening
        ? (interim.isNotEmpty ? interim : 'Listening...')
        : 'Speak a command...';
    final enabled = !widget.isProcessing && !isListening;

    if (ClawfreeTheme.isApple) {
      return CupertinoTextField(
        controller: widget.textController,
        focusNode: _effectiveFocusNode,
        placeholder: hintText,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        style: const TextStyle(fontSize: 14),
        placeholderStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        decoration: null, // Transparent
        enabled: enabled,
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.send,
        maxLines: 1,
      );
    }

    return TextField(
      controller: widget.textController,
      focusNode: _effectiveFocusNode,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        filled: false, // Transparent
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
      ),
      enabled: enabled,
      onSubmitted: (_) => _submit(),
      textInputAction: TextInputAction.send,
      maxLines: 1,
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
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              ClawfreeIcons.send,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(ClawfreeIcons.send),
        color: Theme.of(context).colorScheme.onPrimary,
        tooltip: 'Send message (\u2318Enter)',
        onPressed: widget.isProcessing ? null : _submit,
      ),
    );
  }
}

/// Draws a partial border tracing clockwise as [progress] goes from 0 → 1.
class _BorderTracePainter extends CustomPainter {
  _BorderTracePainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  final double progress;
  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final fullPath = ui.Path()..addRRect(rrect);
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final drawLength = totalLength * progress.clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.7 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    var remaining = drawLength;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final extract = metric.extractPath(0, remaining.clamp(0, metric.length));
      canvas.drawPath(extract, paint);
      remaining -= metric.length;
    }

    // Add a subtle glow at the tip of the trace
    if (progress > 0 && progress < 1) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final tipStart = (drawLength - 10).clamp(0.0, drawLength);
      for (final metric in metrics) {
        if (tipStart < metric.length) {
          final tipPath = metric.extractPath(
            tipStart,
            drawLength.clamp(0, metric.length),
          );
          canvas.drawPath(tipPath, glowPaint);
          break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BorderTracePainter old) =>
      progress != old.progress || color != old.color;
}
