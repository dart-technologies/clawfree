import 'package:flutter/material.dart';

import '../health/health_sparkline.dart';
import '../health/health_state.dart';
import '../theme.dart';
import 'pulsing_dot.dart';

/// A small pill widget showing a remote device session (e.g. "Watch" or "iPhone")
/// with an icon, label, pulsing connectivity dot, and optional inline sparkline.
class RemoteSessionIndicator extends StatelessWidget {
  const RemoteSessionIndicator({
    super.key,
    required this.icon,
    required this.label,
    this.dotSize = 6,
    this.color = Colors.blue,
    this.iconSize = 14,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.showSparkline = false,
  });

  final IconData icon;
  final String label;
  final double dotSize;
  final Color color;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;
  final bool showSparkline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: ClawfreeBorderRadius.element,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: fontSize,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          if (showSparkline) ...[
            const SizedBox(width: 6),
            HealthSparkline(
              level: HealthLevel.nominal,
              width: 40,
              height: 12,
              showGlow: false,
              animate: true,
            ),
          ],
          const SizedBox(width: 6),
          PulsingDot(color: color, size: dotSize),
        ],
      ),
    );
  }
}
