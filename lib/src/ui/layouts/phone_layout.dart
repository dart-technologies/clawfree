import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../../core/prompt_library.dart';
import '../../core/remote_session.dart';
import '../../voice/stt_service.dart';
import '../chat/chat_input_bar.dart';
import '../chat/chat_message_list.dart';
import '../chat/chat_surface_view.dart';
import '../health/health_indicators.dart';
import '../widgets/remote_session_indicator.dart';
import 'voice_orb.dart';

/// iPhone "Mobile Remote" layout.
///
/// Top: compact connectivity bar (3 status dots) + active agent pill.
/// Center: VoiceOrb + latest A2UI surface mini-card.
/// Bottom: 4-icon quick action grid + mute toggle.
class PhoneLayout extends StatelessWidget {
  const PhoneLayout({
    super.key,
    required this.messages,
    required this.surfaceHost,
    required this.scrollController,
    required this.textController,
    required this.sttService,
    required this.isProcessing,
    required this.healthState,
    required this.isListening,
    this.isSpeaking = false,
    required this.interimTranscript,
    required this.isHomeDashboard,
    required this.activeAgentName,
    required this.handsFreeEnabled,
    required this.onSend,
    required this.onRetry,
    required this.onToggleVoice,
    required this.onToggleHandsFree,
    required this.onQuickAction,
    this.onPairDevice,
    this.sessionMode = SessionMode.home,
    this.activeSurfaceId,
    this.remoteSessions = const [],
  });

  final SessionMode sessionMode;
  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final ScrollController scrollController;
  final TextEditingController textController;
  final SttService? sttService;
  final bool isProcessing;
  final HealthState healthState;
  final bool isListening;
  final bool isSpeaking;
  final String interimTranscript;
  final bool isHomeDashboard;
  final String? activeAgentName;
  final bool handsFreeEnabled;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;
  final VoidCallback onToggleVoice;
  final VoidCallback onToggleHandsFree;
  final ValueChanged<String> onQuickAction;
  final VoidCallback? onPairDevice;
  final String? activeSurfaceId;
  final List<RemoteSession> remoteSessions;

  Color _accentForMode(BuildContext context) {
    return switch (sessionMode) {
      SessionMode.onboarding => const Color(0xFF9C27B0),
      SessionMode.home => const Color(0xFF2196F3),
      SessionMode.agentBuilder => Theme.of(context).colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isHomeDashboard) return _buildHomeDashboard(context);
    return _buildChatMode(context);
  }

  /// Home dashboard: voice-centric with quick actions.
  Widget _buildHomeDashboard(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        // -- Top: Connectivity bar --
        _ConnectivityBar(
          healthState: healthState,
          activeAgentName: activeAgentName,
          remoteSessions: remoteSessions,
        ),
        // -- Center: Voice Orb + latest surface --
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VoiceOrb(
                    isListening: isListening,
                    isSpeaking: isSpeaking,
                    interimTranscript: interimTranscript,
                    onTap: onToggleVoice,
                    accentColor: _accentForMode(context),
                  ),
                  const SizedBox(height: 20),
                  _LatestSurfaceMiniCard(
                    messages: messages,
                    surfaceHost: surfaceHost,
                    maxWidth: width - 32,
                    activeSurfaceId: activeSurfaceId,
                  ),
                ],
              ),
            ),
          ),
        ),
        // -- Bottom: Quick actions + mute toggle --
        _QuickActionGrid(
          onQuickAction: onQuickAction,
          handsFreeEnabled: handsFreeEnabled,
          onToggleHandsFree: onToggleHandsFree,
          onPairDevice: onPairDevice,
        ),
      ],
    );
  }

  /// Standard chat mode (single column).
  Widget _buildChatMode(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        _ConnectivityBar(
          healthState: healthState,
          activeAgentName: activeAgentName,
          remoteSessions: const [],
        ),
        Expanded(
          child: ChatMessageList(
            messages: messages,
            scrollController: scrollController,
            surfaceHost: surfaceHost,
            maxBubbleWidth: width * 0.8,
            isDesktop: false,
            isProcessing: isProcessing,
            onSend: onSend,
            onRetry: onRetry,
          ),
        ),
        ChatInputBar(
          controller: textController,
          sttService: sttService,
          isProcessing: isProcessing,
          onSend: onSend,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top: Connectivity bar
// ---------------------------------------------------------------------------

class _ConnectivityBar extends StatelessWidget {
  const _ConnectivityBar({
    required this.healthState,
    required this.activeAgentName,
    this.remoteSessions = const [],
  });

  final HealthState healthState;
  final String? activeAgentName;
  final List<RemoteSession> remoteSessions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Three status dots: Gateway, API, Sync
          HealthDotBar(
            state: HealthState(
              gateway: healthState.gateway,
              llm: healthState.llm,
              channels: healthState.channels,
            ),
          ),
          for (final session in remoteSessions) ...[
            const SizedBox(width: 8),
            RemoteSessionIndicator(
              icon: iconForDeviceType(session.deviceType),
              label: session.deviceName,
              dotSize: 5,
              iconSize: 10,
              fontSize: 9,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          ],
          const Spacer(),
          if (activeAgentName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activeAgentName!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Center: Latest surface mini-card
// ---------------------------------------------------------------------------

class _LatestSurfaceMiniCard extends StatelessWidget {
  const _LatestSurfaceMiniCard({
    required this.messages,
    required this.surfaceHost,
    required this.maxWidth,
    this.activeSurfaceId,
  });

  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final double maxWidth;
  final String? activeSurfaceId;

  @override
  Widget build(BuildContext context) {
    final surfaces = messages.where((m) => m.isSurface).toList();
    if (surfaces.isEmpty) return const SizedBox.shrink();

    MessageItem latest = surfaces.last;
    if (activeSurfaceId != null) {
      final match = surfaces.where((m) => m.surfaceId == activeSurfaceId);
      if (match.isNotEmpty) latest = match.first;
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 360),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: ChatSurfaceView(
            surfaceId: latest.surfaceId!,
            surfaceHost: surfaceHost,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom: Quick action grid
// ---------------------------------------------------------------------------

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.onQuickAction,
    required this.handsFreeEnabled,
    required this.onToggleHandsFree,
    this.onPairDevice,
  });

  final ValueChanged<String> onQuickAction;
  final bool handsFreeEnabled;
  final VoidCallback onToggleHandsFree;
  final VoidCallback? onPairDevice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickActionItem(
                icon: Icons.add_circle_outline,
                label: 'New Agent',
                onTap: () => onQuickAction('Create a new agent'),
              ),
              _QuickActionItem(
                icon: Icons.settings,
                label: 'Manage',
                onTap: () => onQuickAction('Manage OpenClaw'),
              ),
              _QuickActionItem(
                icon: Icons.watch,
                label: 'Pair Watch',
                onTap: () {
                  if (onPairDevice != null) {
                    onPairDevice!();
                  } else {
                    onQuickAction('Pair a device');
                  }
                },
              ),
              _QuickActionItem(
                icon: Icons.extension,
                label: 'Skills',
                onTap: () => onQuickAction('Show skill library'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mute/Unmute toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                handsFreeEnabled ? Icons.mic : Icons.mic_off,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Hands-free',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 28,
                child: Switch.adaptive(
                  value: handsFreeEnabled,
                  onChanged: (_) {
                    HapticFeedback.selectionClick();
                    onToggleHandsFree();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
