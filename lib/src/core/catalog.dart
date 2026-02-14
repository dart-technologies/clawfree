import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../ui/chat/animated_component.dart';
import '../ui/chat/badge_component.dart';
import '../ui/chat/button_component.dart';
import '../ui/chat/card_component.dart';
import '../ui/chat/chip_component.dart';
import '../ui/chat/choice_picker_override.dart';
import '../ui/chat/gap_component.dart';
import '../ui/chat/grid_component.dart';
import '../ui/chat/progress_bar_component.dart';
import '../ui/chat/responsive_container.dart';
import '../ui/chat/stack_component.dart';
import '../ui/chat/text_component.dart';
import '../ui/chat/trip_map_component.dart';
import '../ui/chat/video_player_component.dart';
import '../ui/clawfree_assets.dart';
import '../ui/health/health_sparkline_catalog.dart';

/// Schema for the ResponsiveContainer custom component.
final _responsiveContainerSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ResponsiveContainer']),
    'spacing': S.number(description: 'Gap between children in logical pixels.'),
    'columns': S.integer(
      description: 'Number of columns on tablet/desktop. Defaults to 2.',
    ),
    'mobileColumns': S.integer(
      description: 'Number of columns on mobile. Defaults to 1.',
    ),
    'skeleton': S.string(
      enumValues: ['text', 'form', 'table', 'card'],
      description:
          'Show a specific skeleton type if children are not yet available.',
    ),
    'children': A2uiSchemas.componentArrayReference(
      description: 'Child component IDs to lay out responsively.',
    ),
  },
  required: ['component', 'children'],
);

/// Schema for the BrandLogo custom component.
final _brandLogoSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['BrandLogo']),
    'size': S.number(description: 'Size of the logo in logical pixels.'),
  },
  required: ['component'],
);

/// Returns the default widget catalog for clawfree.
///
/// Extends genUI core widgets with custom and overridden components.
/// Core overrides (Card, Button, Text, ChoicePicker) replace the genUI
/// defaults by using the same name in copyWith.
Catalog getClawfreeCatalog() {
  return CoreCatalogItems.asCatalog().copyWith([
    // --- Custom components ---
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
    CatalogItem(
      name: 'VideoPlayer',
      dataSchema: videoPlayerSchema,
      widgetBuilder: videoPlayerCatalogBuilder,
    ),
    CatalogItem(
      name: 'TripMap',
      dataSchema: tripMapSchema,
      widgetBuilder: tripMapCatalogBuilder,
    ),
    CatalogItem(
      name: 'Gap',
      dataSchema: gapSchema,
      widgetBuilder: gapCatalogBuilder,
    ),
    CatalogItem(
      name: 'BrandLogo',
      dataSchema: _brandLogoSchema,
      widgetBuilder: (itemContext) {
        final data = itemContext.data as Map<String, dynamic>;
        return ClawfreeLogo(size: data['size']?.toDouble() ?? 64.0);
      },
    ),
    CatalogItem(
      name: 'Badge',
      dataSchema: badgeSchema,
      widgetBuilder: badgeCatalogBuilder,
    ),
    CatalogItem(
      name: 'ProgressBar',
      dataSchema: progressBarSchema,
      widgetBuilder: progressBarCatalogBuilder,
    ),
    CatalogItem(
      name: 'Chip',
      dataSchema: chipSchema,
      widgetBuilder: chipCatalogBuilder,
    ),
    CatalogItem(
      name: 'Grid',
      dataSchema: gridSchema,
      widgetBuilder: gridCatalogBuilder,
    ),
    CatalogItem(
      name: 'Stack',
      dataSchema: stackSchema,
      widgetBuilder: stackCatalogBuilder,
    ),
    CatalogItem(
      name: 'Animated',
      dataSchema: animatedSchema,
      widgetBuilder: animatedCatalogBuilder,
    ),

    // --- Core overrides (same name replaces genUI defaults) ---
    CatalogItem(
      name: 'Card',
      dataSchema: cardOverrideSchema,
      widgetBuilder: cardOverrideCatalogBuilder,
    ),
    CatalogItem(
      name: 'Button',
      dataSchema: buttonOverrideSchema,
      widgetBuilder: buttonOverrideCatalogBuilder,
    ),
    CatalogItem(
      name: 'Text',
      dataSchema: textOverrideSchema,
      widgetBuilder: textOverrideCatalogBuilder,
    ),
    CatalogItem(
      name: 'ChoicePicker',
      dataSchema: choicePickerOverrideSchema,
      widgetBuilder: choicePickerOverrideCatalogBuilder,
    ),
  ]);
}
