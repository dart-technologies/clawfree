import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../core/message_item.dart';
import '../../core/remote_session.dart';
import '../../voice/voice_controller.dart';
import '../clawfree_icons.dart';
import '../theme.dart';
import '../chat/chat_input_bar.dart';
import '../chat/chat_message_list.dart';
import '../chat/chat_surface_panel.dart';
import '../health/health_indicators.dart';
import '../widgets/remote_session_indicator.dart';

/// iPad / macOS "Control Tower" layout.
///
/// Left sidebar: OpenClaw nodes + agent library.
/// Top header: system telemetry pills + version badge.
/// Main content: left 60% live surface grid, right 40% chat + logs.
/// Bottom bar: global command input + permissions tray.
class TabletLayout extends StatelessWidget {
  const TabletLayout({
    super.key,
    required this.messages,
    required this.surfaceHost,
    required this.scrollController,
    required this.textController,
    required this.voiceController,
    required this.isProcessing,
    required this.healthState,
    required this.agentNames,
    required this.activeNodeName,
    required this.gatewayVersion,
    required this.updateAvailable,
    required this.onSend,
    required this.onRetry,
    required this.onSelectAgent,
    required this.onQuickAction,
    this.inputKey,
    this.inputFocusNode,
    this.activeSurfaceId,
    this.remoteSessions = const [],
  });

  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final ScrollController scrollController;
  final TextEditingController textController;
  final VoiceController? voiceController;
  final bool isProcessing;
  final HealthState healthState;
  final List<String> agentNames;
  final String activeNodeName;
  final String gatewayVersion;
  final bool updateAvailable;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;
  final ValueChanged<String> onSelectAgent;
  final ValueChanged<String> onQuickAction;
  final Key? inputKey;
  final FocusNode? inputFocusNode;
  final String? activeSurfaceId;
  final List<RemoteSession> remoteSessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // -- Top: System Telemetry header --
        _TelemetryHeader(
          healthState: healthState,
          gatewayVersion: gatewayVersion,
          updateAvailable: updateAvailable,
          remoteSessions: remoteSessions,
          onUpdate: () => onQuickAction('Update OpenClaw'),
        ),
        // -- Main body: sidebar + content --
        Expanded(
          child: Row(
            children: [
              // Left sidebar
              SizedBox(
                width: 240,
                child: _Sidebar(
                  activeNodeName: activeNodeName,
                  agentNames: agentNames,
                  onSelectAgent: onSelectAgent,
                  onQuickAction: onQuickAction,
                ),
              ),
              const VerticalDivider(width: 1),
              // Main content: split view
              Expanded(
                child: _SplitContent(
                  messages: messages,
                  surfaceHost: surfaceHost,
                  scrollController: scrollController,
                  isProcessing: isProcessing,
                  onSend: onSend,
                  onRetry: onRetry,
                  activeSurfaceId: activeSurfaceId,
                  agentNames: agentNames,
                ),
              ),
            ],
          ),
        ),
        // -- Bottom: Global command input + permissions --
        _BottomBar(
          inputKey: inputKey,
          inputFocusNode: inputFocusNode,
          textController: textController,
          voiceController: voiceController,
          isProcessing: isProcessing,
          healthState: healthState,
          onSend: onSend,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top: Telemetry header
// ---------------------------------------------------------------------------

class _TelemetryHeader extends StatelessWidget {
  const _TelemetryHeader({
    required this.healthState,
    required this.gatewayVersion,
    required this.updateAvailable,
    required this.onUpdate,
    this.remoteSessions = const [],
  });

  final HealthState healthState;
  final String gatewayVersion;
  final bool updateAvailable;
  final VoidCallback onUpdate;
  final List<RemoteSession> remoteSessions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 8, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // --- Left Group: Vitals ---
          Text(
            'VITALS',
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: HealthPillBar(state: healthState),
          ),

          // --- Right Group: Sessions + Version ---
          const SizedBox(width: 32),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final session in remoteSessions) ...[
                    RemoteSessionIndicator(
                      icon: ClawfreeIcons.iconForDeviceType(session.deviceType),
                      label: session.deviceName,
                    ),
                    const SizedBox(width: 10),
                  ],
                  _VersionBadge(
                    gatewayVersion: gatewayVersion,
                    updateAvailable: updateAvailable,
                    onUpdate: onUpdate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({
    required this.gatewayVersion,
    required this.updateAvailable,
    required this.onUpdate,
  });

  final String gatewayVersion;
  final bool updateAvailable;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: updateAvailable
            ? ClawfreeTheme.warning.withValues(alpha: 0.1)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: ClawfreeBorderRadius.element,
        border: Border.all(
          color: updateAvailable
              ? ClawfreeTheme.warning.withValues(alpha: 0.3)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: updateAvailable ? onUpdate : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\ud83e\udd9e ${gatewayVersion.toUpperCase()}',
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 9,
              ),
            ),
            if (updateAvailable) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: ClawfreeTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left sidebar: Nodes + Agent library
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.activeNodeName,
    required this.agentNames,
    required this.onSelectAgent,
    required this.onQuickAction,
  });

  final String activeNodeName;
  final List<String> agentNames;
  final ValueChanged<String> onSelectAgent;
  final ValueChanged<String> onQuickAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Node section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                    child: Text(
                      'NODES',
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _SidebarItem(
                    icon: Symbols.hub,
                    label: activeNodeName,
                    isActive: true,
                    onTap: () {},
                  ),
                  const Divider(height: 24, indent: 20, endIndent: 20),
                  // Agent library
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'AGENTS',
                          style: ClawfreeTheme.technicalStyle(
                            context: context,
                            fontSize: 10,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => onQuickAction('Create a new agent'),
                          borderRadius: ClawfreeBorderRadius.tiny,
                          child: Icon(ClawfreeIcons.add, size: 18, color: cs.primary),
                        ),
                      ],
                    ),
                  ),
                  if (agentNames.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No agents yet.\nSay "Create an agent" to start.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (final name in agentNames)
                      _SidebarItem(
                        icon: ClawfreeIcons.agent,
                        label: name,
                        onTap: () => onSelectAgent(name),
                      ),

                  // Blank space to push quick actions to bottom
                  const Spacer(),

                  const Divider(height: 1),
                  // Quick actions
                  _SidebarItem(
                    icon: ClawfreeIcons.settings,
                    label: 'MANAGE OPENCLAW',
                    onTap: () => onQuickAction('Manage OpenClaw'),
                  ),
                  _SidebarItem(
                    icon: ClawfreeIcons.qrCode,
                    label: 'PAIR DEVICE',
                    onTap: () => onQuickAction('Pair a device'),
                  ),
                  _SidebarItem(
                    icon: ClawfreeIcons.skills,
                    label: 'SKILL LIBRARY',
                    onTap: () => onQuickAction('Show skill library'),
                  ),
                  _SidebarItem(
                    icon: ClawfreeIcons.analytics,
                    label: 'ANALYTICS',
                    onTap: () => onQuickAction('Show analytics'),
                  ),
                  _SidebarItem(
                    icon: ClawfreeIcons.security,
                    label: 'SECURITY',
                    onTap: () => onQuickAction('Security overview'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: ClawfreeBorderRadius.small,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive 
                ? cs.primary.withValues(alpha: 0.1) 
                : Colors.transparent,
            borderRadius: ClawfreeBorderRadius.small,
            border: Border.all(
              color: isActive 
                  ? cs.primary.withValues(alpha: 0.3) 
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                    color: isActive ? cs.primary : cs.onSurface,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      ClawfreeTheme.technicalGlow(cs.primary, intensity: 0.5)[0],
                    ],
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
// Main content: 60/40 split
// ---------------------------------------------------------------------------

class _SplitContent extends StatelessWidget {
  const _SplitContent({
    required this.messages,
    required this.surfaceHost,
    required this.scrollController,
    required this.isProcessing,
    required this.onSend,
    required this.onRetry,
    required this.agentNames,
    this.activeSurfaceId,
  });

  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final ScrollController scrollController;
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;
  final List<String> agentNames;
  final String? activeSurfaceId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left 60%: Live surface canvas
        Expanded(
          flex: 6,
          child: ChatSurfacePanel(
            surfaceMessages: messages.where((m) => m.isSurface).toList(),
            surfaceHost: surfaceHost,
            activeSurfaceId: activeSurfaceId,
            borderRadius: 0,
          ),
        ),
        const VerticalDivider(width: 1),
        // Right 40%: Chat & logs
        Expanded(
          flex: 4,
          child: ChatMessageList(
            messages: messages,
            scrollController: scrollController,
            surfaceHost: surfaceHost,
            maxBubbleWidth: 300,
            isDesktop: true,
            isProcessing: isProcessing,
            onSend: onSend,
            onRetry: onRetry,
            agentNames: agentNames,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom: Global command input + permissions tray
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    this.inputKey,
    this.inputFocusNode,
    required this.textController,
    required this.voiceController,
    required this.isProcessing,
    required this.healthState,
    required this.onSend,
  });

  final Key? inputKey;
  final FocusNode? inputFocusNode;
  final TextEditingController textController;
  final VoiceController? voiceController;
  final bool isProcessing;
  final HealthState healthState;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Permissions tray (System Tray Pill)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ClawfreeTheme.glassDecoration(
                context,
                borderRadius: 16,
                elevation: 1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PermissionChip(
                    icon: Symbols.mic,
                    label: 'MIC',
                    level: healthState.voice.level,
                  ),
                  const SizedBox(width: 12),
                  _PermissionChip(
                    icon: Symbols.location_on,
                    label: 'GPS',
                    level: HealthLevel.unknown,
                  ),
                  const SizedBox(width: 12),
                  _PermissionChip(
                    icon: Symbols.database,
                    label: 'DISK',
                    level: HealthLevel.unknown,
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Command input
          Expanded(
            child: ChatInputBar(
              key: inputKey,
              focusNode: inputFocusNode,
              textController: textController,
              voiceController: voiceController,
              isProcessing: isProcessing,
              onSend: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({
    required this.icon,
    required this.label,
    required this.level,
  });

  final IconData icon;
  final String label;
  final HealthLevel level;

  @override
  Widget build(BuildContext context) {
    final color = healthColor(level);
    return Tooltip(
      message: '$label: ${level.name}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
