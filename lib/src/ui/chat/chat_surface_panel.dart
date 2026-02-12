import 'dart:ui';

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
    this.activeSurfaceId,
  });

  final List<MessageItem> surfaceMessages;
  final SurfaceHost surfaceHost;
  final String? activeSurfaceId;

  MessageItem _resolveTarget() {
    if (activeSurfaceId != null) {
      final match =
          surfaceMessages.where((m) => m.surfaceId == activeSurfaceId);
      if (match.isNotEmpty) return match.first;
    }
    return surfaceMessages.last;
  }

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

    final latest = _resolveTarget();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayBase = isDark ? Colors.black : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                overlayBase.withValues(alpha: 0.10),
                overlayBase.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
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
          ),
        ),
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
