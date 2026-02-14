import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';
import 'icon_resolver.dart';

/// JSON Schema for the Badge A2UI component.
final badgeSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Badge']),
    'text': S.string(description: 'Badge label text.'),
    'variant': S.string(
      enumValues: ['success', 'warning', 'error', 'info', 'neutral'],
      description: 'Color variant. Defaults to neutral.',
    ),
    'icon': S.string(description: 'Icon name (e.g. "check", "warning").'),
    'glow': S.boolean(description: 'Whether to add a subtle glow effect.'),
  },
  required: ['component', 'text'],
);

/// Catalog builder for the Badge component.
Widget badgeCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final text = data['text'] as String? ?? '';
  final variant = data['variant'] as String? ?? 'neutral';
  final iconName = data['icon'] as String?;
  final glow = data['glow'] as bool? ?? false;

  return _BadgeWidget(
    text: text,
    variant: variant,
    iconName: iconName,
    glow: glow,
  );
}

class _BadgeWidget extends StatelessWidget {
  const _BadgeWidget({
    required this.text,
    required this.variant,
    this.iconName,
    this.glow = false,
  });

  final String text;
  final String variant;
  final String? iconName;
  final bool glow;

  Color _variantColor(ColorScheme cs) {
    return switch (variant) {
      'success' => Colors.green,
      'warning' => Colors.orange,
      'error' => cs.error,
      'info' => cs.primary,
      _ => cs.onSurface.withValues(alpha: 0.7),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _variantColor(cs);
    final icon = resolveIcon(iconName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: ClawfreeBorderRadius.pill,
        boxShadow: glow ? ClawfreeTheme.technicalGlow(color, intensity: 0.3) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
