import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:clawfree/src/ui/chat/responsive_container.dart';
import 'package:clawfree/src/ui/chat/chat_surface_view.dart';

class MockCatalogItemContext extends Fake implements CatalogItemContext {
  MockCatalogItemContext({required this.data});

  @override
  final Object data;

  @override
  ChildBuilderCallback get buildChild => (String id, [DataContext? dataContext]) {
        return Text('Child: $id');
      };

  @override
  DataContext get dataContext => MockDataContext();
}

class MockDataContext extends Fake implements DataContext {}

void main() {
  group('ResponsiveContainer', () {
    testWidgets('renders children in columns on wide screen', (WidgetTester tester) async {
      final context = MockCatalogItemContext(data: {
        'children': ['1', '2'],
        'columns': 2,
        'spacing': 10.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                child: ResponsiveContainer(itemContext: context),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child: 1'), findsOneWidget);
      expect(find.text('Child: 2'), findsOneWidget);

      // Wrap should be used for columns > 1
      expect(find.byType(Wrap), findsOneWidget);

      // Wait for stagger timers (0ms, 80ms)
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders children in a column on narrow screen', (WidgetTester tester) async {
      final context = MockCatalogItemContext(data: {
        'children': ['1', '2'],
        'columns': 2,
        'mobileColumns': 1,
        'spacing': 10.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: ResponsiveContainer(itemContext: context),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child: 1'), findsOneWidget);
      expect(find.text('Child: 2'), findsOneWidget);

      // Column should be used for activeColumns == 1
      expect(find.byType(Column), findsOneWidget);

      // Wait for stagger timers
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders skeleton when children are empty', (WidgetTester tester) async {
      final context = MockCatalogItemContext(data: {
        'children': [],
        'skeleton': 'card',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(itemContext: context),
          ),
        ),
      );

      // ShimmerSkeleton should be rendered
      expect(find.byType(ShimmerSkeleton), findsOneWidget);
    });
  });
}
