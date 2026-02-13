import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/watch_bridge.dart';
import '../../devices/device_registry.dart';
import '../theme.dart';

/// Bottom sheet panel for managing Apple Watch connection and status.
class WatchManagementPanel extends StatelessWidget {
  const WatchManagementPanel({super.key, required this.registry});

  final DeviceRegistry registry;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: registry,
      builder: (context, _) {
        final ws = registry.watchState;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: ClawfreeTheme.darkSurface.withValues(alpha: 0.92),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConnectionHeader(ws),
                  const SizedBox(height: 16),
                  _ActivityRow(ws),
                  const SizedBox(height: 12),
                  _LastSyncRow(ws.lastSyncTime),
                  if (WatchBridge.isRelayMode) ...[
                    const SizedBox(height: 4),
                    _RelayModeLabel(),
                  ],
                  const SizedBox(height: 16),
                  _RelayToggle(
                    enabled: ws.relayEnabled,
                    onChanged: registry.toggleWatchRelay,
                  ),
                  const SizedBox(height: 12),
                  _PingButton(registry: registry),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Connection header
// ---------------------------------------------------------------------------

class _ConnectionHeader extends StatelessWidget {
  const _ConnectionHeader(this.ws);
  final WatchState ws;

  @override
  Widget build(BuildContext context) {
    final color = _colorForConnection(ws.connectionState);
    final label = switch (ws.connectionState) {
      WatchConnectionState.connected => 'Connected',
      WatchConnectionState.disconnected => 'Disconnected',
      WatchConnectionState.searching => 'Searching...',
    };

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.watch, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apple Watch',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  _PulsingDot(color: color, size: 7),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity row
// ---------------------------------------------------------------------------

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.ws);
  final WatchState ws;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (ws.activityStatus) {
      WatchActivityStatus.idle => (
          Icons.circle_outlined,
          'Idle',
          ClawfreeTheme.textTertiary,
        ),
      WatchActivityStatus.listening => (
          Icons.mic,
          'Listening',
          ClawfreeTheme.teal,
        ),
      WatchActivityStatus.speaking => (
          Icons.volume_up,
          'Speaking',
          ClawfreeTheme.lobsterOrange,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ClawfreeTheme.glassmorphism(
        color: color,
        opacity: 0.06,
        borderRadius: 10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            'Activity: $label',
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Last sync row
// ---------------------------------------------------------------------------

class _LastSyncRow extends StatelessWidget {
  const _LastSyncRow(this.lastSync);
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final text = lastSync != null ? _formatRelative(lastSync!) : 'Never';
    return Row(
      children: [
        Icon(Icons.sync, size: 14, color: ClawfreeTheme.textTertiary),
        const SizedBox(width: 8),
        Text(
          'Last sync: $text',
          style: TextStyle(fontSize: 12, color: ClawfreeTheme.textTertiary),
        ),
      ],
    );
  }

  static String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ---------------------------------------------------------------------------
// Relay mode label
// ---------------------------------------------------------------------------

class _RelayModeLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.router, size: 14, color: ClawfreeTheme.textTertiary),
        const SizedBox(width: 8),
        Text(
          'Connected via gateway relay',
          style: TextStyle(fontSize: 12, color: ClawfreeTheme.textTertiary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Relay toggle
// ---------------------------------------------------------------------------

class _RelayToggle extends StatelessWidget {
  const _RelayToggle({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: ClawfreeTheme.glassmorphism(
        opacity: 0.04,
        borderRadius: 10,
      ),
      child: Row(
        children: [
          Icon(Icons.broadcast_on_personal,
              size: 16, color: ClawfreeTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Broadcast to relay',
              style:
                  TextStyle(fontSize: 13, color: ClawfreeTheme.textSecondary),
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: enabled,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ping button
// ---------------------------------------------------------------------------

class _PingButton extends StatefulWidget {
  const _PingButton({required this.registry});
  final DeviceRegistry registry;

  @override
  State<_PingButton> createState() => _PingButtonState();
}

class _PingButtonState extends State<_PingButton> {
  bool _pinging = false;
  bool? _lastResult;

  Future<void> _ping() async {
    setState(() {
      _pinging = true;
      _lastResult = null;
    });
    HapticFeedback.lightImpact();
    final ok = await widget.registry.pingWatch();
    if (!mounted) return;
    setState(() {
      _pinging = false;
      _lastResult = ok;
    });
    // Clear result after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _lastResult = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _pinging ? null : _ping,
        icon: _pinging
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : _lastResult == null
                ? const Icon(Icons.radar, size: 18)
                : _lastResult!
                    ? const Icon(Icons.check_circle, size: 18)
                    : const Icon(Icons.cancel, size: 18),
        label: Text(_pinging
            ? 'Pinging...'
            : _lastResult == null
                ? 'Ping Watch'
                : _lastResult!
                    ? 'Reachable'
                    : 'Not Reachable'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing dot indicator
// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.6 + 0.4 * _controller.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _colorForConnection(WatchConnectionState state) {
  return switch (state) {
    WatchConnectionState.connected => const Color(0xFF34C759),
    WatchConnectionState.searching => const Color(0xFFFF9F0A),
    WatchConnectionState.disconnected => const Color(0xFFFF3B30),
  };
}
