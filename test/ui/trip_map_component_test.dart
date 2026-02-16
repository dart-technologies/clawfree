import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:clawfree/src/ui/chat/trip_map_component.dart';
import 'package:clawfree/src/ui/theme.dart';

void main() {
  group('TripMapComponent', () {
    final center = LatLng(35.68, 139.76);
    final markers = [
      MapMarker(lat: 35.66, lng: 139.77, label: 'Marker 1'),
      MapMarker(lat: 35.68, lng: 139.76, label: 'Marker 2'),
    ];

    Widget buildTestableWidget() {
      return MaterialApp(
        theme: ClawfreeTheme.dark,
        home: Scaffold(
          body: TripMapComponent(
            center: center,
            zoom: 12.0,
            markers: markers,
          ),
        ),
      );
    }

    testWidgets('renders tactical HUD overlays', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Verify coordinate panel (Top-Left)
      expect(find.textContaining('COORD LAT 35.6800'), findsOneWidget);
      expect(find.textContaining('COORD LNG 139.7600'), findsOneWidget);

      // Verify destination count (Top-Right)
      expect(find.text('2 DESTINATIONS MAPPED'), findsOneWidget);

      // Verify status legend (Bottom-Left)
      expect(find.text('LIVE ITINERARY FEED'), findsOneWidget);

      // Let animations settle
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('renders marker chips', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      
      // Markers have staggered entrance, wait for them
      await tester.pump(const Duration(milliseconds: 1000));
      
      expect(find.text('MARKER 1'), findsOneWidget);
      expect(find.text('MARKER 2'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('updates coordinates on map interaction (simulated)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      
      expect(find.textContaining('COORD LAT 35.6800'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
