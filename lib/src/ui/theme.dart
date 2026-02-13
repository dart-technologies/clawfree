import 'package:flutter/material.dart';

import '../core/platform_config.dart';

class ClawfreeTheme {
  // Brand colors
  static const lobsterOrange = Color(0xFFFF6B35);
  static const teal = Color(0xFF00BFA5);
  static const darkBg = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF242424);
  static const darkSurfaceHigh = Color(0xFF2A2A2A);

  static const _primaryColor = lobsterOrange;
  static const _accentColor = teal;

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
      surface: darkBg,
      onSurface: const Color(0xFFE0E0E0),
    );

    final base = ThemeData.from(colorScheme: colorScheme);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg.withValues(alpha: 0.95),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceHigh,
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
      ),
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
