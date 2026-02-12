import 'package:flutter/material.dart';

import 'health_sparkline.dart';
import 'health_state.dart';

// Re-export for convenience.
export 'health_state.dart';

/// Maps [HealthLevel] to a consistent color.
Color healthColor(HealthLevel level) => switch (level) {
      HealthLevel.nominal => const Color(0xFF34C759),
      HealthLevel.degraded => const Color(0xFFFF9F0A),
      HealthLevel.error => const Color(0xFFFF3B30),
      HealthLevel.unknown => const Color(0xFF8E8E93),
    };

// ---------------------------------------------------------------------------
// Compact: three status dots (phone connectivity bar)
// ---------------------------------------------------------------------------

/// A row of small colored dots — one per health section.
class HealthDotBar extends StatelessWidget {
  const HealthDotBar({super.key, required this.state});

  final HealthState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in state.all) ...[
          _Dot(section: section),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.section});
  final HealthSection section;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${section.label}: ${section.level.name}'
          '${section.detail.isNotEmpty ? ' (${section.detail})' : ''}',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: healthColor(section.level),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded: labeled pills (tablet/desktop header)
// ---------------------------------------------------------------------------

/// Horizontal row of labeled health pills with detail text.
class HealthPillBar extends StatelessWidget {
  const HealthPillBar({super.key, required this.state});

  final HealthState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final section in state.all) ...[
            _Pill(section: section),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.section});
  final HealthSection section;

  @override
  Widget build(BuildContext context) {
    final color = healthColor(section.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            section.id,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          if (section.detail.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              section.detail,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(width: 6),
          HealthSparkline(level: section.level, width: 36, height: 14),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ring: heartbeat circle (watch)
// ---------------------------------------------------------------------------

/// Circular health ring — green/amber/red based on overall status.
class HealthRing extends StatelessWidget {
  const HealthRing({
    super.key,
    required this.level,
    this.size = 120,
    this.strokeWidth = 8,
    this.child,
  });

  final HealthLevel level;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = healthColor(level);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: _RingPainter(color: color, strokeWidth: strokeWidth),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawArc(rect, -1.57, 6.28, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      color != old.color || strokeWidth != old.strokeWidth;
}
