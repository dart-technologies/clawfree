import 'package:flutter/material.dart';
import '../../core/message_item.dart';
import 'chat_message_bubble.dart';

/// Chat history overlay for the mobile layout.
///
/// Shows all text messages in the current session, designed to sit above a bottom tray.
class RecentChatOverlay extends StatelessWidget {
  const RecentChatOverlay({
    super.key,
    required this.messages,
    required this.maxBubbleWidth,
    this.isProcessing = false,
  });

  final List<MessageItem> messages;
  final double maxBubbleWidth;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    // We only care about text messages (user or AI), skip surfaces
    final displayMessages = messages
        .where((m) => !m.isSurface && (m.text != null && m.text!.isNotEmpty))
        .toList();

    if (displayMessages.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final msg in displayMessages)
          AnimatedMessageEntry(
            message: msg,
            child: ChatMessageBubble(
              message: msg,
              maxBubbleWidth: maxBubbleWidth,
              isProcessing: isProcessing,
              isStreaming:
                  isProcessing && msg == displayMessages.last && !msg.isUser,
            ),
          ),
      ],
    );
  }
}
