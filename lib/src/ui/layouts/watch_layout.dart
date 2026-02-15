import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/message_item.dart';
import '../clawfree_icons.dart';
import '../theme.dart';
import '../health/health_indicators.dart';

/// Apple Watch "Pulse Monitor" layout.
///
/// Main screen: center heartbeat ring (green/amber/red), top agent count,
/// center tap for full-screen STT.
/// Vertical scroll: critical alert approval cards.
class WatchLayout extends StatelessWidget {
  const WatchLayout({
    super.key,
    required this.healthLevel,
    required this.activeAgentCount,
    required this.pendingApprovals,
    required this.agentNames,
    required this.onStartSpeaking,
    required this.onApprove,
    required this.onDeny,
    required this.onPingAgent,
  });

  final HealthLevel healthLevel;
  final int activeAgentCount;
  final List<MessageItem> pendingApprovals;
  final List<String> agentNames;
  final VoidCallback onStartSpeaking;
  final ValueChanged<int> onApprove;
  final ValueChanged<int> onDeny;
  final ValueChanged<String> onPingAgent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main screen: heartbeat ring
        Expanded(
          flex: 3,
          child: _HeartbeatScreen(
            healthLevel: healthLevel,
            activeAgentCount: activeAgentCount,
            onTap: onStartSpeaking,
          ),
        ),
        // Scroll area: alerts + agent list
        Expanded(
          flex: 2,
          child: _AlertsList(
            pendingApprovals: pendingApprovals,
            agentNames: agentNames,
            onApprove: onApprove,
            onDeny: onDeny,
            onPingAgent: onPingAgent,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Heartbeat screen
// ---------------------------------------------------------------------------

enum _WatchVoiceState { idle, listening, processing }

class _HeartbeatScreen extends StatefulWidget {
  const _HeartbeatScreen({
    required this.healthLevel,
    required this.activeAgentCount,
    required this.onTap,
  });

  final HealthLevel healthLevel;
  final int activeAgentCount;
  final VoidCallback onTap;

  @override
  State<_HeartbeatScreen> createState() => _HeartbeatScreenState();
}

class _HeartbeatScreenState extends State<_HeartbeatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  _WatchVoiceState _voiceState = _WatchVoiceState.idle;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Heartbeat curve: quick expansion (0→0.3) then slow decay (0.3→1.0).
  double _heartbeatCurve(double t) {
    if (t < 0.3) {
      // Quick rise
      return Curves.easeOut.transform(t / 0.3);
    } else {
      // Slow decay
      return 1.0 - Curves.easeInCubic.transform((t - 0.3) / 0.7);
    }
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _voiceState = switch (_voiceState) {
        _WatchVoiceState.idle => _WatchVoiceState.listening,
        _WatchVoiceState.listening => _WatchVoiceState.processing,
        _WatchVoiceState.processing => _WatchVoiceState.idle,
      };
      // Adjust pulse speed
      _pulseController.duration = switch (_voiceState) {
        _WatchVoiceState.idle => const Duration(milliseconds: 1200),
        _WatchVoiceState.listening => const Duration(milliseconds: 600),
        _WatchVoiceState.processing => const Duration(milliseconds: 1200),
      };
      _pulseController.repeat();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (_voiceState) {
      _WatchVoiceState.listening => 'Listening...',
      _WatchVoiceState.processing => 'Thinking...',
      _WatchVoiceState.idle => switch (widget.healthLevel) {
        HealthLevel.nominal => 'Tap to Speak',
        HealthLevel.degraded => 'Gateway Disconnected',
        HealthLevel.error => 'API Error',
        HealthLevel.unknown => 'Connecting\u2026',
      },
    };

    final isListening = _voiceState == _WatchVoiceState.listening;
    final ringColor = isListening
        ? Theme.of(context).colorScheme.primary
        : healthColor(widget.healthLevel);

    return GestureDetector(
      onTap: _handleTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top complication: agent count
            Text(
              '${widget.activeAgentCount} Agent${widget.activeAgentCount == 1 ? '' : 's'} Active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Pulsing heartbeat ring with mic icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _voiceState == _WatchVoiceState.processing
                    ? 0.5 // Steady glow
                    : _heartbeatCurve(_pulseController.value);
                final micScale = isListening ? 1.0 + 0.1 * pulse : 1.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 100 + 16 * pulse,
                      height: 100 + 16 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ringColor.withValues(
                            alpha: 0.2 * (1.0 - pulse),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    // Main health ring
                    HealthRing(
                      level: widget.healthLevel,
                      size: 100,
                      strokeWidth: 6 + 2 * pulse,
                      child: Transform.scale(
                        scale: micScale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(ClawfreeIcons.mic, size: 32, color: ringColor),
                            const SizedBox(height: 2),
                            Text(
                              isListening ? 'LISTENING' : 'SPEAK',
                              style: ClawfreeTheme.technicalStyle(
                                context: context,
                                fontSize: 9,
                                color: ringColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(statusLabel, style: TextStyle(fontSize: 11, color: ringColor)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alerts + agent list (scrollable)
// ---------------------------------------------------------------------------

class _AlertsList extends StatelessWidget {
  const _AlertsList({
    required this.pendingApprovals,
    required this.agentNames,
    required this.onApprove,
    required this.onDeny,
    required this.onPingAgent,
  });

  final List<MessageItem> pendingApprovals;
  final List<String> agentNames;
  final ValueChanged<int> onApprove;
  final ValueChanged<int> onDeny;
  final ValueChanged<String> onPingAgent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        if (pendingApprovals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              'REQUIRES APPROVAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.error,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (var i = 0; i < pendingApprovals.length; i++)
            _ApprovalCard(
              message: pendingApprovals[i].text ?? 'Action requires approval',
              onApprove: () => onApprove(i),
              onDeny: () => onDeny(i),
            ),
        ],
        if (agentNames.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
            child: Text(
              'AGENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final name in agentNames)
            _AgentTile(name: name, onPing: () => onPingAgent(name)),
        ],
        if (pendingApprovals.isEmpty && agentNames.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No alerts',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.message,
    required this.onApprove,
    required this.onDeny,
  });

  final String message;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDeny,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Deny', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Allow', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentTile extends StatelessWidget {
  const _AgentTile({required this.name, required this.onPing});

  final String name;
  final VoidCallback onPing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPing,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              ClawfreeIcons.agent,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Ping',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
