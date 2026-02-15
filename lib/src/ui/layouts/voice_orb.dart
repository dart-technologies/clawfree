import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../clawfree_icons.dart';
import '../theme.dart';
import '../spring_curve.dart';

/// Visual state mood for the VoiceOrb.
enum OrbMood { idle, thinking, listening, speaking, success, error }

/// Large pulsing voice visualizer for the phone "Mobile Remote" layout.
///
/// Idle: solid circle with mic icon.
/// Listening: pulsing rings radiating outward with glow bloom + waveform.
/// Shows interim transcript text below.
///
/// When a GPU is available, renders an organic metaball shader blob instead of
/// the simple waveform ring. Falls back to [_WaveformPainter] when the shader
/// cannot be loaded (e.g. `flutter test` has no GPU).
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.isListening,
    this.interimTranscript = '',
    this.onTap,
    this.size = 120,
    this.accentColor,
    this.mood = OrbMood.idle,
    this.showTranscript = true,
  });

  final bool isListening;
  final String interimTranscript;
  final VoidCallback? onTap;
  final double size;
  final OrbMood mood;
  final bool showTranscript;

  /// Optional accent color driven by session mode. Falls back to theme primary.
  final Color? accentColor;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _tapController;
  late final AnimationController _moodController;

  // Haptic heartbeat during listening
  Timer? _hapticTimer;

  // Shader support
  ui.FragmentShader? _shader;
  Ticker? _shaderTicker;
  double _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _moodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    bool isTest = false;
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        isTest = true;
      }
    } catch (_) {}

    if (widget.isListening && !isTest) _controller.repeat(reverse: true);
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/voice_blob.frag',
      );
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());

      bool isTest = false;
      try {
        if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
          isTest = true;
        }
      } catch (_) {}

      if (!isTest) {
        _shaderTicker = createTicker((duration) {
          _elapsed = duration.inMilliseconds / 1000.0;

          // Dynamic haptic pulse synced with visual amplitude
          if (widget.isListening && _elapsed % 0.75 < 0.016) {
            HapticFeedback.lightImpact();
          }
        })
          ..start();
      }
    } catch (_) {
      // No GPU (flutter test) — fall back to waveform painter.
    }
  }

  @override
  void didUpdateWidget(VoiceOrb old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && old.isListening) {
      _controller.stop();
      _controller.reset();
    }

    if (widget.mood != old.mood) {
      _moodController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _controller.dispose();
    _tapController.dispose();
    _moodController.dispose();
    _shaderTicker?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _tapController.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    _tapController.forward();
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _tapController.forward();
  }

  double _moodValue(OrbMood mood) {
    return switch (mood) {
      OrbMood.idle => 0.0,
      OrbMood.thinking => 1.0,
      OrbMood.listening => 2.0,
      OrbMood.speaking => 3.0,
      OrbMood.success => 5.0,
      OrbMood.error => 4.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final targetColor = switch (widget.mood) {
      OrbMood.error => cs.error,
      OrbMood.thinking => cs.tertiary,
      OrbMood.speaking => cs.secondary,
      OrbMood.success => ClawfreeTheme.success,
      _ => widget.accentColor ?? cs.primary,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: ScaleTransition(
            scale: _tapController,
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _moodController]),
              builder: (context, child) {
                final pulse = widget.isListening ? _controller.value : 0.0;
                // Apply spring easing to pulse rings
                const spring = SpringCurve(damping: 0.5, stiffness: 6.0);
                final springPulse = spring.transform(pulse.clamp(0.0, 1.0));

                final moodVal = _moodValue(widget.mood);

                return SizedBox(
                  width: widget.size + 40,
                  height: widget.size + 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      if (widget.isListening)
                        Container(
                          width: widget.size + 40 * springPulse,
                          height: widget.size + 40 * springPulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: targetColor.withValues(
                                alpha: 0.3 - 0.3 * pulse,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      // Middle pulse ring
                      if (widget.isListening)
                        Container(
                          width: widget.size + 20 * springPulse,
                          height: widget.size + 20 * springPulse,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: targetColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                        ),
                      // Shader blob or waveform fallback (only when listening)
                      if (widget.isListening ||
                          widget.mood == OrbMood.thinking ||
                          widget.mood == OrbMood.success)
                        _shader != null
                            ? CustomPaint(
                                size: Size(widget.size - 8, widget.size - 8),
                                painter: _BlobShaderPainter(
                                  shader: _shader!,
                                  elapsed: _elapsed,
                                  amplitude: pulse,
                                  color: targetColor,
                                  mood: moodVal,
                                ),
                              )
                            : CustomPaint(
                                size: Size(widget.size - 8, widget.size - 8),
                                painter: _WaveformPainter(
                                  color: targetColor.withValues(alpha: 0.3),
                                  phase: _controller.value * 2 * math.pi,
                                ),
                              ),
                      // Core orb
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: targetColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: targetColor.withValues(alpha: 0.6),
                            width: 2.5,
                          ),
                          boxShadow: widget.mood == OrbMood.success
                              ? [
                                  BoxShadow(
                                    color: targetColor.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: targetColor.withValues(alpha: 0.2),
                                    blurRadius: 60,
                                    spreadRadius: 8,
                                  ),
                                ]
                              : widget.isListening
                              ? [
                                  // Triple-layered glow bloom
                                  BoxShadow(
                                    color: targetColor.withValues(
                                      alpha: 0.15 + 0.05 * pulse,
                                    ),
                                    blurRadius: 40 + 10 * pulse,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: targetColor.withValues(
                                      alpha: 0.25 + 0.05 * pulse,
                                    ),
                                    blurRadius: 20 + 5 * pulse,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: targetColor.withValues(
                                      alpha: 0.35 + 0.05 * pulse,
                                    ),
                                    blurRadius: 8 + 3 * pulse,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            widget.mood == OrbMood.success
                                ? ClawfreeIcons.success
                                : (widget.isListening
                                      ? ClawfreeIcons.mic
                                      : ClawfreeIcons.micNone),
                            key: ValueKey(widget.mood == OrbMood.success),
                            size: widget.size * 0.4,
                            color: targetColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.showTranscript) ...[
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.isListening
                  ? (widget.interimTranscript.isNotEmpty
                      ? widget.interimTranscript
                      : 'Listening\u2026')
                  : widget.mood == OrbMood.success
                      ? 'Done \u2714'
                      : (widget.mood == OrbMood.thinking
                          ? 'Thinking\u2026'
                          : 'Tap or say "Hey clawfree"'),
              key: ValueKey(
                widget.isListening ? widget.interimTranscript : widget.mood,
              ),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: widget.isListening
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws a sine-distorted circle as an inner waveform ring.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.color, required this.phase});

  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const segments = 120;
    const frequency = 6.0;
    const amplitude = 4.0;

    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final distortion = math.sin(angle * frequency + phase) * amplitude;
      final r = radius + distortion;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      color != old.color || phase != old.phase;
}

/// Renders the metaball fragment shader as a custom painter.
class _BlobShaderPainter extends CustomPainter {
  _BlobShaderPainter({
    required this.shader,
    required this.elapsed,
    required this.amplitude,
    required this.color,
    required this.mood,
  });

  final ui.FragmentShader shader;
  final double elapsed;
  final double amplitude;
  final Color color;
  final double mood;

  @override
  void paint(Canvas canvas, Size size) {
    // uResolution (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uTime (float)
    shader.setFloat(2, elapsed);
    // uAmplitude (float)
    shader.setFloat(3, amplitude);
    // uColor (vec3)
    shader.setFloat(4, color.r);
    shader.setFloat(5, color.g);
    shader.setFloat(6, color.b);
    // uMood (float)
    shader.setFloat(7, mood);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_BlobShaderPainter old) => true;
}
