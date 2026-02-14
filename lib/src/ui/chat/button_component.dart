import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
// ignore: implementation_imports
import 'package:genui/src/functions/expression_parser.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'icon_resolver.dart';

typedef JsonMap = Map<String, Object?>;

/// JSON Schema for the Button A2UI component override.
final buttonOverrideSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Button']),
    'child': A2uiSchemas.componentReference(
      description: 'Button label content.',
    ),
    'action': A2uiSchemas.action(description: 'Action to dispatch on press.'),
    'variant': S.string(
      enumValues: ['primary', 'secondary', 'ghost', 'danger', 'borderless'],
      description: 'Button style variant. Defaults to primary.',
    ),
    'size': S.string(
      enumValues: ['small', 'medium', 'large'],
      description: 'Button size. Defaults to medium.',
    ),
    'icon': S.string(description: 'Leading icon name (e.g. "send", "add").'),
    'fullWidth': S.boolean(
      description: 'Whether the button expands to full width.',
    ),
  },
  required: ['component', 'child', 'action'],
);

/// Catalog builder for the clawfree Button override.
Widget buttonOverrideCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as JsonMap;
  final childRef = data['child'];
  final childId = childRef is String ? childRef : null;
  final action = data['action'] as JsonMap? ?? {};
  final variant = data['variant'] as String? ?? 'primary';
  final size = data['size'] as String? ?? 'medium';
  final iconName = data['icon'] as String?;
  final fullWidth = data['fullWidth'] as bool? ?? false;

  if (childId == null) return const SizedBox.shrink();

  return _ButtonWidget(
    itemContext: itemContext,
    childId: childId,
    action: action,
    variant: variant,
    size: size,
    iconName: iconName,
    fullWidth: fullWidth,
  );
}

class _ButtonWidget extends StatelessWidget {
  const _ButtonWidget({
    required this.itemContext,
    required this.childId,
    required this.action,
    required this.variant,
    required this.size,
    this.iconName,
    this.fullWidth = false,
  });

  final CatalogItemContext itemContext;
  final String childId;
  final JsonMap action;
  final String variant;
  final String size;
  final String? iconName;
  final bool fullWidth;

  EdgeInsets _paddingForSize() {
    return switch (size) {
      'small' => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      'large' => const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      _ => const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    };
  }

  double _fontSizeForSize() {
    return switch (size) {
      'small' => 12.0,
      'large' => 16.0,
      _ => 14.0,
    };
  }

  void _handlePress() {
    if (action.containsKey('event')) {
      final eventMap = action['event'] as JsonMap;
      final actionName = eventMap['name'] as String;
      final contextDef = eventMap['context'] as JsonMap?;

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
    } else if (action.containsKey('functionCall')) {
      final funcMap = action['functionCall'] as JsonMap;
      final callName = funcMap['call'] as String;

      if (callName == 'closeModal') {
        Navigator.of(itemContext.buildContext).pop();
        return;
      }

      final parser = ExpressionParser(itemContext.dataContext);
      parser.evaluateFunctionCall(funcMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = resolveIcon(iconName);
    final child = itemContext.buildChild(childId);
    final padding = _paddingForSize();
    final fontSize = _fontSizeForSize();

    final textStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      letterSpacing: 0.5,
    );

    final shape = const StadiumBorder();

    final Widget label = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: fontSize + 2),
              const SizedBox(width: 8),
              child,
            ],
          )
        : child;

    Widget button = switch (variant) {
      'secondary' => OutlinedButton(
        onPressed: _handlePress,
        style: OutlinedButton.styleFrom(
          shape: shape,
          side: BorderSide(color: cs.primary, width: 1.5),
          padding: padding,
          textStyle: textStyle,
        ),
        child: label,
      ),
      'ghost' => TextButton(
        onPressed: _handlePress,
        style: TextButton.styleFrom(
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        child: label,
      ),
      'danger' => ElevatedButton(
        onPressed: _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          shape: shape,
          padding: padding,
          elevation: 0,
          textStyle: textStyle,
        ),
        child: label,
      ),
      'borderless' => TextButton(
        onPressed: _handlePress,
        style: TextButton.styleFrom(
          padding: padding,
          textStyle: textStyle,
        ),
        child: label,
      ),
      // primary (default)
      _ => ElevatedButton(
        onPressed: _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: shape,
          padding: padding,
          elevation: 0,
          textStyle: textStyle,
        ),
        child: label,
      ),
    };

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
