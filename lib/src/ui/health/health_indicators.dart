import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../clawfree_icons.dart';
import '../theme.dart';
import 'health_sparkline.dart';
import 'health_state.dart';

// Re-export for convenience.
export 'health_state.dart';

/// Maps [HealthLevel] to a consistent color from ClawfreeTheme.
Color healthColor(HealthLevel level) => switch (level) {
  HealthLevel.nominal => ClawfreeTheme.success,
  HealthLevel.degraded => ClawfreeTheme.warning,
  HealthLevel.error => ClawfreeTheme.error,
  HealthLevel.unknown => ClawfreeTheme.neutral,
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
          const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {

  const _Dot({required this.section});

  final HealthSection section;



  IconData _iconForSection(String id) {
    return switch (id.toLowerCase()) {
      'link' || 'gateway' => ClawfreeIcons.hub,
      'think' || 'llm' => ClawfreeIcons.psychology,
      'reach' || 'channels' => ClawfreeIcons.sync,
      'ear' || 'voice' => ClawfreeIcons.mic,
      'skill' || 'tools' => ClawfreeIcons.skills,
      'security' => ClawfreeIcons.security,
      _ => Icons.circle,
    };
  }



  @override

  Widget build(BuildContext context) {

    final color = healthColor(section.level);

    return Tooltip(

      message: '${section.label}: ${section.level.name}'

          '${section.detail.isNotEmpty ? ' (${section.detail})' : ''}',

      child: Container(

        decoration: BoxDecoration(

          shape: BoxShape.circle,

          boxShadow: [

            if (section.level == HealthLevel.nominal)

              BoxShadow(

                color: color.withValues(alpha: 0.2),

                blurRadius: 4,

                spreadRadius: 1,

              ),

          ],

        ),

        child: Icon(

          _iconForSection(section.id),

          size: 14,

          color: color,

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
    final isNominal = section.level == HealthLevel.nominal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: ClawfreeBorderRadius.element,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlowDot(color: color, isActive: isNominal),
          const SizedBox(width: 8),
          Text(
            section.id.toUpperCase(),
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          if (section.detail.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              section.detail,
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(width: 8),
          HealthSparkline(level: section.level, width: 40, height: 14),
        ],
      ),
    );
  }
}

class _GlowDot extends StatefulWidget {
  const _GlowDot({required this.color, required this.isActive});
  final Color color;
  final bool isActive;

  @override
  State<_GlowDot> createState() => _GlowDotState();
}

class _GlowDotState extends State<_GlowDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    bool isTest = false;
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        isTest = true;
      }
    } catch (_) {}

    if (!isTest) {
      _controller.repeat(reverse: true);
    }
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
      builder: (context, child) {
        final glowSize = widget.isActive
            ? 4.0 + (_controller.value * 4.0)
            : 0.0;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              if (widget.isActive)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: glowSize,
                  spreadRadius: glowSize / 2,
                ),
            ],
          ),
        );
      },
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
