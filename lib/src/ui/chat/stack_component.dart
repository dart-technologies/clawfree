import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';

/// JSON Schema for the Stack A2UI component.
final stackSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Stack']),
    'alignment': S.string(
      enumValues: [
        'topLeft', 'topCenter', 'topRight',
        'centerLeft', 'center', 'centerRight',
        'bottomLeft', 'bottomCenter', 'bottomRight',
      ],
      description: 'Stack alignment. Defaults to topLeft.',
    ),
    'children': A2uiSchemas.componentArrayReference(
      description: 'Child component IDs to stack.',
    ),
  },
  required: ['component', 'children'],
);

/// Catalog builder for the Stack component.
Widget stackCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final alignmentStr = data['alignment'] as String? ?? 'topLeft';

  final childrenRef = data['children'];
  final childIds = <String>[];
  if (childrenRef is List) {
    for (final item in childrenRef) {
      if (item is String) childIds.add(item);
    }
  }

  if (childIds.isEmpty) return const SizedBox.shrink();

  final alignment = _parseAlignment(alignmentStr);

  return ClipRRect(
    borderRadius: ClawfreeBorderRadius.surface,
    child: Stack(
      alignment: alignment,
      children: childIds.map((id) => itemContext.buildChild(id)).toList(),
    ),
  );
}

Alignment _parseAlignment(String value) {
  return switch (value) {
    'topLeft' => Alignment.topLeft,
    'topCenter' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' => Alignment.centerLeft,
    'center' => Alignment.center,
    'centerRight' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => Alignment.topLeft,
  };
}
