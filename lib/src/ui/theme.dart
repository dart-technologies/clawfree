import 'package:flutter/material.dart';

import '../core/platform_config.dart';

class ClawfreeTheme {
  static const _primaryColor = Color(0xFF0066CC);
  static const _accentColor = Color(0xFFFF6600);

  /// Whether the current platform uses Apple (Cupertino) design language.
  static bool get isApple => PlatformConfig.isApple;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _accentColor,
    );

    final base = ThemeData.from(colorScheme: colorScheme);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor:
            isApple ? _primaryColor.withValues(alpha: 0.95) : _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: isApple ? Colors.transparent : null,
      ),
      cardTheme: isApple
          ? CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
            )
          : null,
      inputDecorationTheme: isApple
          ? InputDecorationTheme(
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
            )
          : null,
      textTheme: base.textTheme.merge(_textThemeOverrides(colorScheme)),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _accentColor,
      brightness: Brightness.dark,
    );

    final base = ThemeData.from(colorScheme: colorScheme);
    return base.copyWith(
      appBarTheme: isApple
          ? AppBarTheme(
              backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      cardTheme: isApple
          ? CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
            )
          : null,
      textTheme: base.textTheme.merge(_textThemeOverrides(colorScheme)),
    );
  }

  /// Custom font weight overrides — merged on top of the base theme's
  /// textTheme so that all styles (bodyMedium, titleMedium, etc.) keep
  /// their correctly-themed colors for light/dark mode.
  static TextTheme _textThemeOverrides(ColorScheme colorScheme) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
    );
  }
}
