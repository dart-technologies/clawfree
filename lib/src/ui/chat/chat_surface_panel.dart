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
    this.borderRadius = 20.0,
  });

  final List<MessageItem> surfaceMessages;
  final SurfaceHost surfaceHost;
  final String? activeSurfaceId;
  final double borderRadius;

  MessageItem _resolveTarget() {
    if (activeSurfaceId != null) {
      final match = surfaceMessages.where(
        (m) => m.surfaceId == activeSurfaceId,
      );
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
            ClawfreeLogo(size: 120),
            const SizedBox(height: 16),
            Text(
              'GENERATED UI WILL APPEAR HERE',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final latest = _resolveTarget();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: ClawfreeTheme.blurSigma(1.0),
          sigmaY: ClawfreeTheme.blurSigma(1.0),
        ),
        child: DecoratedBox(
          decoration: ClawfreeTheme.glassDecoration(
            context,
            elevation: 1.0,
            borderRadius: borderRadius,
          ),
          child: SingleChildScrollView(
            primary: false,
            physics: ClawfreeTheme.isApple
                ? const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  )
                : null,
            padding: const EdgeInsets.all(24),
            child: ChatSurfaceView(
              key: Key('surface-panel-${latest.surfaceId}'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.8),
          borderRadius: ClawfreeBorderRadius.element,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ClawfreeIcons.dashboard,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'UI generated',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
