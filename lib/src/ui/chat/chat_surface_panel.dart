import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../clawfree_assets.dart';
import '../clawfree_icons.dart';
import '../theme.dart';
import 'chat_surface_view.dart';

/// Side panel showing the latest genUI surface or an empty state.
class ChatSurfacePanel extends StatelessWidget {
  const ChatSurfacePanel({
    super.key,
    required this.surfaceMessages,
    required this.surfaceHost,
  });

  final List<MessageItem> surfaceMessages;
  final SurfaceHost surfaceHost;

  @override
  Widget build(BuildContext context) {
    if (surfaceMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(ClawfreeAssets.icon, width: 80, height: 80),
            const SizedBox(height: 16),
            Text(
              'Generated UI will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final latest = surfaceMessages.last;
    return SingleChildScrollView(
      physics: ClawfreeTheme.isApple
          ? const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            )
          : null,
      padding: const EdgeInsets.all(16),
      child: ChatSurfaceView(
        surfaceId: latest.surfaceId!,
        surfaceHost: surfaceHost,
      ),
    );
  }
}

/// Small indicator chip shown in the message list for surface messages
/// when using the desktop two-panel layout.
class SurfaceIndicator extends StatelessWidget {
  const SurfaceIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ClawfreeIcons.dashboard,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'UI generated',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
