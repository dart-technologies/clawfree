import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:latlong2/latlong.dart';

import '../theme.dart';

// ---------------------------------------------------------------------------
// A2UI Catalog registration
// ---------------------------------------------------------------------------

/// JSON Schema for the TripMap A2UI component.
final tripMapSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['TripMap']),
    'center': S.list(
      items: S.number(),
      description: 'Map center as [lat, lng].',
    ),
    'zoom': S.number(description: 'Initial zoom level (default 12).'),
    'markers': S.list(
      items: S.object(
        properties: {'lat': S.number(), 'lng': S.number(), 'label': S.string()},
        required: ['lat', 'lng', 'label'],
      ),
      description: 'Array of map markers with lat, lng, label.',
    ),
  },
  required: ['component', 'markers'],
);

/// Catalog-compatible builder.
Widget tripMapCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;

  // Parse center.
  final rawCenter = data['center'] as List?;
  final centerLat = (rawCenter != null && rawCenter.length >= 2)
      ? (rawCenter[0] as num).toDouble()
      : 35.68;
  final centerLng = (rawCenter != null && rawCenter.length >= 2)
      ? (rawCenter[1] as num).toDouble()
      : 139.76;

  final zoom = (data['zoom'] as num?)?.toDouble() ?? 12.0;

  // Parse markers.
  final rawMarkers = data['markers'] as List? ?? [];
  final markers = <MapMarker>[];
  for (final m in rawMarkers) {
    if (m is Map<String, Object?>) {
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      final label = m['label'] as String? ?? '';
      if (lat != null && lng != null) {
        markers.add(MapMarker(lat: lat, lng: lng, label: label));
      }
    }
  }

  return TripMapComponent(
    center: LatLng(centerLat, centerLng),
    zoom: zoom,
    markers: markers,
  );
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class MapMarker {
  const MapMarker({required this.lat, required this.lng, required this.label});
  final double lat;
  final double lng;
  final String label;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class TripMapComponent extends StatefulWidget {
  const TripMapComponent({
    super.key,
    required this.center,
    required this.zoom,
    required this.markers,
  });

  final LatLng center;
  final double zoom;
  final List<MapMarker> markers;

  @override
  State<TripMapComponent> createState() => _TripMapComponentState();
}

class _TripMapComponentState extends State<TripMapComponent> {
  final MapController _mapController = MapController();
  LatLng? _currentCenter;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapCamera camera, bool hasGesture) {
    if (mounted) {
      setState(() {
        _currentCenter = camera.center;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCenter = _currentCenter ?? widget.center;
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: ClawfreeBorderRadius.surface,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: widget.zoom,
                onPositionChanged: _onMapEvent,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.clawfree.app',
                ),
                MarkerLayer(
                  markers: widget.markers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    return Marker(
                      point: LatLng(m.lat, m.lng),
                      width: 120,
                      height: 60,
                      child: _StaggeredMarker(index: i, label: m.label),
                    );
                  }).toList(),
                ),
              ],
            ),
            // HUD coordinate overlay (top-left)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: ClawfreeBorderRadius.small,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LAT ${displayCenter.latitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    Text(
                      'LNG ${displayCenter.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Marker count overlay (top-right)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: ClawfreeBorderRadius.small,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${widget.markers.length} MARKERS',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredMarker extends StatefulWidget {
  const _StaggeredMarker({required this.index, required this.label});
  final int index;
  final String label;

  @override
  State<_StaggeredMarker> createState() => _StaggeredMarkerState();
}

class _StaggeredMarkerState extends State<_StaggeredMarker>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _sonarCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sonarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future.delayed(Duration(milliseconds: widget.index * 120), () {
      if (mounted) {
        _entranceCtrl.forward();
        // Start sonar pulse after entrance completes
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _sonarCtrl.repeat();
        });
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _sonarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, child) {
        return Opacity(
          opacity: _entranceCtrl.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.8 + (0.2 * _entranceCtrl.value),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MarkerChip(label: widget.label),
          // Sonar pulse rings below the chip
          SizedBox(
            width: 20,
            height: 14,
            child: AnimatedBuilder(
              animation: _sonarCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SonarPainter(
                    progress: _sonarCtrl.value,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A small labeled chip rendered at each marker position.
class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: ClawfreeBorderRadius.surface,
        boxShadow: ClawfreeTheme.technicalGlow(color, intensity: 0.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Concentric sonar pulse rings expanding outward.
class _SonarPainter extends CustomPainter {
  _SonarPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 0);
    for (var i = 0; i < 2; i++) {
      final p = ((progress + i * 0.5) % 1.0);
      final radius = 4 + p * 10;
      final alpha = (1.0 - p) * 0.4;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SonarPainter old) =>
      progress != old.progress || color != old.color;
}
