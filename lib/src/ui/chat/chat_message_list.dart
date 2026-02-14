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
    this.agentNames = const [],
  });

  final List<MessageItem> messages;
  final ScrollController scrollController;
  final SurfaceHost surfaceHost;
  final double maxBubbleWidth;
  final bool isDesktop;
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;
  final List<String> agentNames;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _EmptyState(onSend: onSend, agentNames: agentNames);
    }

    return ListView.builder(
      controller: scrollController,
      physics: ClawfreeTheme.isApple
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : null,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final stagger = Duration(milliseconds: 80 * (index % 5));
        // The last AI text message while processing is the streaming bubble.
        final isStreamingBubble =
            isProcessing &&
            !message.isUser &&
            !message.isSurface &&
            index == _lastAiTextIndex;
        return AnimatedMessageEntry(
          message: message,
          delay: stagger,
          child: _buildMessage(message, stagger, isStreamingBubble),
        );
      },
    );
  }

  /// Index of the last AI text message (for streaming indicator).
  int get _lastAiTextIndex {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isUser && !messages[i].isSurface) return i;
    }
    return -1;
  }

  Widget _buildMessage(
    MessageItem message, [
    Duration stagger = Duration.zero,
    bool isStreaming = false,
  ]) {
    if (message.isSurface) {
      if (isDesktop) {
        return const SurfaceIndicator();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      isStreaming: isStreaming,
      onRetry: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSend, required this.agentNames});

  final ValueChanged<String> onSend;
  final List<String> agentNames;

  bool get _hasTravelConcierge =>
      agentNames.any((name) => name.toLowerCase().contains('travel'));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
                'Say something to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _chip('Create an agent'),
                  _chip('Show my agents'),
                  _chip('Manage OpenClaw'),
                  _chip('Pair a device'),
                  _chip('Run a security scan'),
                  _chip('Check system health'),
                  if (_hasTravelConcierge) _chip('Plan a trip'),
                ],
              ),
            ],
          ),
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
