import 'package:flutter/material.dart';

import 'pulsing_dot.dart';

/// A small pill widget showing a remote device session (e.g. "Watch" or "iPhone")
/// with an icon, label, and pulsing connectivity dot.
class RemoteSessionIndicator extends StatelessWidget {
  const RemoteSessionIndicator({
    super.key,
    required this.icon,
    required this.label,
    this.dotSize = 6,
    this.color = Colors.blue,
    this.iconSize = 12,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  final IconData icon;
  final String label;
  final double dotSize;
  final Color color;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: fontSize, color: color),
          ),
          const SizedBox(width: 4),
          PulsingDot(color: color, size: dotSize),
        ],
      ),
    );
  }
}
