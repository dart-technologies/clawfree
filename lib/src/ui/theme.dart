import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/platform_config.dart';

class ClawfreeTheme {
  // Brand colors
  static const lobsterOrange = Color(0xFFFF6B35);
  static const teal = Color(0xFF00BFA5);

  // Dark mode surface layers (rich depth hierarchy)
  static const darkBase = Color(0xFF121212);
  static const darkBg = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF242424);
  static const darkSurfaceHigh = Color(0xFF2A2A2A);
  static const darkSurfaceHighest = Color(0xFF333333);

  // Glow colors
  static const orangeGlow = Color(0x33FF6B35); // 20% orange
  static const tealGlow = Color(0x3300BFA5);

  // High-contrast text colors for WCAG AA (4.5:1 on #1A1A1A)
  static const textPrimary = Color(0xFFF5F5F5); // ~15:1
  static const textSecondary = Color(0xFFBDBDBD); // ~8:1
  static const textTertiary = Color(0xFF9E9E9E); // ~5:1

  static const _primaryColor = lobsterOrange;
  static const _accentColor = teal;

  /// Standard animation durations
  static const durationFast = Duration(milliseconds: 200);
  static const durationMedium = Duration(milliseconds: 300);

  /// Whether the current platform uses Apple (Cupertino) design language.
  static bool get isApple => PlatformConfig.isApple;

  /// Glassmorphism decoration helper
  static BoxDecoration glassmorphism({
    Color? color,
    double opacity = 0.08,
    double borderRadius = 16,
    double blurRadius = 20,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 0.5,
      ),
    );
  }

  /// Orange glow box shadow for focused/active elements
  static List<BoxShadow> orangeGlowShadow({double intensity = 1.0}) {
    return [
      BoxShadow(
        color: lobsterOrange.withValues(alpha: 0.15 * intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: lobsterOrange.withValues(alpha: 0.08 * intensity),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ];
  }

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
      textTheme: _buildTextTheme(base.textTheme, colorScheme),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _accentColor,
      brightness: Brightness.dark,
      surface: darkBg,
      onSurface: textPrimary,
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
      textTheme: _buildTextTheme(base.textTheme, colorScheme),
    );
  }

  /// Builds text theme with Google Fonts (Space Grotesk for headlines, Inter for body).
  static TextTheme _buildTextTheme(TextTheme base, ColorScheme colorScheme) {
    final headlineFont = GoogleFonts.spaceGroteskTextTheme(base);
    final bodyFont = GoogleFonts.interTextTheme(base);

    return bodyFont.copyWith(
      // Headlines use Space Grotesk
      displayLarge: headlineFont.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: headlineFont.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      displaySmall: headlineFont.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineLarge: headlineFont.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.3,
      ),
      headlineMedium: headlineFont.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: headlineFont.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: headlineFont.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
      titleMedium: bodyFont.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: bodyFont.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      // Body uses Inter
      bodyLarge: bodyFont.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodySmall: bodyFont.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      labelLarge: bodyFont.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelMedium: bodyFont.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      labelSmall: bodyFont.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}
