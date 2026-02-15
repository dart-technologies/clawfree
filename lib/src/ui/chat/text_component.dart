import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';
import 'icon_resolver.dart';

/// JSON Schema for the Text A2UI component override.
final textOverrideSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Text']),
    'text': A2uiSchemas.stringReference(
      description: 'Text content. Supports simple Markdown.',
    ),
    'variant': S.string(
      enumValues: [
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'caption', 'body', 'body1', 'body2',
        'technical', 'mono', 'label', 'overline',
      ],
      description: 'Text style variant.',
    ),
    'fontSize': S.number(description: 'Font size override in logical pixels.'),
    'fontWeight': S.integer(description: 'Font weight override (e.g. 700).'),
    'letterSpacing': S.number(description: 'Letter spacing override.'),
    'color': S.string(description: 'Hex color override (e.g. "#00FF88").'),
  },
  required: ['component', 'text'],
);

/// Catalog builder for the clawfree Text override.
Widget textOverrideCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final textRef = data['text'];
  final variant = data['variant'] as String? ?? 'body';
  final fontSizeOverride = (data['fontSize'] as num?)?.toDouble();
  final fontWeightOverride = (data['fontWeight'] as num?)?.toInt();
  final letterSpacingOverride = (data['letterSpacing'] as num?)?.toDouble();
  final colorOverride = parseHexColor(data['color'] as String?);

  // Subscribe to string for reactive data binding.
  final notifier = _subscribeToText(itemContext.dataContext, textRef);

  return ValueListenableBuilder<String?>(
    valueListenable: notifier,
    builder: (context, currentValue, _) {
      final text = currentValue ?? '';

      // Clawfree-specific variants use plain Text.
      return switch (variant) {
        'technical' => Text(
          text.toUpperCase(),
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: fontSizeOverride ?? 10,
            fontWeight: _parseFontWeight(fontWeightOverride ?? 700),
            letterSpacing: letterSpacingOverride ?? 1.0,
            color: colorOverride,
          ),
        ),
        'mono' => MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: _parseFontWeight(fontWeightOverride ?? 400),
              fontSize: fontSizeOverride ?? 14,
              letterSpacing: letterSpacingOverride,
              color: colorOverride,
            ),
          ),
        ),
        'label' => Text(
          text.toUpperCase(),
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontWeight: _parseFontWeight(fontWeightOverride ?? 700),
            fontSize: fontSizeOverride ?? 12,
            letterSpacing: letterSpacingOverride ?? 0.8,
            color: colorOverride ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        'overline' => Text(
          text.toUpperCase(),
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontWeight: _parseFontWeight(fontWeightOverride ?? 600),
            fontSize: fontSizeOverride ?? 10,
            letterSpacing: letterSpacingOverride ?? 1.5,
            color: colorOverride ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        // Standard variants — replicate core Text with MarkdownBody.
        _ => _buildMarkdownVariant(
          context, text, variant,
          fontSizeOverride: fontSizeOverride,
          colorOverride: colorOverride,
        ),
      };
    },
  );
}

FontWeight _parseFontWeight(int value) {
  return switch (value) {
    100 => FontWeight.w100,
    200 => FontWeight.w200,
    300 => FontWeight.w300,
    400 => FontWeight.w400,
    500 => FontWeight.w500,
    600 => FontWeight.w600,
    700 => FontWeight.w700,
    800 => FontWeight.w800,
    900 => FontWeight.w900,
    _ => FontWeight.w700,
  };
}

Widget _buildMarkdownVariant(
  BuildContext context,
  String text,
  String variant, {
  double? fontSizeOverride,
  Color? colorOverride,
}) {
  final textTheme = Theme.of(context).textTheme;

  var baseStyle = switch (variant) {
    'h1' => textTheme.headlineLarge,
    'h2' => textTheme.headlineMedium,
    'h3' => textTheme.headlineSmall,
    'h4' => textTheme.titleLarge,
    'h5' => textTheme.titleMedium,
    'h6' => textTheme.titleSmall,
    'caption' || 'body2' => textTheme.bodySmall,
    _ => DefaultTextStyle.of(context).style,
  };

  if (fontSizeOverride != null || colorOverride != null) {
    baseStyle = baseStyle?.copyWith(
      fontSize: fontSizeOverride ?? baseStyle.fontSize,
      color: colorOverride ?? baseStyle.color,
    );
  }

  final verticalPadding = switch (variant) {
    'h1' => 8.0,
    'h2' => 6.0,
    'h3' => 4.0,
    'h4' => 4.0,
    'h5' || 'h6' => 2.0,
    'caption' || 'body2' => 0.0,
    _ => 2.0,
  };

  return Padding(
    padding: EdgeInsets.symmetric(vertical: verticalPadding),
    child: MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: baseStyle,
      ),
    ),
  );
}

ValueNotifier<String?> _subscribeToText(DataContext context, Object? textRef) {
  if (textRef is Map) {
    if (textRef.containsKey('path')) {
      return context.subscribe<String>(textRef['path'] as String);
    }
  }
  if (textRef is String) {
    if (textRef.contains(r'${')) {
      return context.subscribe<String>(textRef);
    }
    return ValueNotifier(textRef);
  }
  return ValueNotifier(textRef?.toString());
}
