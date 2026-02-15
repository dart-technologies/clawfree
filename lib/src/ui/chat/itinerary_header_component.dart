import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';

/// JSON Schema for the ItineraryHeader A2UI component.
final itineraryHeaderSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ItineraryHeader']),
    'title': S.string(description: 'Main title of the itinerary.'),
    'subtitle': S.string(description: 'Technical subtitle or metadata line.'),
    'vibe': S.string(description: 'Current travel vibe (e.g. FOODIE).'),
    'status': S.string(description: 'System status text (e.g. READY).'),
  },
  required: ['component', 'title'],
);

/// Catalog builder for the ItineraryHeader component.
Widget itineraryHeaderCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return ItineraryHeaderComponent(
    itemContext: itemContext,
    title: data['title'] as String? ?? '',
    subtitle: data['subtitle'] as String? ?? '',
    vibe: data['vibe'] as String? ?? 'DISCOVERY',
    status: data['status'] as String? ?? 'ACTIVE',
  );
}

class ItineraryHeaderComponent extends StatelessWidget {
  const ItineraryHeaderComponent({
    super.key,
    required this.itemContext,
    required this.title,
    required this.subtitle,
    required this.vibe,
    required this.status,
  });

  final CatalogItemContext itemContext;
  final String title;
  final String subtitle;
  final String vibe;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Split subtitle to extract date and logistics
    final parts = subtitle.split(' \u2022 ');
    final datePart = parts.first.toUpperCase();
    
    // Try to extract duration from title (e.g. "3-DAY")
    final titleUpper = title.toUpperCase();
    String mainTitle = titleUpper;
    String? duration;
    
    final durationMatch = RegExp(r'(\d+-DAY)').firstMatch(titleUpper);
    if (durationMatch != null) {
      duration = durationMatch.group(1);
      mainTitle = titleUpper.replaceFirst(duration!, '').replaceAll('  ', ' ').trim();
    }

    final logisticsPart = parts.length > 1 ? parts.sublist(1).join(' \u2022 ').toUpperCase() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Technical Metadata Bar
        Row(
          children: [
            Flexible(
              child: Text(
                'ORCHESTRATION: OPUS 4.6',
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: cs.primary.withValues(alpha: 0.6),
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              datePart,
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 8,
                color: ClawfreeTheme.hudTextFaint,
              ),
              maxLines: 1,
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Main Focus: Trip Title + Duration Pill
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                mainTitle,
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
            if (duration != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: ClawfreeBorderRadius.tiny,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  duration,
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Secondary Details (Logistics only)
        if (logisticsPart.isNotEmpty)
          Text(
            logisticsPart,
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 10,
              color: ClawfreeTheme.hudTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
        const SizedBox(height: 16),
        Divider(color: ClawfreeTheme.hudDivider, thickness: 1),
      ],
    );
  }
}
