import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../clawfree_icons.dart';
import '../theme.dart';
import '../health/health_indicators.dart';

/// JSON Schema for the AgentCard A2UI component.
final agentCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['AgentCard']),
    'name': S.string(description: 'Agent name.'),
    'status': S.string(description: 'Status text (e.g. ONLINE).'),
    'meta': S.string(description: 'Technical metadata line.'),
    'model': S.string(description: 'Model identifier (e.g. OPUS 4.6).'),
    'level': S.string(
      enumValues: ['nominal', 'warning', 'critical', 'unknown'],
      description: 'Health level for the status indicator.',
    ),
    'action': A2uiSchemas.action(description: 'Action to dispatch on tap/view.'),
  },
  required: ['component', 'name', 'action'],
);

/// Catalog builder for the AgentCard component.
Widget agentCardCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  
  return AgentCardComponent(
    itemContext: itemContext,
    name: data['name'] as String? ?? '',
    status: data['status'] as String? ?? 'ONLINE',
    meta: data['meta'] as String? ?? '',
    model: data['model'] as String? ?? 'OPUS 4.6',
    level: data['level'] as String? ?? 'nominal',
    action: data['action'] as Map<String, Object?>? ?? {},
  );
}

class AgentCardComponent extends StatelessWidget {
  const AgentCardComponent({
    super.key,
    required this.itemContext,
    required this.name,
    required this.status,
    required this.meta,
    required this.model,
    required this.level,
    required this.action,
  });

  final CatalogItemContext itemContext;
  final String name;
  final String status;
  final String meta;
  final String model;
  final String level;
  final Map<String, Object?> action;

  void _handlePress() {
    if (action.containsKey('event')) {
      final eventMap = action['event'] as Map<String, Object?>;
      final actionName = eventMap['name'] as String;
      final contextDef = eventMap['context'] as Map<String, Object?>?;

      final resolvedCtx = resolveContext(
        itemContext.dataContext,
        contextDef,
      );
      itemContext.dispatchEvent(
        UserActionEvent(
          name: actionName,
          sourceComponentId: itemContext.id,
          context: resolvedCtx,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final healthLevel = HealthLevel.values.firstWhere(
      (l) => l.name == level,
      orElse: () => HealthLevel.nominal,
    );
    final statusColor = healthColor(healthLevel);

    return GestureDetector(
      onTap: _handlePress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClawfreeTheme.hudContainerColor,
          borderRadius: ClawfreeBorderRadius.element,
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Model
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  model.toUpperCase(),
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 9,
                    color: ClawfreeTheme.hudTextFaint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Status Indicator
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      ClawfreeTheme.technicalGlow(statusColor, intensity: 0.5)[0],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                meta.toUpperCase(),
                style: ClawfreeTheme.technicalStyle(
                  context: context,
                  fontSize: 9,
                  color: ClawfreeTheme.hudTextMuted,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ENGAGE AGENT',
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(ClawfreeIcons.arrowForward, size: 12, color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
