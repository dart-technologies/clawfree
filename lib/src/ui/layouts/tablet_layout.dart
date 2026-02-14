import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../../core/message_item.dart';
import '../../core/remote_session.dart';
import '../../voice/stt_service.dart';
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
    required this.sttService,
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
    this.activeSurfaceId,
    this.remoteSessions = const [],
  });

  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final ScrollController scrollController;
  final TextEditingController textController;
  final SttService? sttService;
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
              Container(
                width: 220,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                ),
              ),
            ],
          ),
        ),
        // -- Bottom: Global command input + permissions --
        _BottomBar(
          textController: textController,
          sttService: sttService,
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
          const Text(
            'Vitals',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          Expanded(child: HealthPillBar(state: healthState)),
          const SizedBox(width: 12),
          // Remote session indicators
          for (final session in remoteSessions) ...[
            RemoteSessionIndicator(
              icon: iconForDeviceType(session.deviceType),
              label: session.deviceName,
            ),
            const SizedBox(width: 8),
          ],
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: updateAvailable
                  ? Colors.orange.withValues(alpha: 0.15)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: updateAvailable
                  ? Border.all(color: Colors.orange.withValues(alpha: 0.5))
                  : null,
            ),
            child: InkWell(
              onTap: updateAvailable ? onUpdate : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gatewayVersion,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  if (updateAvailable) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'NODES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ),
        _SidebarItem(
          icon: Icons.computer,
          label: activeNodeName,
          isActive: true,
          onTap: () {},
        ),
        const Divider(height: 16, indent: 16, endIndent: 16),
        // Agent library
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                'AGENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => onQuickAction('Create a new agent'),
                borderRadius: BorderRadius.circular(4),
                child: Icon(Icons.add, size: 18, color: cs.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: agentNames.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No agents yet.\nSay "Create an agent" to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: agentNames.length,
                  itemBuilder: (context, i) => _SidebarItem(
                    icon: Icons.smart_toy,
                    label: agentNames[i],
                    onTap: () => onSelectAgent(agentNames[i]),
                  ),
                ),
        ),
        // Quick actions at bottom of sidebar
        const Divider(height: 1),
        _SidebarItem(
          icon: Icons.settings,
          label: 'Manage OpenClaw',
          onTap: () => onQuickAction('Manage OpenClaw'),
        ),
        _SidebarItem(
          icon: Icons.qr_code,
          label: 'Pair Device',
          onTap: () => onQuickAction('Pair a device'),
        ),
        _SidebarItem(
          icon: Icons.extension,
          label: 'Skill Library',
          onTap: () => onQuickAction('Show skill library'),
        ),
        _SidebarItem(
          icon: Icons.analytics,
          label: 'Analytics',
          onTap: () => onQuickAction('Show analytics'),
        ),
        _SidebarItem(
          icon: Icons.security,
          label: 'Security',
          onTap: () => onQuickAction('Security overview'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SidebarItem extends StatefulWidget {
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
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: widget.isActive
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : _hovered
                  ? cs.onSurface.withValues(alpha: 0.05)
                  : null,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isActive ? cs.primary : cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: healthColor(HealthLevel.nominal),
                    shape: BoxShape.circle,
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
    this.activeSurfaceId,
  });

  final List<MessageItem> messages;
  final SurfaceHost surfaceHost;
  final ScrollController scrollController;
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final VoidCallback? onRetry;
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
    required this.textController,
    required this.sttService,
    required this.isProcessing,
    required this.healthState,
    required this.onSend,
  });

  final TextEditingController textController;
  final SttService? sttService;
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
          // Permissions tray (compact)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PermissionChip(
                  icon: Icons.mic,
                  label: 'EAR',
                  level: healthState.voice.level,
                ),
                const SizedBox(width: 6),
                _PermissionChip(
                  icon: Icons.location_on,
                  label: 'LOC',
                  level: HealthLevel.unknown,
                ),
                const SizedBox(width: 6),
                _PermissionChip(
                  icon: Icons.folder,
                  label: 'FILE',
                  level: HealthLevel.unknown,
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Command input
          Expanded(
            child: ChatInputBar(
              controller: textController,
              sttService: sttService,
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
