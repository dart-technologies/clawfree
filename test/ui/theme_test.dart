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
      expect(appBarBg, Colors.transparent);
    });

    test('light theme appBar has correct foreground color', () {
      final theme = ClawfreeTheme.light;
      expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onSurface);
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
      expect(outlineBorder.borderRadius, BorderRadius.circular(20));
      debugDefaultTargetPlatformOverride = null;
    });

    // -----------------------------------------------------------------------
    // Text theme
    // -----------------------------------------------------------------------

    test('text theme uses JetBrains Mono font', () {
      final theme = ClawfreeTheme.light;
      expect(theme.textTheme.headlineLarge?.fontFamily, 'JetBrainsMono');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'JetBrainsMono');
    });

    test('text theme has correct font weights', () {
      final theme = ClawfreeTheme.light;
      expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w800);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
    });

    test('dark theme text theme has correct font weights', () {
      final theme = ClawfreeTheme.dark;
      expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w800);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
    });

    test('text theme colors are set from colorScheme', () {
      final theme = ClawfreeTheme.light;
      final onSurface = theme.colorScheme.onSurface;
      expect(theme.textTheme.headlineLarge?.color, onSurface);
      expect(theme.textTheme.titleLarge?.color, onSurface);
      expect(theme.textTheme.bodyLarge?.color, onSurface);
    });

    // -----------------------------------------------------------------------
    // HUD Brackets
    // -----------------------------------------------------------------------

    testWidgets('hudBrackets renders brackets and child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  ClawfreeTheme.hudBrackets(context, child: const Text('42.0')),
            ),
          ),
        ),
      );

      expect(find.text('['), findsOneWidget);
      expect(find.text(']'), findsOneWidget);
      expect(find.text('42.0'), findsOneWidget);
    });

    testWidgets('hudBrackets renders label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ClawfreeTheme.hudBrackets(
                context,
                label: 'lat',
                child: const Text('35.68'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('['), findsOneWidget);
      expect(find.text(']'), findsOneWidget);
      expect(find.text('LAT'), findsOneWidget);
      expect(find.text('35.68'), findsOneWidget);
    });

    testWidgets('hudBrackets wraps in a Row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  ClawfreeTheme.hudBrackets(context, child: const Text('val')),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    // -----------------------------------------------------------------
    // New theme utility methods
    // -----------------------------------------------------------------

    testWidgets('minimalSurface returns BoxDecoration with element radius', (
      tester,
    ) async {
      late BoxDecoration decoration;
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                decoration = ClawfreeTheme.minimalSurface(context);
                return Container(decoration: decoration);
              },
            ),
          ),
        ),
      );

      expect(decoration.borderRadius, ClawfreeBorderRadius.element);
      expect(decoration.border, isNotNull);
    });

    testWidgets('flatButtonStyle returns a ButtonStyle with pill shape', (
      tester,
    ) async {
      late ButtonStyle style;
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                style = ClawfreeTheme.flatButtonStyle(context);
                return TextButton(
                  onPressed: () {},
                  style: style,
                  child: const Text('btn'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('btn'), findsOneWidget);
      expect(style.backgroundColor?.resolve({}), Colors.transparent);
    });

    testWidgets('pill wraps child in pill-shaped container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: ClawfreeTheme.pill(child: const Text('tag')),
          ),
        ),
      );

      expect(find.text('tag'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, ClawfreeBorderRadius.pill);
    });

    testWidgets('minimalInputDecoration returns underline-style input', (
      tester,
    ) async {
      late InputDecoration decoration;
      await tester.pumpWidget(
        MaterialApp(
          theme: ClawfreeTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                decoration = ClawfreeTheme.minimalInputDecoration(context);
                return TextField(decoration: decoration);
              },
            ),
          ),
        ),
      );

      expect(decoration.filled, isFalse);
      expect(decoration.border, isA<UnderlineInputBorder>());
      expect(decoration.focusedBorder, isA<UnderlineInputBorder>());
    });
  });
}
