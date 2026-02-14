import 'package:clawfree/src/ui/chat/chat_surface_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ShimmerSkeleton', () {
    testWidgets('renders text type by default', (tester) async {
      await tester.pumpWidget(wrap(const ShimmerSkeleton()));
      await tester.pump(const Duration(milliseconds: 100));
      // Default is text layout: should find Column + multiple Container bones
      expect(find.byType(ShimmerSkeleton), findsOneWidget);
    });

    testWidgets('renders form type', (tester) async {
      await tester.pumpWidget(
        wrap(const ShimmerSkeleton(type: SkeletonType.form)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ShimmerSkeleton), findsOneWidget);
      // Form has an Align for the button
      expect(find.byType(Align), findsWidgets);
    });

    testWidgets('renders table type', (tester) async {
      await tester.pumpWidget(
        wrap(const ShimmerSkeleton(type: SkeletonType.table)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ShimmerSkeleton), findsOneWidget);
      // Table has Divider
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders card type', (tester) async {
      await tester.pumpWidget(
        wrap(const ShimmerSkeleton(type: SkeletonType.card)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ShimmerSkeleton), findsOneWidget);
    });

    testWidgets('SkeletonType enum has four values', (tester) async {
      expect(SkeletonType.values.length, 4);
      expect(
        SkeletonType.values,
        containsAll([
          SkeletonType.text,
          SkeletonType.form,
          SkeletonType.table,
          SkeletonType.card,
        ]),
      );
    });
  });
}
