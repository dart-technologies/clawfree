import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';

import '../../core/input_coordinator.dart';
import '../../core/message_item.dart';
import '../../core/prompt_library.dart';
import '../../core/remote_session.dart';
import '../../devices/device_registry.dart';
import '../../voice/stt_service.dart';
import '../chat/chat_input_bar.dart';
import '../chat/chat_message_list.dart';
import '../chat/chat_surface_view.dart';
import '../health/health_indicators.dart';
import '../theme.dart';
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
    this.onViewDevices,
    this.onManageWatch,
    this.sessionMode = SessionMode.home,
    this.activeSurfaceId,
    this.remoteSessions = const [],
    this.activeInputSource,
    this.queuedInputSource,
    this.watchConnectionState,
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
  final VoidCallback? onViewDevices;
  final VoidCallback? onManageWatch;
  final String? activeSurfaceId;
  final List<RemoteSession> remoteSessions;
  final InputSource? activeInputSource;
  final InputSource? queuedInputSource;
  final WatchConnectionState? watchConnectionState;

  Color _accentForMode(BuildContext context) {
    return switch (sessionMode) {
      SessionMode.onboarding => const Color(0xFF9C27B0),
      SessionMode.home => const Color(0xFF00BFA5),
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
        // -- Watch active banner --
        if (activeInputSource == InputSource.watch)
          _ActiveSourceBanner(
            icon: Icons.watch,
            label: 'Watch is talking',
            color: ClawfreeTheme.teal,
          ),
        if (queuedInputSource == InputSource.phone &&
            activeInputSource == InputSource.watch)
          _QueuedBanner(),
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
                  if (messages.where((m) => m.isSurface).isEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'What would you like to build?',
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _SuggestionChip(
                          label: '🤖 Create an agent',
                          onTap: () => onQuickAction('Create a new agent'),
                        ),
                        _SuggestionChip(
                          label: '⌚ Pair Apple Watch',
                          onTap: () {
                            if (onPairDevice != null) {
                              onPairDevice!();
                            } else {
                              onQuickAction('Pair a device');
                            }
                          },
                        ),
                        _SuggestionChip(
                          label: '📊 Show analytics',
                          onTap: () => onQuickAction('Show analytics'),
                        ),
                      ],
                    ),
                  ],
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
          onViewDevices: onViewDevices,
          onManageWatch: onManageWatch,
          watchConnectionState: watchConnectionState,
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
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
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
    ),
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
    this.onViewDevices,
    this.onManageWatch,
    this.watchConnectionState,
  });

  final ValueChanged<String> onQuickAction;
  final bool handsFreeEnabled;
  final VoidCallback onToggleHandsFree;
  final VoidCallback? onPairDevice;
  final VoidCallback? onViewDevices;
  final VoidCallback? onManageWatch;
  final WatchConnectionState? watchConnectionState;

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
                label: watchConnectionState == WatchConnectionState.connected
                    ? 'Watch'
                    : 'Pair Watch',
                badgeColor: watchConnectionState == WatchConnectionState.connected
                    ? const Color(0xFF34C759)
                    : null,
                onTap: () {
                  if (watchConnectionState == WatchConnectionState.connected &&
                      onManageWatch != null) {
                    onManageWatch!();
                  } else if (onPairDevice != null) {
                    onPairDevice!();
                  } else {
                    onQuickAction('Pair a device');
                  }
                },
              ),
              _QuickActionItem(
                icon: Icons.devices,
                label: 'Devices',
                onTap: () {
                  if (onViewDevices != null) {
                    onViewDevices!();
                  } else {
                    onQuickAction('Show connected devices');
                  }
                },
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

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

class _QuickActionItem extends StatefulWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? badgeColor;

  @override
  State<_QuickActionItem> createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<_QuickActionItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTapDown: (_) {
        _scaleController.reverse();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        _scaleController.forward();
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () {
        _scaleController.forward();
        setState(() => _pressed = false);
      },
      child: ScaleTransition(
        scale: _scaleController,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.icon, size: 28, color: primary),
                  if (widget.badgeColor != null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active source banner ("Watch is talking")
// ---------------------------------------------------------------------------

class _ActiveSourceBanner extends StatelessWidget {
  const _ActiveSourceBanner({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: ClawfreeTheme.durationMedium,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          _PulsingDot(color: color),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Queued input banner
// ---------------------------------------------------------------------------

class _QueuedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white.withValues(alpha: 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue, size: 12, color: ClawfreeTheme.textTertiary),
          const SizedBox(width: 6),
          Text(
            'Your input is queued',
            style: TextStyle(
              fontSize: 11,
              color: ClawfreeTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing dot (reusable within this file)
// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.5 + 0.5 * _ctrl.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
