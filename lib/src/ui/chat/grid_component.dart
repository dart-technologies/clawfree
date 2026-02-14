import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// JSON Schema for the Grid A2UI component.
final gridSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Grid']),
    'columns': S.integer(
      description: 'Number of columns. Defaults to 2.',
    ),
    'gap': S.number(
      description: 'Gap between items in logical pixels. Defaults to 12.',
    ),
    'children': A2uiSchemas.componentArrayReference(
      description: 'Child component IDs to lay out in a grid.',
    ),
  },
  required: ['component', 'children'],
);

/// Catalog builder for the Grid component.
Widget gridCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final columns = (data['columns'] as num?)?.toInt() ?? 2;
  final gap = (data['gap'] as num?)?.toDouble() ?? 12.0;

  // Resolve children IDs.
  final childrenRef = data['children'];
  final childIds = <String>[];
  if (childrenRef is List) {
    for (final item in childrenRef) {
      if (item is String) childIds.add(item);
    }
  }

  if (childIds.isEmpty) return const SizedBox.shrink();

  return _GridWidget(
    itemContext: itemContext,
    childIds: childIds,
    columns: columns,
    gap: gap,
  );
}

class _GridWidget extends StatelessWidget {
  const _GridWidget({
    required this.itemContext,
    required this.childIds,
    required this.columns,
    required this.gap,
  });

  final CatalogItemContext itemContext;
  final List<String> childIds;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard: if maxWidth is infinite, fall back to single column.
        final effectiveColumns =
            constraints.maxWidth.isInfinite ? 1 : columns.clamp(1, 12);
        final totalGap = gap * (effectiveColumns - 1);
        final itemWidth = (constraints.maxWidth - totalGap) / effectiveColumns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: childIds.map((id) {
            return SizedBox(
              width: itemWidth,
              child: itemContext.buildChild(id),
            );
          }).toList(),
        );
      },
    );
  }
}
