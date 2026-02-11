import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/src/ui/theme.dart';

void main() {
  group('ClawfreeTheme', () {
    // -----------------------------------------------------------------------
    // Basic theme creation
    // -----------------------------------------------------------------------

    test('light theme returns a ThemeData', () {
      final theme = ClawfreeTheme.light;
      expect(theme, isA<ThemeData>());
    });

    test('dark theme returns a ThemeData', () {
      final theme = ClawfreeTheme.dark;
      expect(theme, isA<ThemeData>());
    });

    test('isApple returns a bool', () {
      expect(ClawfreeTheme.isApple, isA<bool>());
    });

    test('isApple is true on macOS platform', () {
      // In Flutter test runner, defaultTargetPlatform is android by default.
      // Override to macOS to verify the Apple branch.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(ClawfreeTheme.isApple, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    test('isApple is false on android platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(ClawfreeTheme.isApple, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });

    // -----------------------------------------------------------------------
    // Light theme
    // -----------------------------------------------------------------------

    test('light theme has light brightness', () {
      final theme = ClawfreeTheme.light;
      expect(theme.brightness, Brightness.light);
    });

    test('light theme has primary color in appBarTheme', () {
      final theme = ClawfreeTheme.light;
      final appBarBg = theme.appBarTheme.backgroundColor;
      expect(appBarBg, isNotNull);
      // The primary color is Color(0xFF0066CC), possibly with alpha on Apple
      expect(appBarBg!.r, closeTo(0.0, 0.02));
      expect(appBarBg.g, closeTo(0.4, 0.05));
      expect(appBarBg.b, closeTo(0.8, 0.05));
    });

    test('light theme appBar has white foreground color', () {
      final theme = ClawfreeTheme.light;
      expect(theme.appBarTheme.foregroundColor, Colors.white);
    });

    test('light theme appBar has zero elevation', () {
      final theme = ClawfreeTheme.light;
      expect(theme.appBarTheme.elevation, 0);
    });

    // -----------------------------------------------------------------------
    // Dark theme
    // -----------------------------------------------------------------------

    test('dark theme has dark brightness', () {
      final theme = ClawfreeTheme.dark;
      expect(theme.brightness, Brightness.dark);
    });

    test('dark theme exists and is distinct from light', () {
      final light = ClawfreeTheme.light;
      final dark = ClawfreeTheme.dark;
      expect(light.brightness, isNot(equals(dark.brightness)));
    });

    // -----------------------------------------------------------------------
    // Platform-adaptive: Apple-specific features
    // -----------------------------------------------------------------------

    test('light theme on Apple has surfaceTintColor transparent', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final theme = ClawfreeTheme.light;
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      debugDefaultTargetPlatformOverride = null;
    });

    test('light theme on Apple has inputDecorationTheme filled', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final theme = ClawfreeTheme.light;
      expect(theme.inputDecorationTheme.filled, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    test('light theme on Apple has cardTheme with zero elevation', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final theme = ClawfreeTheme.light;
      expect(theme.cardTheme.elevation, 0);
      debugDefaultTargetPlatformOverride = null;
    });

    test('light theme on Apple has rounded card shape', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final theme = ClawfreeTheme.light;
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      debugDefaultTargetPlatformOverride = null;
    });

    test('light theme on Apple has rounded inputDecoration borders', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final theme = ClawfreeTheme.light;
      final border = theme.inputDecorationTheme.border;
      expect(border, isA<OutlineInputBorder>());
      final outlineBorder = border as OutlineInputBorder;
      expect(outlineBorder.borderRadius, BorderRadius.circular(12));
      debugDefaultTargetPlatformOverride = null;
    });

    // -----------------------------------------------------------------------
    // Text theme
    // -----------------------------------------------------------------------

    test('text theme has correct font weights', () {
      final theme = ClawfreeTheme.light;
      expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
    });

    test('dark theme text theme has correct font weights', () {
      final theme = ClawfreeTheme.dark;
      expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
    });

    test('text theme colors are set from colorScheme', () {
      final theme = ClawfreeTheme.light;
      final onSurface = theme.colorScheme.onSurface;
      expect(theme.textTheme.headlineLarge?.color, onSurface);
      expect(theme.textTheme.titleLarge?.color, onSurface);
      expect(theme.textTheme.bodyLarge?.color, onSurface);
    });
  });
}
