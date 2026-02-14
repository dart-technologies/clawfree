import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/message_item.dart';
import '../clawfree_icons.dart';
import '../theme.dart';

/// Renders a single chat message (user, AI, or error) with context menu.
///
/// When [isStreaming] is true, shows a blinking cursor and shimmer sweep
/// effect to make the chunk-by-chunk typing visually obvious.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.maxBubbleWidth,
    this.isProcessing = false,
    this.isStreaming = false,
    this.onRetry,
  });

  final MessageItem message;
  final double maxBubbleWidth;
  final bool isProcessing;

  /// When true, shows a blinking cursor and shimmer on the AI text.
  final bool isStreaming;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final text = (message.text ?? '').trim();
    if (text.isEmpty && !isUser) return const SizedBox.shrink();

    if (message.isError) {
      return _ErrorBubble(
        message: message,
        maxBubbleWidth: maxBubbleWidth,
        isProcessing: isProcessing,
        onRetry: onRetry,
      );
    }

    final textStyle = TextStyle(
      color: isUser
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurface,
      fontSize: 12,
      height: 1.25,
    );

    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: isUser
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: ClawfreeBorderRadius.element,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : ClawfreeTheme.glassDecoration(context, borderRadius: 16),
        child: !isUser && isStreaming
            ? _StreamingText(text: text, style: textStyle)
            : Text(text, style: textStyle),
      ),
    );

    return _MessageContextMenu(message: message, child: bubble);
  }
}

/// Animated text with blinking cursor and shimmer sweep during AI streaming.
class _StreamingText extends StatefulWidget {
  const _StreamingText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText>
    with TickerProviderStateMixin {
  late AnimationController _cursorController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Blinking cursor: fade in/out at 530ms period
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);

    // Shimmer sweep: moves a highlight across the text
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _cursorController]),
      builder: (context, _) {
        final shimmerValue = _shimmerController.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            // Sweep a bright highlight across the text
            final sweep = shimmerValue * 3.0 - 1.0; // -1.0 to 2.0
            return LinearGradient(
              begin: Alignment(sweep - 0.3, 0),
              end: Alignment(sweep + 0.3, 0),
              colors: [
                widget.style.color ?? Colors.white,
                (widget.style.color ?? Colors.white).withValues(alpha: 0.5),
                widget.style.color ?? Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: widget.text, style: widget.style),
                WidgetSpan(
                  child: Opacity(
                    opacity: _cursorController.value,
                    child: Text(
                      '\u258C', // ▌ left half block
                      style: widget.style.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wraps each message with a fade + scale entry animation using organic physics.
class AnimatedMessageEntry extends StatelessWidget {
  const AnimatedMessageEntry({
    super.key,
    required this.message,
    required this.child,
    this.delay = Duration.zero,
  });

  final MessageItem message;
  final Widget child;

  /// Optional stagger delay before the animation starts.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(message.hashCode),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.97 + (0.03 * value), child: child),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ErrorBubble extends StatefulWidget {
  const _ErrorBubble({
    required this.message,
    required this.maxBubbleWidth,
    required this.isProcessing,
    this.onRetry,
  });

  final MessageItem message;
  final double maxBubbleWidth;
  final bool isProcessing;
  final VoidCallback? onRetry;

  @override
  State<_ErrorBubble> createState() => _ErrorBubbleState();
}

class _ErrorBubbleState extends State<_ErrorBubble> {
  @override
  void initState() {
    super.initState();
    // Haptic on error appearance
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final errorText = widget.message.text ?? 'Unknown error';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: widget.maxBubbleWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: ClawfreeBorderRadius.interactive,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.isProcessing
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onRetry?.call();
                    },
              icon: const Icon(ClawfreeIcons.refresh, size: 16),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContextMenu extends StatelessWidget {
  const _MessageContextMenu({required this.message, required this.child});

  final MessageItem message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (message.text == null || message.text!.isEmpty) return child;
    return GestureDetector(
      onSecondaryTapUp: (details) => _show(context, details.globalPosition),
      onLongPressStart: (details) => _show(context, details.globalPosition),
      child: child,
    );
  }

  void _show(BuildContext context, Offset position) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(ClawfreeIcons.copy, size: 16),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        if (message.isError)
          PopupMenuItem<String>(
            value: 'retry',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(ClawfreeIcons.refresh, size: 16),
                SizedBox(width: 8),
                Text('Retry'),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: message.text ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }
}
