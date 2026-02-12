import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../clawfree_assets.dart';
import '../theme.dart';
import 'chat_message_bubble.dart';
import 'chat_surface_panel.dart';
import 'chat_surface_view.dart';

/// Scrollable message list with empty state and suggestion chips.
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.surfaceHost,
    required this.maxBubbleWidth,
    required this.isDesktop,
    required this.isProcessing,
    required this.onSend,
    this.onRetry,
  });

  final List<MessageItem> messages;
  final ScrollController scrollController;
  final SurfaceHost surfaceHost;
  final double maxBubbleWidth;
  final bool isDesktop;
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return _EmptyState(onSend: onSend);

    return ListView.builder(
      controller: scrollController,
      physics: ClawfreeTheme.isApple
          ? const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return AnimatedMessageEntry(
          message: message,
          child: _buildMessage(message),
        );
      },
    );
  }

  Widget _buildMessage(MessageItem message) {
    if (message.isSurface) {
      if (isDesktop) {
        return const SurfaceIndicator();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ChatSurfaceView(
          surfaceId: message.surfaceId!,
          surfaceHost: surfaceHost,
        ),
      );
    }

    return ChatMessageBubble(
      message: message,
      maxBubbleWidth: maxBubbleWidth,
      isProcessing: isProcessing,
      onRetry: onRetry,
    );
  }
}

/// Empty state with animated lobster icon and suggestion chips.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lobster icon with subtle glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClawfreeTheme.lobsterOrange.withValues(alpha: 0.08),
                ),
                child: Image.asset(
                  ClawfreeAssets.icon,
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What would you like to build?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Say or type something to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SuggestionChip(
                    icon: Icons.smart_toy_outlined,
                    label: 'Create a GitHub automation agent',
                    onTap: () => onSend('Create a GitHub automation agent'),
                  ),
                  _SuggestionChip(
                    icon: Icons.dashboard_outlined,
                    label: 'Show my agents',
                    onTap: () => onSend('Show my agents'),
                  ),
                  _SuggestionChip(
                    icon: Icons.send_outlined,
                    label: 'Create a Telegram bot',
                    onTap: () => onSend('Create a Telegram bot'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded suggestion chip with icon, hover effect, and smooth transition.
class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ClawfreeTheme.hoverDuration,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? ClawfreeTheme.lobsterOrange.withValues(alpha: 0.1)
                : (isDark ? ClawfreeTheme.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(ClawfreeTheme.radiusFull),
            border: Border.all(
              color: _isHovered
                  ? ClawfreeTheme.lobsterOrange.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.02),
                  blurRadius: _isHovered ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _isHovered
                    ? ClawfreeTheme.lobsterOrange
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isHovered
                      ? ClawfreeTheme.lobsterOrange
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
