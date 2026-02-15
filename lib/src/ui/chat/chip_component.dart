import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';
import 'icon_resolver.dart';

/// JSON Schema for the Chip A2UI component.
final chipSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Chip']),
    'label': S.string(description: 'Chip label text.'),
    'icon': S.string(description: 'Icon name (e.g. "star", "check").'),
    'variant': S.string(
      enumValues: ['default', 'outlined', 'filled'],
      description: 'Visual variant. Defaults to default.',
    ),
    'color': S.string(description: 'Hex color override (e.g. "#0066CC").'),
    'deletable': S.boolean(
      description: 'Whether the chip shows a delete button.',
    ),
  },
  required: ['component', 'label'],
);

/// Catalog builder for the Chip component.
Widget chipCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final label = data['label'] as String? ?? '';
  final iconName = data['icon'] as String?;
  final variant = data['variant'] as String? ?? 'default';
  final colorHex = data['color'] as String?;
  final deletable = data['deletable'] as bool? ?? false;

  return _ChipWidget(
    itemContext: itemContext,
    label: label,
    iconName: iconName,
    variant: variant,
    color: parseHexColor(colorHex),
    deletable: deletable,
  );
}

class _ChipWidget extends StatelessWidget {
  const _ChipWidget({
    required this.itemContext,
    required this.label,
    this.iconName,
    this.variant = 'default',
    this.color,
    this.deletable = false,
  });

  final CatalogItemContext itemContext;
  final String label;
  final String? iconName;
  final String variant;
  final Color? color;
  final bool deletable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipColor = color ?? cs.primary;
    final icon = resolveIcon(iconName);

    final avatar = icon != null ? Icon(icon, size: 16, color: chipColor) : null;

    final labelWidget = Text(
      label.toUpperCase(),
      style: ClawfreeTheme.technicalStyle(context: context, fontSize: 11),
    );

    if (variant == 'filled') {
      return InputChip(
        label: labelWidget,
        avatar: avatar,
        backgroundColor: chipColor.withValues(alpha: 0.15),
        side: BorderSide.none,
        onDeleted: deletable ? () => _onDeleted() : null,
        deleteIconColor: chipColor,
      );
    }

    if (variant == 'outlined') {
      return InputChip(
        label: labelWidget,
        avatar: avatar,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: chipColor.withValues(alpha: 0.5)),
        onDeleted: deletable ? () => _onDeleted() : null,
        deleteIconColor: chipColor,
      );
    }

    // default
    return InputChip(
      label: labelWidget,
      avatar: avatar,
      onDeleted: deletable ? () => _onDeleted() : null,
      deleteIconColor: cs.onSurface.withValues(alpha: 0.5),
    );
  }

  void _onDeleted() {
    itemContext.dispatchEvent(
      UserActionEvent(
        name: 'chip_deleted',
        sourceComponentId: itemContext.id,
        context: {'label': label},
      ),
    );
  }
}
