import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';

/// JSON Schema for the Gap A2UI component.
final gapSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Gap']),
    'size': S.string(
      enumValues: ['xs', 'sm', 'md', 'lg', 'xl', 'xxl', 'xxxl'],
      description: 'Named size. Overridden by explicit height/width.',
    ),
    'height': S.number(description: 'Vertical spacing in logical pixels.'),
    'width': S.number(description: 'Horizontal spacing in logical pixels.'),
    'showDivider': S.boolean(
      description: 'Whether to show a decorative technical divider.',
    ),
    'color': S.string(
      description: 'Hex color for the divider (e.g. "#FF6600").',
    ),
  },
  required: ['component'],
);

/// Maps named size tokens to [ClawfreeSpacing] constants.
double? _resolveNamedSize(String? name) {
  return switch (name) {
    'xs' => ClawfreeSpacing.xs,
    'sm' => ClawfreeSpacing.sm,
    'md' => ClawfreeSpacing.md,
    'lg' => ClawfreeSpacing.lg,
    'xl' => ClawfreeSpacing.xl,
    'xxl' => ClawfreeSpacing.xxl,
    'xxxl' => ClawfreeSpacing.xxxl,
    _ => null,
  };
}

/// Catalog-compatible builder for the Gap component.
Widget gapCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final namedSize = data['size'] as String?;
  final explicitHeight = (data['height'] as num?)?.toDouble();
  final explicitWidth = (data['width'] as num?)?.toDouble();
  final showDivider = data['showDivider'] as bool? ?? false;
  final colorHex = data['color'] as String?;

  // Explicit height/width override named size.
  final resolved = _resolveNamedSize(namedSize);
  final height = explicitHeight ?? resolved;
  final width = explicitWidth;

  Color? dividerColor;
  if (colorHex != null) {
    try {
      dividerColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {}
  }

  if (showDivider) {
    return Container(
      height: height ?? 1.0,
      width: width ?? double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:
            dividerColor ??
            Theme.of(itemContext.buildContext).colorScheme.outlineVariant,
        boxShadow: dividerColor != null
            ? ClawfreeTheme.technicalGlow(dividerColor, intensity: 0.5)
            : null,
      ),
    );
  }

  return SizedBox(height: height, width: width);
}
