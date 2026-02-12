import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'health_sparkline.dart';
import 'health_state.dart';

/// Catalog-compatible builder that bridges [CatalogItemContext] to [HealthSparkline].
Widget healthSparklineCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final levelStr = data['level'] as String? ?? 'unknown';
  final level = HealthLevel.values.firstWhere(
    (l) => l.name == levelStr,
    orElse: () => HealthLevel.unknown,
  );
  final rawPoints = data['dataPoints'] as List?;
  final points =
      rawPoints?.whereType<num>().map((n) => n.toDouble()).toList();
  final width = (data['width'] as num?)?.toDouble() ?? 60;
  final height = (data['height'] as num?)?.toDouble() ?? 20;
  return HealthSparkline(
    level: level,
    dataPoints: points,
    width: width,
    height: height,
  );
}

/// JSON Schema for the HealthSparkline A2UI component.
final healthSparklineSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['HealthSparkline']),
    'level': S.string(
      enumValues: ['nominal', 'degraded', 'error', 'unknown'],
      description: 'Health level determining color and demo data pattern.',
    ),
    'dataPoints': S.list(
      items: S.number(),
      description: 'Optional 0.0-1.0 values.',
    ),
    'width': S.number(description: 'Width in logical pixels (default 60).'),
    'height': S.number(description: 'Height in logical pixels (default 20).'),
  },
  required: ['component', 'level'],
);
