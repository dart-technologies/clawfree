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
    
    // Enhanced Technical HUD Filter: Preserves road contrast while biasing towards deep blue/cyan
    const mapFilter = ColorFilter.matrix([
      0.1, 0.1, 0.1, 0, 0,   // Red: Minimal
      0.1, 0.5, 0.1, 0, 20,  // Green: Moderate glow
      0.2, 0.2, 0.8, 0, 50,  // Blue: Strong HUD bias
      0, 0, 0, 1, 0,         // Alpha
    ]);

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: ClawfreeTheme.scaffoldBlack,
          borderRadius: ClawfreeBorderRadius.element,
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: ClawfreeBorderRadius.element,
          child: Stack(
            children: [
              Opacity(
                opacity: 0.9,
                child: ColorFiltered(
                  colorFilter: mapFilter,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: widget.center,
                      initialZoom: widget.zoom,
                      onPositionChanged: _onMapEvent,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag |
                            InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      TileLayer(
                        // Switch to CartoDB Dark Matter for native high-visibility roads and labels
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.clawfree.app',
                      ),
                      MarkerLayer(
                        markers: widget.markers.asMap().entries.map((entry) {
                          final i = entry.key;
                          final m = entry.value;
                          return Marker(
                            point: LatLng(m.lat, m.lng),
                            width: 140,
                            height: 70,
                            child: _StaggeredMarker(index: i, label: m.label),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tactical HUD: Grid / Scanlines Overlay
              const Positioned.fill(child: _TacticalOverlay()),

              // HUD coordinate overlay (top-left)
              Positioned(
                left: 12,
                top: 12,
                child: _HudPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'COORD LAT ${displayCenter.latitude.toStringAsFixed(4)}',
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'COORD LNG ${displayCenter.longitude.toStringAsFixed(4)}',
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Marker count overlay (top-right)
              Positioned(
                right: 12,
                top: 12,
                child: _HudPanel(
                  child: Text(
                    '${widget.markers.length} DESTINATIONS MAPPED',
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),

              // Legend / Status (bottom-left)
              Positioned(
                left: 12,
                bottom: 12,
                child: _HudPanel(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ClawfreeTheme.hudActive,
                          shape: BoxShape.circle,
                          boxShadow: [ClawfreeTheme.technicalGlow(ClawfreeTheme.hudActive, intensity: 0.5)[0]],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE ITINERARY FEED',
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: ClawfreeTheme.hudTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudPanel extends StatelessWidget {
  const _HudPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ClawfreeTheme.hudOverlayColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _TacticalOverlay extends StatelessWidget {
  const _TacticalOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _TacticalPainter(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

class _TacticalPainter extends CustomPainter {
  _TacticalPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Draw Grid
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Corner Accents
    final accentPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1.5;
    const l = 15.0;
    
    // Top-left
    canvas.drawLine(Offset.zero, const Offset(l, 0), accentPaint);
    canvas.drawLine(Offset.zero, const Offset(0, l), accentPaint);
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - l, 0), accentPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), accentPaint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), accentPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - l), accentPaint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - l, size.height), accentPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - l), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          child: Transform.translate(
            offset: Offset(0, -20 * (1.0 - _entranceCtrl.value)),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MarkerChip(label: widget.label),
          SizedBox(
            width: 30,
            height: 20,
            child: AnimatedBuilder(
              animation: _sonarCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SonarPainter(
                    progress: _sonarCtrl.value,
                    color: Theme.of(context).colorScheme.primary,
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

class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9), // Deep black for text contrast
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: ClawfreeTheme.technicalGlow(cs.primary, intensity: 0.4),
      ),
      child: Text(
        label.toUpperCase(),
        style: ClawfreeTheme.technicalStyle(
          context: context,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: cs.primary, // Glow-matched text color
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SonarPainter extends CustomPainter {
  _SonarPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 0);
    for (var i = 0; i < 2; i++) {
      final p = ((progress + i * 0.5) % 1.0);
      final radius = 2 + p * 15;
      final alpha = (1.0 - p) * 0.5;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
    // Fixed center point
    canvas.drawCircle(center, 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SonarPainter old) =>
      progress != old.progress || color != old.color;
}
