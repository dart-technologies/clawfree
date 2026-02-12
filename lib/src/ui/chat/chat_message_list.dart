import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../clawfree_icons.dart';
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
        final stagger = Duration(milliseconds: 80 * (index % 5));
        return AnimatedMessageEntry(
          message: message,
          delay: stagger,
          child: _buildMessage(message, stagger),
        );
      },
    );
  }

  Widget _buildMessage(MessageItem message, [Duration stagger = Duration.zero]) {
    if (message.isSurface) {
      if (isDesktop) {
        return const SurfaceIndicator();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ChatSurfaceView(
          surfaceId: message.surfaceId!,
          surfaceHost: surfaceHost,
          entranceDelay: stagger,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ClawfreeIcons.mic,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Say or type something to get started',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chip('Create a GitHub automation agent'),
                _chip('Plan a trip'),
                _chip('Show my agents'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 13)),
      onPressed: () {
        HapticFeedback.lightImpact();
        onSend(text);
      },
    );
  }
}
