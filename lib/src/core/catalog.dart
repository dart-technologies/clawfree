import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../ui/chat/responsive_container.dart';
import '../ui/health/health_sparkline_catalog.dart';

/// Schema for the ResponsiveContainer custom component.
final _responsiveContainerSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ResponsiveContainer']),
    'spacing': S.number(description: 'Gap between children in logical pixels.'),
    'children': A2uiSchemas.componentArrayReference(
      description: 'Child component IDs to lay out responsively.',
    ),
  },
  required: ['component', 'children'],
);

/// Returns the default widget catalog for clawfree.
///
/// Extends genUI core widgets (Text, Button, TextField, Card, ChoicePicker,
/// Image, etc.) with the custom ResponsiveContainer component.
Catalog getClawfreeCatalog() {
  return CoreCatalogItems.asCatalog().copyWith([
    CatalogItem(
      name: 'ResponsiveContainer',
      dataSchema: _responsiveContainerSchema,
      widgetBuilder: (itemContext) =>
          ResponsiveContainer(itemContext: itemContext),
    ),
    CatalogItem(
      name: 'HealthSparkline',
      dataSchema: healthSparklineSchema,
      widgetBuilder: healthSparklineCatalogBuilder,
    ),
  ]);
}
