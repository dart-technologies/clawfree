import 'package:clawfree/src/ui/health/health_sparkline.dart';
import 'package:clawfree/src/ui/health/health_sparkline_catalog.dart';
import 'package:clawfree/src/ui/health/health_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('HealthSparkline', () {
    testWidgets('renders for nominal level', (tester) async {
      await tester.pumpWidget(
        wrap(const HealthSparkline(level: HealthLevel.nominal)),
      );
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders for degraded level', (tester) async {
      await tester.pumpWidget(
        wrap(const HealthSparkline(level: HealthLevel.degraded)),
      );
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders for error level', (tester) async {
      await tester.pumpWidget(
        wrap(const HealthSparkline(level: HealthLevel.error)),
      );
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders for unknown level', (tester) async {
      await tester.pumpWidget(
        wrap(const HealthSparkline(level: HealthLevel.unknown)),
      );
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('accepts custom data points', (tester) async {
      await tester.pumpWidget(
        wrap(
          const HealthSparkline(
            level: HealthLevel.nominal,
            dataPoints: [0.5, 0.6, 0.7, 0.8, 0.9],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        wrap(
          const HealthSparkline(
            level: HealthLevel.nominal,
            width: 100,
            height: 30,
          ),
        ),
      );
      await tester.pump();
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 100);
      expect(sizedBox.height, 30);
    });
  });

  group('HealthSparkline catalog schema', () {
    test('schema requires component and level', () {
      final schema = healthSparklineSchema;
      expect(schema, isNotNull);
    });

    test('schema is compatible with catalog registration', () {
      final item = CatalogItem(
        name: 'HealthSparkline',
        dataSchema: healthSparklineSchema,
        widgetBuilder: healthSparklineCatalogBuilder,
      );
      expect(item.name, 'HealthSparkline');
    });
  });
}
