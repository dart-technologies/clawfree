import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../spring_curve.dart';
import '../theme.dart';
import 'icon_resolver.dart';

/// JSON Schema for the ProgressBar A2UI component.
final progressBarSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ProgressBar']),
    'value': S.number(description: 'Progress value from 0.0 to 1.0.'),
    'label': S.string(description: 'Optional label above the bar.'),
    'color': S.string(description: 'Hex color for the fill (e.g. "#0066CC").'),
    'height': S.number(description: 'Bar height in logical pixels. Defaults to 6.'),
    'showPercentage': S.boolean(
      description: 'Whether to show percentage text. Defaults to false.',
    ),
  },
  required: ['component', 'value'],
);

/// Catalog builder for the ProgressBar component.
Widget progressBarCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final value = (data['value'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
  final label = data['label'] as String?;
  final colorHex = data['color'] as String?;
  final height = (data['height'] as num?)?.toDouble() ?? 6.0;
  final showPercentage = data['showPercentage'] as bool? ?? false;

  return _ProgressBarWidget(
    value: value,
    label: label,
    color: parseHexColor(colorHex),
    height: height,
    showPercentage: showPercentage,
  );
}

class _ProgressBarWidget extends StatelessWidget {
  const _ProgressBarWidget({
    required this.value,
    this.label,
    this.color,
    this.height = 6.0,
    this.showPercentage = false,
  });

  final double value;
  final String? label;
  final Color? color;
  final double height;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fillColor = color ?? cs.primary;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  if (showPercentage)
                    Text(
                      '${(value * 100).round()}%',
                      style: ClawfreeTheme.technicalStyle(
                        context: context,
                        fontSize: 10,
                        color: fillColor,
                      ),
                    ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Track
                  Container(
                    height: height,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: ClawfreeBorderRadius.tiny,
                    ),
                  ),
                  // Fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: const SpringCurve(),
                    height: height,
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: ClawfreeBorderRadius.tiny,
                      boxShadow: ClawfreeTheme.technicalGlow(
                        fillColor,
                        intensity: 0.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
