import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
// ignore: implementation_imports
import 'package:genui/src/functions/expression_parser.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';
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
      enumValues: ['primary', 'secondary', 'ghost', 'danger', 'borderless', 'gradient'],
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

    final textStyle = ClawfreeTheme.technicalStyle(
      context: context,
      fontWeight: FontWeight.w800,
      fontSize: fontSize,
      letterSpacing: 1.0,
    );

    // Using element radius (16px) instead of StadiumBorder so buttons sit
    // more predictably side-by-side or stacked.
    final shape = RoundedRectangleBorder(
      borderRadius: ClawfreeBorderRadius.interactive,
    );

    final Widget label = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
          foregroundColor: cs.primary,
        ),
        child: DefaultTextStyle.merge(
          style: textStyle.copyWith(color: cs.primary),
          child: label,
        ),
      ),
      'ghost' => TextButton(
        onPressed: _handlePress,
        style: TextButton.styleFrom(
          shape: shape,
          padding: padding,
          foregroundColor: cs.onSurface.withValues(alpha: 0.7),
        ),
        child: DefaultTextStyle.merge(
          style: textStyle.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
          child: label,
        ),
      ),
      'danger' => ElevatedButton(
        onPressed: _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          shape: shape,
          padding: padding,
          elevation: 0,
        ),
        child: DefaultTextStyle.merge(
          style: textStyle.copyWith(color: cs.onError),
          child: label,
        ),
      ),
      'borderless' => TextButton(
        onPressed: _handlePress,
        style: TextButton.styleFrom(
          padding: padding,
        ),
        child: DefaultTextStyle.merge(
          style: textStyle,
          child: label,
        ),
      ),
      'gradient' => Container(
        decoration: BoxDecoration(
          borderRadius: ClawfreeBorderRadius.interactive,
          gradient: LinearGradient(
            colors: [cs.primary, cs.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: ClawfreeTheme.technicalGlow(cs.primary, intensity: 0.3),
        ),
        child: ElevatedButton(
          onPressed: _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: cs.onPrimary,
            shadowColor: Colors.transparent,
            shape: shape,
            padding: padding,
            elevation: 0,
          ),
          child: DefaultTextStyle.merge(
            style: textStyle.copyWith(color: cs.onPrimary),
            child: label,
          ),
        ),
      ),
      // primary (default)
      _ => Container(
        decoration: BoxDecoration(
          borderRadius: ClawfreeBorderRadius.interactive,
          boxShadow: ClawfreeTheme.technicalGlow(cs.primary, intensity: 0.25),
        ),
        child: ElevatedButton(
          onPressed: _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: shape,
            padding: padding,
            elevation: 0,
          ),
          child: DefaultTextStyle.merge(
            style: textStyle.copyWith(
              color: cs.onPrimary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
            child: label,
          ),
        ),
      ),
    };

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // Add consistent vertical spacing to prevent components from touching
    // when the LLM omits a Gap component.
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: button,
    );
  }
}
