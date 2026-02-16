import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../ui/clawfree_icons.dart';
import '../ui/theme.dart';
import '../ui/chat/animated_component.dart';
import '../ui/chat/icon_resolver.dart';
import '../ui/chat/badge_component.dart';
import '../ui/chat/button_component.dart';
import '../ui/chat/card_component.dart';
import '../ui/chat/chip_component.dart';
import '../ui/chat/choice_picker_override.dart';
import '../ui/chat/flight_ticket_component.dart';
import '../ui/chat/hotel_card_component.dart';
import '../ui/chat/agent_card_component.dart';
import '../ui/chat/booking_summary_component.dart';
import '../ui/chat/itinerary_day_component.dart';
import '../ui/chat/itinerary_header_component.dart';
import '../ui/chat/itinerary_timeline_component.dart';
import '../ui/chat/gap_component.dart';
import '../ui/chat/grid_component.dart';
import '../ui/chat/progress_bar_component.dart';
import '../ui/chat/responsive_container.dart';
import '../ui/chat/stack_component.dart';
import '../ui/chat/text_component.dart';
import '../ui/chat/text_field_override.dart';
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
/// Returns the default widget catalog for clawfree.
///
/// Extends genUI core widgets with custom and overridden components.
/// Core overrides (Card, Button, Text, ChoicePicker) replace the genUI
/// defaults by using the same name in copyWith.
Catalog getClawfreeCatalog() {
  return Catalog([
    // --- Polyfilled Core Items (since CoreCatalogItems is missing in v0.9 remote) ---
    CatalogItem(
      name: 'Column',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['Column']),
          'children': S.list(items: S.string()),
          'crossAxisAlignment': S.string(enumValues: ['start', 'center', 'end', 'stretch']),
          'gap': S.number(description: 'Gap between children.'),
        },
        required: ['component', 'children'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        final children = (data['children'] as List?)?.cast<String>() ?? [];
        final crossAlign = data['crossAxisAlignment'] as String? ?? 'stretch'; // Default to stretch
        final gap = (data['gap'] as num?)?.toDouble() ?? 0.0;

        return Column(
          crossAxisAlignment: switch (crossAlign) {
            'center' => CrossAxisAlignment.center,
            'end' => CrossAxisAlignment.end,
            'start' => CrossAxisAlignment.start,
            _ => CrossAxisAlignment.stretch,
          },
          mainAxisSize: MainAxisSize.min,
          children: children.map((id) {
            final child = context.buildChild(id);
            if (gap > 0 && id != children.last) {
              return Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: child,
              );
            }
            return child;
          }).toList(),
        );
      },
    ),
    CatalogItem(
      name: 'Row',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['Row']),
          'children': S.list(items: S.string()),
          'mainAxisAlignment': S.string(enumValues: ['start', 'center', 'end', 'spaceBetween']),
          'justify': S.string(
            enumValues: ['start', 'center', 'end', 'spaceBetween'],
            description: 'Alias for mainAxisAlignment.',
          ),
          'wrap': S.boolean(description: 'Whether to wrap children if they overflow.'),
          'spacing': S.number(description: 'Gap between children when wrapped.'),
        },
        required: ['component', 'children'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        final children = (data['children'] as List?)?.cast<String>() ?? [];
        final mainAlign = data['mainAxisAlignment'] as String?
            ?? data['justify'] as String?
            ?? 'start';
        final shouldWrap = data['wrap'] as bool? ?? true;
        final spacing = (data['spacing'] as num?)?.toDouble() ?? 8.0;

        final childrenWidgets = children.map((id) => context.buildChild(id)).toList();

        if (shouldWrap) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: switch (mainAlign) {
              'center' => WrapAlignment.center,
              'end' => WrapAlignment.end,
              'spaceBetween' => WrapAlignment.spaceBetween,
              _ => WrapAlignment.start,
            },
            children: childrenWidgets,
          );
        }

        return Row(
          mainAxisAlignment: switch (mainAlign) {
            'center' => MainAxisAlignment.center,
            'end' => MainAxisAlignment.end,
            'spaceBetween' => MainAxisAlignment.spaceBetween,
            _ => MainAxisAlignment.start,
          },
          children: childrenWidgets,
        );
      },
    ),
    CatalogItem(
      name: 'Image',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['Image']),
          'url': S.string(),
          'variant': S.string(
            enumValues: [
              'thumbnail', 'smallFeature', 'mediumFeature', 'fullWidth', 'header',
            ],
            description: 'Image display size variant.',
          ),
        },
        required: ['component', 'url'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        final url = data['url'] as String? ?? '';
        final variant = data['variant'] as String? ?? 'fullWidth';
        if (url.isEmpty) return const SizedBox.shrink();

        final image = Image.network(
          url,
          fit: (variant == 'header' || variant == 'fullWidth') ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(ClawfreeIcons.brokenImage),
        );

        if (variant == 'header' || variant == 'fullWidth') {
          return SizedBox(width: double.infinity, child: image);
        }
        return image;
      },
    ),
    CatalogItem(
      name: 'Icon',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['Icon']),
          'icon': S.string(description: 'Icon name (e.g. "check", "warning").'),
          'codePoint': S.integer(description: 'Material icon code point (alternative to icon).'),
          'size': S.string(
            enumValues: ['small', 'medium', 'large'],
            description: 'Icon size. Defaults to medium.',
          ),
        },
        required: ['component'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        final iconName = data['icon'] as String?;
        final sizeStr = data['size'] as String? ?? 'medium';
        final iconSize = switch (sizeStr) {
          'small' => 16.0,
          'large' => 32.0,
          _ => 24.0,
        };
        IconData? iconData;
        if (iconName != null) {
          iconData = resolveIcon(iconName);
        }
        if (iconData == null) return const SizedBox.shrink();
        return Icon(iconData, size: iconSize);
      },
    ),
    CatalogItem(
      name: 'Divider',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['Divider']),
        },
        required: ['component'],
      ),
      widgetBuilder: (context) => const Divider(),
    ),
    CatalogItem(
      name: 'Slider',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['Slider']),
          'label': S.string(description: 'Label for the slider.'),
          'value': S.number(description: 'Current value.'),
          'min': S.number(description: 'Minimum value. Defaults to 0.'),
          'max': S.number(description: 'Maximum value. Defaults to 100.'),
        },
        required: ['component', 'label'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        final label = data['label'] as String? ?? '';
        final value = (data['value'] as num?)?.toDouble() ?? 0;
        final min = (data['min'] as num?)?.toDouble() ?? 0;
        final max = (data['max'] as num?)?.toDouble() ?? 100;
        final fraction = max > min ? (value - min) / (max - min) : 0.0;
        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    label.toUpperCase(),
                    style: ClawfreeTheme.technicalStyle(
                      context: context.buildContext,
                      fontSize: 10,
                    ),
                  ),
                ),
                          ClipRRect(
                            borderRadius: ClawfreeBorderRadius.tiny,
                            child: SizedBox(
                              width: double.infinity,
                              child: LinearProgressIndicator(
                                value: fraction.clamp(0.0, 1.0),
                                minHeight: 6,
                              ),
                            ),
                          ),
              
            ],
          ),
        );
      },
    ),
    CatalogItem(
      name: 'CheckBox',
      dataSchema: S.object(
        properties: {
          'component': S.string(enumValues: ['CheckBox']),
          'label': S.string(description: 'Checkbox label text.'),
          'value': S.boolean(description: 'Whether checked.'),
        },
        required: ['component', 'label'],
      ),
      widgetBuilder: (context) {
        final data = context.data as Map<String, dynamic>;
        final label = data['label'] as String? ?? '';
        final value = data['value'] as bool? ?? false;
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: Theme.of(context.buildContext).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: ClawfreeTheme.technicalStyle(
                  context: context.buildContext,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    ),
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
      name: 'ItineraryHeader',
      dataSchema: itineraryHeaderSchema,
      widgetBuilder: itineraryHeaderCatalogBuilder,
    ),
    CatalogItem(
      name: 'ItineraryTimeline',
      dataSchema: itineraryTimelineSchema,
      widgetBuilder: itineraryTimelineCatalogBuilder,
    ),
    CatalogItem(
      name: 'ItineraryDay',
      dataSchema: itineraryDaySchema,
      widgetBuilder: itineraryDayCatalogBuilder,
    ),
    CatalogItem(
      name: 'AgentCard',
      dataSchema: agentCardSchema,
      widgetBuilder: agentCardCatalogBuilder,
    ),
    CatalogItem(
      name: 'BookingSummary',
      dataSchema: bookingSummarySchema,
      widgetBuilder: bookingSummaryCatalogBuilder,
    ),
    CatalogItem(
      name: 'HotelCard',
      dataSchema: hotelCardSchema,
      widgetBuilder: hotelCardCatalogBuilder,
    ),
    CatalogItem(
      name: 'FlightTicket',
      dataSchema: flightTicketSchema,
      widgetBuilder: flightTicketCatalogBuilder,
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
        return ClawfreeLogo(size: (data['size'] as num?)?.toDouble() ?? 64.0);
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

    // --- Core overrides ---
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
    CatalogItem(
      name: 'TextField',
      dataSchema: textFieldOverrideSchema,
      widgetBuilder: textFieldOverrideCatalogBuilder,
    ),
  ], catalogId: 'clawfree-catalog');
}
