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
    this.isSpeaking = false,
    this.onRetry,
  });

  final MessageItem message;
  final double maxBubbleWidth;
  final bool isProcessing;
  final bool isSpeaking;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // User bubble: brand orange; AI bubble: subtle surface card
    final bubbleColor = isUser
        ? ClawfreeTheme.lobsterOrange
        : isDark
            ? ClawfreeTheme.darkCard
            : Colors.white;

    final textColor = isUser
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    // Directional border radius for a modern chat look
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(ClawfreeTheme.radiusL),
            topRight: Radius.circular(ClawfreeTheme.radiusL),
            bottomLeft: Radius.circular(ClawfreeTheme.radiusL),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(ClawfreeTheme.radiusL),
            bottomLeft: Radius.circular(ClawfreeTheme.radiusL),
            bottomRight: Radius.circular(ClawfreeTheme.radiusL),
          );

    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && isSpeaking)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: _TtsSpeakingIndicator(),
            ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: (isUser
                              ? ClawfreeTheme.lobsterOrange
                              : Colors.black)
                          .withValues(alpha: isUser ? 0.15 : 0.04),
                      blurRadius: isUser ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  if (isDark && !isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
                border: (!isUser && isDark)
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      )
                    : null,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
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
  });

  final MessageItem message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(message.hashCode),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: ClawfreeTheme.transitionDuration,
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Animated speaker icon shown next to AI bubbles during TTS playback.
class _TtsSpeakingIndicator extends StatefulWidget {
  const _TtsSpeakingIndicator();

  @override
  State<_TtsSpeakingIndicator> createState() => _TtsSpeakingIndicatorState();
}

class _TtsSpeakingIndicatorState extends State<_TtsSpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
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
        return Opacity(
          opacity: 0.4 + 0.6 * _controller.value,
          child: Icon(
            Icons.volume_up,
            size: 16,
            color: ClawfreeTheme.lobsterOrange,
          ),
        );
      },
    );
  }
}

class _ErrorBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final errorText = message.text ?? 'Unknown error';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(ClawfreeTheme.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ClawfreeIcons.error,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    errorText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isProcessing ? null : onRetry,
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
