import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'health_indicators.dart';

/// Tiny sparkline chart for health indicators.
///
/// Renders a 60x20 line chart colored by [HealthLevel].
/// If no [dataPoints] are provided, generates demo data per level.
class HealthSparkline extends StatelessWidget {
  const HealthSparkline({
    super.key,
    required this.level,
    this.dataPoints,
    this.width = 60,
    this.height = 20,
  });

  final HealthLevel level;
  final List<double>? dataPoints;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final data = dataPoints ?? _demoData(level);
    final color = healthColor(level);

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i]),
    ];

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          minY: 0,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  /// Generate demo sparkline data for a given health level.
  static List<double> _demoData(HealthLevel level) {
    final rng = math.Random(level.index);
    const count = 12;

    return switch (level) {
      HealthLevel.nominal => List.generate(count, (i) => 0.75 + rng.nextDouble() * 0.2),
      HealthLevel.degraded => List.generate(count, (i) => 0.35 + rng.nextDouble() * 0.3),
      HealthLevel.error => List.generate(count, (i) => 0.05 + rng.nextDouble() * 0.2),
      HealthLevel.unknown => List.generate(count, (_) => 0.5),
    };
  }
}
