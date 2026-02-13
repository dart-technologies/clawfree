import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../spring_curve.dart';
import '../theme.dart';

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
    this.isSpeaking = false,
    this.interimTranscript = '',
    this.onTap,
    this.size = 120,
    this.accentColor,
  });

  final bool isListening;

  /// Whether TTS is currently speaking (drives speaking animation).
  final bool isSpeaking;
  final String interimTranscript;
  final VoidCallback? onTap;
  final double size;

  /// Optional accent color driven by session mode. Falls back to theme primary.
  final Color? accentColor;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _tapController;
  late final AnimationController _breatheController;

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
    // Subtle breathing animation for idle state
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    if (widget.isListening || widget.isSpeaking) {
      _controller.repeat(reverse: true);
    }
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/voice_blob.frag');
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
      _shaderTicker = createTicker((duration) {
        _elapsed = duration.inMilliseconds / 1000.0;
      })..start();
    } catch (_) {
      // No GPU (flutter test) — fall back to waveform painter.
    }
  }

  @override
  void didUpdateWidget(VoiceOrb old) {
    super.didUpdateWidget(old);
    final wasActive = old.isListening || old.isSpeaking;
    final isActive = widget.isListening || widget.isSpeaking;

    if (isActive && !wasActive) {
      _controller.repeat(reverse: true);
    } else if (!isActive && wasActive) {
      _controller.stop();
      _controller.reset();
    }

    // Haptic heartbeat only while listening (not speaking)
    if (widget.isListening && !old.isListening) {
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
        HapticFeedback.lightImpact();
      });
    } else if (!widget.isListening && old.isListening) {
      _hapticTimer?.cancel();
      _hapticTimer = null;
    }
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _controller.dispose();
    _tapController.dispose();
    _breatheController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = widget.isListening
        ? cs.error
        : widget.isSpeaking
            ? cs.tertiary
            : cs.primary;

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
              animation: Listenable.merge([_controller, _breatheController]),
              builder: (context, child) {
                final active = widget.isListening || widget.isSpeaking;
                final pulse = active ? _controller.value : 0.0;
                final breathe = _breatheController.value;
                // Apply spring easing to pulse rings
                const spring = SpringCurve(damping: 0.5, stiffness: 6.0);
                final springPulse = spring.transform(pulse.clamp(0.0, 1.0));

                // Idle breathing scale
                final idleScale = active ? 1.0 : 1.0 + 0.02 * breathe;

                return Transform.scale(
                  scale: idleScale,
                  child: SizedBox(
                    width: widget.size + 40,
                    height: widget.size + 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        if (active)
                          Container(
                            width: widget.size + 40 * springPulse,
                            height: widget.size + 40 * springPulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: baseColor
                                    .withValues(alpha: 0.3 - 0.3 * pulse),
                                width: 2,
                              ),
                            ),
                          ),
                        // Middle pulse ring
                        if (active)
                          Container(
                            width: widget.size + 20 * springPulse,
                            height: widget.size + 20 * springPulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: baseColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                          ),
                        // Inner subtle ring (3rd layer)
                        if (active)
                          Container(
                            width: widget.size + 8 * springPulse,
                            height: widget.size + 8 * springPulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: baseColor.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                          ),
                        // Wave bars around the orb (voice visualization)
                        if (active)
                          CustomPaint(
                            size: Size(widget.size + 30, widget.size + 30),
                            painter: _WaveBarsPainter(
                              color: baseColor.withValues(alpha: 0.4),
                              phase: _controller.value * 2 * math.pi,
                              barCount: 24,
                              radius: widget.size / 2 + 4,
                            ),
                          ),
                        // Shader blob or waveform fallback (when active)
                        if (active)
                          _shader != null
                              ? CustomPaint(
                                  size: Size(
                                      widget.size - 8, widget.size - 8),
                                  painter: _BlobShaderPainter(
                                    shader: _shader!,
                                    elapsed: _elapsed,
                                    amplitude: pulse,
                                    color: baseColor,
                                  ),
                                )
                              : CustomPaint(
                                  size: Size(
                                      widget.size - 8, widget.size - 8),
                                  painter: _WaveformPainter(
                                    color:
                                        baseColor.withValues(alpha: 0.3),
                                    phase:
                                        _controller.value * 2 * math.pi,
                                  ),
                                ),
                        // Glassmorphism frosted glass background
                        ClipOval(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: AnimatedContainer(
                              duration: ClawfreeTheme.durationMedium,
                              width: widget.size,
                              height: widget.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: baseColor.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Core orb (on top of glass)
                        AnimatedContainer(
                          duration: ClawfreeTheme.durationMedium,
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                baseColor.withValues(alpha: 0.2),
                                baseColor.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: baseColor.withValues(alpha: 0.6),
                              width: 2.5,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: baseColor.withValues(
                                          alpha: 0.15 + 0.05 * pulse),
                                      blurRadius: 40 + 10 * pulse,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: baseColor.withValues(
                                          alpha: 0.25 + 0.05 * pulse),
                                      blurRadius: 20 + 5 * pulse,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: baseColor.withValues(
                                          alpha: 0.35 + 0.05 * pulse),
                                      blurRadius: 8 + 3 * pulse,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : [
                                    // Subtle idle glow
                                    BoxShadow(
                                      color: baseColor.withValues(
                                          alpha: 0.06 + 0.04 * breathe),
                                      blurRadius: 20 + 5 * breathe,
                                      spreadRadius: 1,
                                    ),
                                  ],
                          ),
                          child: Icon(
                            widget.isListening
                                ? Icons.mic
                                : widget.isSpeaking
                                    ? Icons.volume_up
                                    : Icons.mic_none,
                            size: widget.size * 0.4,
                            color: baseColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.isListening
                ? (widget.interimTranscript.isNotEmpty
                    ? widget.interimTranscript
                    : 'Listening\u2026')
                : widget.isSpeaking
                    ? 'Speaking\u2026'
                    : 'Tap or say "Hey clawfree"',
            key: ValueKey(
                widget.isListening
                    ? widget.interimTranscript
                    : widget.isSpeaking
                        ? 'speaking'
                        : 'idle'),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle:
                  widget.isListening ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Draws radial wave bars around the orb for voice visualization.
class _WaveBarsPainter extends CustomPainter {
  _WaveBarsPainter({
    required this.color,
    required this.phase,
    required this.barCount,
    required this.radius,
  });

  final Color color;
  final double phase;
  final int barCount;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi;
      final barHeight =
          4.0 + 8.0 * ((math.sin(angle * 3 + phase) + 1) / 2);
      final startR = radius;
      final endR = radius + barHeight;
      final start = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final end = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveBarsPainter old) =>
      color != old.color || phase != old.phase;
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
      final distortion =
          math.sin(angle * frequency + phase) * amplitude;
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
  });

  final ui.FragmentShader shader;
  final double elapsed;
  final double amplitude;
  final Color color;

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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_BlobShaderPainter old) => true;
}
