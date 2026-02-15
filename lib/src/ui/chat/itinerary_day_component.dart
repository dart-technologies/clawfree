import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../clawfree_icons.dart';
import '../theme.dart';
import 'icon_resolver.dart';

/// JSON Schema for the ItineraryDay A2UI component.
final itineraryDaySchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ItineraryDay']),
    'dayLabel': S.string(description: 'Label for the day (e.g. DAY 1 • TSUKIJI).'),
    'title': S.string(description: 'Main theme/title of the day.'),
    'imageUrl': S.string(description: 'Hero image for the day.'),
    'activities': S.list(
      items: S.object(
        properties: {
          'time': S.string(),
          'label': S.string(),
          'icon': S.string(description: 'Material icon name.'),
        },
        required: ['time', 'label'],
      ),
    ),
  },
  required: ['component', 'dayLabel', 'title', 'activities'],
);

/// Catalog builder for the ItineraryDay component.
Widget itineraryDayCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return ItineraryDayComponent(
    itemContext: itemContext,
    dayLabel: data['dayLabel'] as String? ?? '',
    title: data['title'] as String? ?? '',
    imageUrl: data['imageUrl'] as String?,
    activities: (data['activities'] as List?)?.map((a) {
      final map = a as Map<String, dynamic>;
      return ItineraryActivity(
        time: map['time'] as String? ?? '',
        label: map['label'] as String? ?? '',
        icon: map['icon'] as String?,
      );
    }).toList() ?? [],
  );
}

class ItineraryActivity {
  const ItineraryActivity({required this.time, required this.label, this.icon});
  final String time;
  final String label;
  final String? icon;
}

class ItineraryDayComponent extends StatelessWidget {
  const ItineraryDayComponent({
    super.key,
    required this.itemContext,
    required this.dayLabel,
    required this.title,
    this.imageUrl,
    required this.activities,
  });

  final CatalogItemContext itemContext;
  final String dayLabel;
  final String title;
  final String? imageUrl;
  final List<ItineraryActivity> activities;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ClawfreeTheme.hudContainerColor,
        borderRadius: ClawfreeBorderRadius.element,
        border: Border.all(
          color: ClawfreeTheme.hudBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: ClawfreeBorderRadius.element,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day Header Image
            if (imageUrl != null)
              Stack(
                children: [
                  Image.network(
                    imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            ClawfreeTheme.hudOverlayColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel.toUpperCase(),
                          style: ClawfreeTheme.technicalStyle(
                            context: context,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          title.toUpperCase(),
                          style: ClawfreeTheme.technicalStyle(
                            context: context,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Activity Timeline
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: activities.map((a) => _ActivityRow(a)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.activity);
  final ItineraryActivity activity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconData = activity.icon != null ? resolveIcon(activity.icon!) : ClawfreeIcons.timelineDot;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Block
          SizedBox(
            width: 64,
            child: Text(
              activity.time.toUpperCase(),
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: ClawfreeTheme.hudTextMuted,
              ),
            ),
          ),
          
          // Technical Dot/Line
          Column(
            children: [
              Icon(iconData, size: 12, color: cs.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 4),
              // We don't do a full line here to keep it clean, but could add one
            ],
          ),
          
          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              activity.label,
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 11,
                color: ClawfreeTheme.hudTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
