import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// A genUI component that adapts its layout based on available width.
///
/// Width > 600: children in a 2-column grid (Wrap).
/// Width <= 600: children stacked vertically (Column).
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.itemContext,
  });

  final CatalogItemContext itemContext;

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, Object?>;
    final childrenRaw = data['children'];
    final spacing = (data['spacing'] as num?)?.toDouble() ?? 16.0;

    // Extract child IDs from the children array.
    final childIds = <String>[];
    if (childrenRaw is List) {
      for (final item in childrenRaw) {
        if (item is String) childIds.add(item);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = childIds
            .map((id) => itemContext.buildChild(id, itemContext.dataContext))
            .toList();

        if (constraints.maxWidth > 600) {
          // Tablet/Desktop: 2-column grid
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children.map((child) {
              return SizedBox(
                width: (constraints.maxWidth - spacing) / 2 - 1,
                child: child,
              );
            }).toList(),
          );
        } else {
          // Mobile: vertical stack
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((child) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: child,
              );
            }).toList(),
          );
        }
      },
    );
  }
}
