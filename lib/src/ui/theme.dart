import 'package:flutter/material.dart';

import '../core/platform_config.dart';

/// Clawfree brand design system with Material 3 design tokens.
///
/// Color palette:
///   Primary: Lobster Orange (#FF6B35)
///   Secondary: Teal (#00BFA5)
///   Dark bg: #1A1A1A / surface: #242424 / card: #2A2A2A
///   Light bg: #FAFAFA
class ClawfreeTheme {
  ClawfreeTheme._();

  // -- Brand colors ----------------------------------------------------------
  static const lobsterOrange = Color(0xFFFF6B35);
  static const teal = Color(0xFF00BFA5);
  static const darkBg = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF242424);
  static const darkCard = Color(0xFF2A2A2A);
  static const lightBg = Color(0xFFFAFAFA);

  /// Whether the current platform uses Apple (Cupertino) design language.
  static bool get isApple => PlatformConfig.isApple;

  // -- Animation durations ---------------------------------------------------
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration transitionDuration = Duration(milliseconds: 300);

  // -- Border radii ----------------------------------------------------------
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusFull = 999;

  // -- Light theme -----------------------------------------------------------
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lobsterOrange,
      secondary: teal,
      brightness: Brightness.light,
      surface: lightBg,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // -- Dark theme ------------------------------------------------------------
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lobsterOrange,
      secondary: teal,
      brightness: Brightness.dark,
      surface: darkSurface,
    ).copyWith(
      // Override generated dark colors for a richer, deeper look
      surface: darkSurface,
      surfaceContainerHighest: darkCard,
      surfaceContainerHigh: const Color(0xFF303030),
      surfaceContainerLow: darkBg,
      surfaceContainer: const Color(0xFF262626),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // -- Shared builder --------------------------------------------------------
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? darkBg : lightBg,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? darkSurface.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: isApple,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        color: isDark ? darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: isDark
              ? BorderSide(color: Colors.white.withValues(alpha: 0.06))
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          borderSide: isDark
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          borderSide: BorderSide(color: lobsterOrange, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.w400,
        ),
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lobsterOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          elevation: isDark ? 0 : 2,
          shadowColor: lobsterOrange.withValues(alpha: 0.3),
          animationDuration: hoverDuration,
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lobsterOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          animationDuration: hoverDuration,
        ),
      ),

      // Icon button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          animationDuration: hoverDuration,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lobsterOrange;
          return isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lobsterOrange.withValues(alpha: 0.4);
          }
          return isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
        }),
      ),

      // Action chip (suggestion chips)
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkCard : Colors.white,
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        backgroundColor: isDark ? darkCard : colorScheme.inverseSurface,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        elevation: isDark ? 0 : 8,
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? darkCard : Colors.white,
        elevation: isDark ? 2 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),

      // Typography
      textTheme: _buildTextTheme(base.textTheme, colorScheme),
    );
  }

  // -- Font family -----------------------------------------------------------
  // Use Inter with system font fallbacks (SF Pro on Apple, sans-serif elsewhere)
  static const String _fontFamily = 'Inter';
  static const List<String> _fontFamilyFallback = [
    '.SF Pro Text',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  // -- Text theme ------------------------------------------------------------
  static TextTheme _buildTextTheme(TextTheme base, ColorScheme cs) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
