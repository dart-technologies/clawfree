import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../clawfree_icons.dart';
import '../theme.dart';
import 'icon_resolver.dart';

/// JSON Schema for the ItineraryTimeline A2UI component.
final itineraryTimelineSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ItineraryTimeline']),
    'days': S.list(
      items: S.object(
        properties: {
          'dayLabel': S.string(description: 'Label for the day (e.g. DAY 1).'),
          'title': S.string(description: 'Main theme/title of the day.'),
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
        required: ['dayLabel', 'title', 'activities'],
      ),
    ),
  },
  required: ['component', 'days'],
);

/// Catalog builder for the ItineraryTimeline component.
Widget itineraryTimelineCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return ItineraryTimelineComponent(
    itemContext: itemContext,
    days: (data['days'] as List?)?.map((d) {
      final map = d as Map<String, dynamic>;
      return TimelineDay(
        dayLabel: map['dayLabel'] as String? ?? '',
        title: map['title'] as String? ?? '',
        activities: (map['activities'] as List?)?.map((a) {
          final amap = a as Map<String, dynamic>;
          return TimelineActivity(
            time: amap['time'] as String? ?? '',
            label: amap['label'] as String? ?? '',
            icon: amap['icon'] as String?,
          );
        }).toList() ?? [],
      );
    }).toList() ?? [],
  );
}

class TimelineDay {
  const TimelineDay({required this.dayLabel, required this.title, required this.activities});
  final String dayLabel;
  final String title;
  final List<TimelineActivity> activities;
}

class TimelineActivity {
  const TimelineActivity({required this.time, required this.label, this.icon});
  final String time;
  final String label;
  final String? icon;
}

class ItineraryTimelineComponent extends StatelessWidget {
  const ItineraryTimelineComponent({
    super.key,
    required this.itemContext,
    required this.days,
  });

  final CatalogItemContext itemContext;
  final List<TimelineDay> days;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ClawfreeTheme.hudSurfaceFaint,
              border: Border(bottom: BorderSide(color: ClawfreeTheme.hudSurfaceFaint)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAILY LOGISTICS',
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${days.length} DAYS SEQUENCED',
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 8,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Timeline Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: days.map((day) => _DayBlock(day)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock(this.day);
  final TimelineDay day;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${day.dayLabel.toUpperCase()} \u2022 ${day.title.toUpperCase()}',
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        ...day.activities.map((a) => _ActivityRow(a)),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.activity);
  final TimelineActivity activity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconData = activity.icon != null ? resolveIcon(activity.icon!) : ClawfreeIcons.timelineDot;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Block
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                activity.time.toUpperCase(),
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: ClawfreeTheme.hudTextMuted,
                ),
              ),
            ),
          ),
          
          // Technical Timeline Column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Icon(iconData, size: 10, color: cs.primary.withValues(alpha: 0.6)),
                Expanded(
                  child: Container(
                    width: 0.5,
                    color: ClawfreeTheme.hudBorder,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                activity.label,
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 11,
                  color: ClawfreeTheme.hudTextPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
