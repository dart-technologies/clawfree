import 'package:flutter/material.dart';

import '../core/platform_config.dart';

/// Standardized border radii for the clawfree design system.
class ClawfreeBorderRadius {
  ClawfreeBorderRadius._();

  static const surface = BorderRadius.all(Radius.circular(20));
  static const element = BorderRadius.all(Radius.circular(16));
  static const interactive = BorderRadius.all(Radius.circular(12));
  static const small = BorderRadius.all(Radius.circular(8));
  static const tiny = BorderRadius.all(Radius.circular(4));
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Standardized spacing values for the clawfree design system.
class ClawfreeSpacing {
  ClawfreeSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class ClawfreeTheme {
  static const _primaryColor = Color(0xFF0066CC);
  static const _accentColor = Color(0xFFFF6600);
  static const _fontFamily = 'JetBrainsMono';

  // --- Design Tokens: Status & Mood ---
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9F0A);
  static const error = Color(0xFFFF3B30);
  static const info = _primaryColor;
  static const neutral = Color(0xFF8E8E93);

  // --- Design Tokens: Session Modes ---
  static const onboardingMode = Color(0xFF9C27B0);
  static const homeMode = Color(0xFF2196F3);
  static const agentBuilderMode = _primaryColor;

  // --- Design Tokens: Glass & HUD ---
  static const glassOverlayColor = Color(0xD9000000); // 85% Black
  static const glassBlur = 20.0;
  static const itineraryAccent = Color(0xFF66AAFF);
  static const hudActive = Color(0xFF00FF88); // Neon green for live/active indicators
  static const scaffoldBlack = Color(0xFF050505); // Deep black matching scaffold
  static const ratingGold = Colors.amber;

  // --- Design Tokens: HUD Surface & Container ---
  static const hudBorder = Color(0x1AFFFFFF); // white 10%
  static const hudSurfaceFaint = Color(0x0DFFFFFF); // white 5%
  static const hudDivider = Color(0x1AFFFFFF); // white 10%
  static final hudContainerColor = Colors.black.withValues(alpha: 0.4);
  static final hudOverlayColor = Colors.black.withValues(alpha: 0.7);

  // --- Design Tokens: HUD Text Hierarchy ---
  static const hudTextPrimary = Colors.white70; // 70% white
  static const hudTextSecondary = Colors.white54; // 54% white
  static const hudTextMuted = Colors.white38; // 38% white
  static const hudTextFaint = Colors.white24; // 24% white

  /// Whether the current platform uses Apple (Cupertino) design language.
  static bool get isApple => PlatformConfig.isApple;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _accentColor,
    );

    final base = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: colorScheme.surface.withValues(alpha: 0.7),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.85,
        ),
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: colorScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: ClawfreeSpacing.xl,
          vertical: ClawfreeSpacing.lg,
        ),
      ),
      textTheme: base.textTheme.merge(_textThemeOverrides(colorScheme)),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _accentColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0A0A0A), // Deep HUD black
      onSurface: const Color(0xFFF5F5F5), // High-contrast off-white
      surfaceContainerHighest: const Color(0xFF121212),
      surfaceContainerHigh: const Color(0xFF1A1A1A),
      surfaceContainerLow: const Color(0xFF050505),
    );

    final base = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF050505),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        color: colorScheme.surface.withValues(alpha: 0.4),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ClawfreeBorderRadius.surface,
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: ClawfreeSpacing.xl,
          vertical: ClawfreeSpacing.lg,
        ),
      ),
      textTheme: base.textTheme.merge(_textThemeOverrides(colorScheme)),
    );
  }

  /// Custom font weight overrides and JetBrains Mono for a technical, modern look.
  static TextTheme _textThemeOverrides(ColorScheme colorScheme) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        letterSpacing: -1.0,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Monospaced, tracked, and condensed style for telemetry and technical IDs.
  static TextStyle technicalStyle({
    required BuildContext context,
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 1.0,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  /// Unified gradient that mirrors the VoiceOrb's color palette.
  static Gradient unifiedGradient(
    BuildContext context, {
    bool isError = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = isError ? cs.error : cs.primary;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: 0.15),
        baseColor.withValues(alpha: 0.05),
      ],
    );
  }

  /// Reusable frosted glass decoration with unified gradient and elevation support.
  static Decoration glassDecoration(
    BuildContext context, {
    bool isError = false,
    double elevation = 0,
    double borderRadius = 20,
    bool isPill = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isError ? colorScheme.error : colorScheme.primary;

    final opacityFactor = (1.0 - (elevation * 0.05)).clamp(0.2, 1.0);
    final blurSigma = 20.0 + (elevation * 5.0);

    return BoxDecoration(
      borderRadius: isPill
          ? ClawfreeBorderRadius.pill
          : BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.15),
        width: 0.5, // Ultra-thin HUD border
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withValues(alpha: (isDark ? 0.12 : 0.18) * opacityFactor),
          colorScheme.surface.withValues(
            alpha: (isDark ? 0.05 : 0.12) * opacityFactor,
          ),
        ],
      ),
      boxShadow: [
        if (elevation > 0)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15 + (elevation * 0.05)),
            blurRadius: blurSigma * 2,
            offset: Offset(0, 15 + (elevation * 5)),
            spreadRadius: -5,
          ),
      ],
    );
  }

  /// High-glow effect for nominal system states or active markers.
  static List<BoxShadow> technicalGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.4 * intensity),
        blurRadius: 12 * intensity,
        spreadRadius: 2 * intensity,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.2 * intensity),
        blurRadius: 24 * intensity,
        spreadRadius: 4 * intensity,
      ),
    ];
  }

  /// Returns the appropriate blur sigma for a given elevation.
  static double blurSigma(double elevation) => 15.0 + (elevation * 5.0);

  /// Subtle surface decoration: muted background, element radius, faint outline.
  static BoxDecoration minimalSurface(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
      borderRadius: ClawfreeBorderRadius.element,
      border: Border.all(
        color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
      ),
    );
  }

  /// Transparent pill-shaped TextButton style with JetBrainsMono w600.
  static ButtonStyle flatButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      backgroundColor: Colors.transparent,
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Pill-shaped container with tinted background.
  static Widget pill({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.25),
        borderRadius: ClawfreeBorderRadius.pill,
      ),
      child: child,
    );
  }

  /// Underline-only input decoration with focus highlight.
  static InputDecoration minimalInputDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ClawfreeSpacing.sm,
        vertical: ClawfreeSpacing.sm,
      ),
    );
  }

  /// HUD-style bracket wrapper: `[ LABEL child ]` in technical font.
  ///
  /// Used for coordinates, serial numbers, telemetry values.
  static Widget hudBrackets(
    BuildContext context, {
    required Widget child,
    String? label,
    Color? color,
    double fontSize = 10,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    final bracketStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: effectiveColor.withValues(alpha: 0.5),
    );
    final labelStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: effectiveColor.withValues(alpha: 0.7),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('[', style: bracketStyle),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(label.toUpperCase(), style: labelStyle),
          const SizedBox(width: 6),
        ] else
          const SizedBox(width: 4),
        child,
        const SizedBox(width: 4),
        Text(']', style: bracketStyle),
      ],
    );
  }
}
