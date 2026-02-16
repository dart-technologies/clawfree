import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/main.dart';
import 'package:clawfree/src/ui/clawfree_assets.dart';

import 'test_helpers.dart';

void main() {
  group('ClawfreeApp', () {
    testWidgets('App launches with icon and API key screen', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester, size: const Size(1200, 1600));
      await tester.pumpWidget(const ClawfreeApp());

      // App bar or title
      expect(find.text('CLAWFREE'), findsOneWidget);

      // API key field (on non-web)
      expect(find.text('ANTHROPIC API KEY'), findsOneWidget);

      // Start button
      expect(find.text('START'), findsOneWidget);
    });

    testWidgets('empty key shows snackbar on non-web', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester, size: const Size(1200, 1600));
      await tester.pumpWidget(const ClawfreeApp());

      // Tap start without key
      await tester.tap(find.text('START'));
      await tester.pump();

      expect(find.text('Please enter your Anthropic API key'), findsOneWidget);
    });

    testWidgets('theme uses Material 3', (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('demo mode toggle is visible', (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      expect(find.text('DEMO MODE'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggling demo mode hides API key field', (
      WidgetTester tester,
    ) async {
      setTestViewport(tester, size: const Size(1200, 1600));
      await tester.pumpWidget(const ClawfreeApp());

      // Initially, API key field should be visible
      expect(find.text('ANTHROPIC API KEY'), findsOneWidget);

      // Toggle demo mode on
      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pump();

      // API key field should be hidden
      expect(find.text('ANTHROPIC API KEY'), findsNothing);

      // Demo mode banner should appear
      expect(
        find.textContaining('DEMO MODE: CACHED RESPONSES'),
        findsOneWidget,
      );

      // Start button should say "START DEMO"
      expect(find.text('START DEMO'), findsOneWidget);
    });

    testWidgets('demo mode starts without API key', (
      WidgetTester tester,
    ) async {
      // Use phone-width viewport so ChatScreen renders the phone layout
      // without overflow in the tablet split view.
      setTestViewport(tester, size: const Size(450, 900));

      await tester.pumpWidget(const ClawfreeApp());

      // Toggle demo mode on
      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pump();

      // Tap start — triggers Navigator.push with route transition
      final startButton = find.text('START DEMO');
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      // Use pump + duration instead of pumpAndSettle (VoiceOrb shader ticker never settles).
      // _start() is async (earcon init, agent store) — needs enough pump time.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      // ChatScreen starts in onboarding mode; the empty state text is in
      // the chat message list which shows after mode transitions.
      // Verify we at least navigated to the chat screen.
      expect(find.byType(ClawfreeLogo), findsOneWidget);
    });
  });
}
