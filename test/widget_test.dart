import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawfree/main.dart';

void main() {
  group('ClawfreeApp', () {
    testWidgets('App launches with icon and API key screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      // App bar or title
      expect(find.text('clawfree'), findsOneWidget);

      // API key field (on non-web)
      expect(find.text('Anthropic API Key'), findsOneWidget);

      // Start button
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('empty key shows snackbar on non-web',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      // Tap start without key
      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(
        find.text('Please enter your Anthropic API key'),
        findsOneWidget,
      );
    });

    testWidgets('theme uses Material 3', (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('demo mode toggle is visible', (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      expect(find.text('Demo mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggling demo mode hides API key field',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ClawfreeApp());

      // Initially, API key field should be visible
      expect(find.text('Anthropic API Key'), findsOneWidget);

      // Toggle demo mode on
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // API key field should be hidden
      expect(find.text('Anthropic API Key'), findsNothing);

      // Demo mode banner should appear
      expect(find.textContaining('Demo mode: using cached responses'),
          findsOneWidget);

      // Start button should say "Start Demo"
      expect(find.text('Start Demo'), findsOneWidget);
    });

    testWidgets('demo mode starts without API key',
        (WidgetTester tester) async {
      // Use phone-width viewport so ChatScreen renders the phone layout
      // without overflow in the tablet split view.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ClawfreeApp());

      // Toggle demo mode on
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Tap start — triggers Navigator.push with route transition
      await tester.tap(find.text('Start Demo'));
      await tester.pumpAndSettle();

      // Should transition to chat screen
      expect(find.text('Say or type something to get started'), findsOneWidget);
    });
  });
}
