import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_recorder_service.dart';

/// Callback with the recorded audio file path.
typedef OnAudioRecorded = void Function(String filePath);

/// Telegram-style press-to-talk button.
///
/// Long-press starts recording, release stops and sends.
/// Visual feedback: pulsing animation + color change while recording.
/// Works on all platforms (iOS, iPad, macOS, Web — except Web has no record).
class PressTalkButton extends StatefulWidget {
  const PressTalkButton({
    super.key,
    required this.recorder,
    required this.onRecorded,
    this.onRecordingStateChanged,
    this.enabled = true,
    this.size = 48,
  });

  final AudioRecorderService recorder;
  final OnAudioRecorded onRecorded;
  final ValueChanged<bool>? onRecordingStateChanged;
  final bool enabled;
  final double size;

  @override
  State<PressTalkButton> createState() => _PressTalkButtonState();
}

class _PressTalkButtonState extends State<PressTalkButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording || !widget.enabled) return;

    HapticFeedback.heavyImpact();
    final path = await widget.recorder.startRecording();
    if (path == null) return;

    setState(() => _isRecording = true);
    widget.onRecordingStateChanged?.call(true);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    HapticFeedback.lightImpact();
    _pulseController.stop();
    _pulseController.reset();

    final path = await widget.recorder.stopRecording();
    setState(() => _isRecording = false);
    widget.onRecordingStateChanged?.call(false);

    if (path != null) {
      widget.onRecorded(path);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;

    HapticFeedback.selectionClick();
    _pulseController.stop();
    _pulseController.reset();

    await widget.recorder.cancelRecording();
    setState(() => _isRecording = false);
    widget.onRecordingStateChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: _isRecording ? 'Release to send' : 'Hold to record',
      child: GestureDetector(
        onLongPressStart: (_) => _startRecording(),
        onLongPressEnd: (_) => _stopRecording(),
        onLongPressCancel: () => _cancelRecording(),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = _isRecording ? _pulseController.value : 0.0;
            final scale = 1.0 + 0.12 * pulse;

            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring when recording
                  if (_isRecording)
                    Container(
                      width: widget.size + 16,
                      height: widget.size + 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.3 * (1 - pulse)),
                          width: 2,
                        ),
                      ),
                    ),
                  // Waveform ring when recording
                  if (_isRecording)
                    CustomPaint(
                      size: Size(widget.size + 8, widget.size + 8),
                      painter: _MiniWaveformPainter(
                        color: cs.error.withValues(alpha: 0.4),
                        phase: pulse * 2 * math.pi,
                      ),
                    ),
                  // Core button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? cs.error
                          : widget.enabled
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: cs.error.withValues(alpha: 0.3),
                                blurRadius: 12 + 4 * pulse,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: widget.size * 0.5,
                      color: _isRecording
                          ? cs.onError
                          : widget.enabled
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Small waveform ring painter for the press-to-talk button.
class _MiniWaveformPainter extends CustomPainter {
  _MiniWaveformPainter({required this.color, required this.phase});

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
    const segments = 60;
    const frequency = 4.0;
    const amplitude = 3.0;

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
  bool shouldRepaint(_MiniWaveformPainter old) =>
      color != old.color || phase != old.phase;
}
