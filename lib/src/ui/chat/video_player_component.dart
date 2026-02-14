import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme.dart';
import '../spring_curve.dart';
import 'video_player_native_stub.dart'
    if (dart.library.io) 'video_player_native.dart'
    as native_player;

// ---------------------------------------------------------------------------
// A2UI Catalog registration
// ---------------------------------------------------------------------------

/// JSON Schema for the VideoPlayer A2UI component.
final videoPlayerSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['VideoPlayer']),
    'tripId': S.string(
      description:
          'Trip identifier. If provided, triggers self-generation of the preview video.',
    ),
    'filePath': S.string(
      description: 'Direct path to an .mp4 file for playback.',
    ),
  },
  required: ['component'],
);

/// Catalog-compatible builder.
Widget videoPlayerCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final tripId = data['tripId'] as String?;
  final filePath = data['filePath'] as String?;
  return VideoPlayerComponent(tripId: tripId, filePath: filePath);
}

// ---------------------------------------------------------------------------
// Slide data (shared between slideshow fallback and FFmpeg text overlays)
// ---------------------------------------------------------------------------

class SlideData {
  const SlideData(this.url, this.line1, [this.line2 = '']);
  final String url;
  final String line1;
  final String line2;
}

const slides = <SlideData>[
  SlideData(
    'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=1280&h=720&fit=crop&auto=format',
    'Tokyo',
    '3 Day Foodie Adventure',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1280&h=720&fit=crop&auto=format',
    'Day 1 \u2014 Tsukiji & Ginza',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=1280&h=720&fit=crop&auto=format',
    'Sushi Dai',
    'Arrive 5:30 AM',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=1280&h=720&fit=crop&auto=format',
    'Ramen Street',
    'Rokurinsha',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=1280&h=720&fit=crop&auto=format',
    'Day 2 \u2014 Shinjuku & Golden Gai',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=1280&h=720&fit=crop&auto=format',
    'Shinjuku Gyoen',
    'Matcha Tea',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1554797589-7241bb691973?w=1280&h=720&fit=crop&auto=format',
    'Golden Gai',
    '6 Bars, 6 Sake',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1580442151529-343f2f6e0e27?w=1280&h=720&fit=crop&auto=format',
    'Day 3 \u2014 Toyosu & Asakusa',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1523539693385-e5e891eb4465?w=1280&h=720&fit=crop&auto=format',
    'Toyosu',
    'Tuna Auction Deck',
  ),
  SlideData(
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1280&h=720&fit=crop&auto=format',
    'Narisawa',
    "#12 World\u2019s 50 Best",
  ),
];

// ---------------------------------------------------------------------------
// Top-level widget: delegates to native video or web slideshow
// ---------------------------------------------------------------------------

class VideoPlayerComponent extends StatelessWidget {
  const VideoPlayerComponent({super.key, this.tripId, this.filePath});

  final String? tripId;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const _SlideshowPlayer();
    }
    return native_player.NativeVideoPlayer(tripId: tripId, filePath: filePath);
  }
}

// ---------------------------------------------------------------------------
// Web fallback: pure-Flutter animated slideshow
// ---------------------------------------------------------------------------

class _SlideshowPlayer extends StatefulWidget {
  const _SlideshowPlayer();

  @override
  State<_SlideshowPlayer> createState() => _SlideshowPlayerState();
}

class _SlideshowPlayerState extends State<_SlideshowPlayer>
    with TickerProviderStateMixin {
  int _current = 0;
  Timer? _timer;
  late final AnimationController _zoomCtrl;
  late final Animation<double> _zoom;
  bool _paused = false;

  static const _slideDuration = Duration(milliseconds: 4000);
  static const _fadeDuration = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _zoomCtrl = AnimationController(vsync: this, duration: _slideDuration);
    _zoom = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(
        parent: _zoomCtrl,
        curve: const SpringCurve(damping: 0.8),
      ),
    );
    _zoomCtrl.forward();
    _timer = Timer.periodic(_slideDuration, (_) => _advance());
  }

  void _advance() {
    if (!mounted || _paused) return;
    setState(() => _current = (_current + 1) % slides.length);
    _zoomCtrl.forward(from: 0);
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _timer?.cancel();
        _timer = null;
      } else {
        _timer = Timer.periodic(_slideDuration, (_) => _advance());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _zoomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[_current];
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: ClawfreeBorderRadius.surface,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: _fadeDuration,
                child: _KenBurnsImage(
                  key: ValueKey(_current),
                  url: slide.url,
                  zoom: _zoom,
                ),
              ),
              // Glass text overlay
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: ClawfreeTheme.glassDecoration(
                    context,
                    elevation: 2,
                    borderRadius: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slide.line1.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (slide.line2.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          slide.line2,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Glass play/pause button
              Positioned(
                right: 16,
                top: 16,
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: ClawfreeTheme.glassDecoration(
                      context,
                      isPill: true,
                      elevation: 1,
                    ),
                    child: Icon(
                      _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Technical progress dots
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: active ? 20 : 6,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: active
                            ? ClawfreeTheme.technicalGlow(
                                Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single slide image with animated Ken Burns zoom.
class _KenBurnsImage extends StatelessWidget {
  const _KenBurnsImage({super.key, required this.url, required this.zoom});

  final String url;
  final Animation<double> zoom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: zoom,
      builder: (context, child) {
        return Transform.scale(scale: zoom.value, child: child);
      },
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              Center(
                child: Text(
                  'SCANNING...',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          );
        },
        errorBuilder: (context, error, stack) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white24, size: 48),
          );
        },
      ),
    );
  }
}
