import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';

/// JSON Schema for the Card A2UI component override.
final cardOverrideSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Card']),
    'child': A2uiSchemas.componentReference(
      description: 'Child component to render inside the card.',
    ),
    'variant': S.string(
      enumValues: ['glass', 'flat', 'outlined', 'elevated'],
      description: 'Card visual variant. Defaults to glass.',
    ),
    'padding': S.number(
      description: 'Inner padding in logical pixels. Defaults to 16.',
    ),
  },
  required: ['component', 'child'],
);

/// Catalog builder for the clawfree Card override.
Widget cardOverrideCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;

  // Resolve child ID — may be a string or a map with a path.
  final childRef = data['child'];
  final childId = childRef is String ? childRef : null;
  final variant = data['variant'] as String? ?? 'glass';
  final padding = (data['padding'] as num?)?.toDouble() ?? 16.0;

  if (childId == null) return const SizedBox.shrink();

  final child = Padding(
    padding: EdgeInsets.all(padding),
    child: itemContext.buildChild(childId),
  );

  final context = itemContext.buildContext;

  return switch (variant) {
    'glass' => Container(
      decoration: ClawfreeTheme.glassDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
    'flat' => Container(
      decoration: ClawfreeTheme.minimalSurface(context),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
    'outlined' => Container(
      decoration: BoxDecoration(
        borderRadius: ClawfreeBorderRadius.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
    'elevated' => Card(
      child: child,
    ),
    _ => Container(
      decoration: ClawfreeTheme.glassDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  };
}
