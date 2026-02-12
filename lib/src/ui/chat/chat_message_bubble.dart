import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/message_item.dart';
import '../clawfree_icons.dart';
import '../theme.dart';

/// Renders a single chat message (user, AI, or error) with context menu.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.maxBubbleWidth,
    this.isProcessing = false,
    this.onRetry,
  });

  final MessageItem message;
  final double maxBubbleWidth;
  final bool isProcessing;
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

    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(
            ClawfreeTheme.isApple ? 18 : 16,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );

    return _MessageContextMenu(message: message, child: bubble);
  }
}

/// Wraps each message with a slide-up + fade entry animation.
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
      duration: const Duration(milliseconds: 300) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
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
          borderRadius: BorderRadius.circular(16),
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
      onSecondaryTapUp: (details) =>
          _show(context, details.globalPosition),
      onLongPressStart: (details) =>
          _show(context, details.globalPosition),
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
