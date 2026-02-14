import 'package:flutter/material.dart';

/// A small animated dot that pulses between 30% and 100% opacity
/// with a subtle glow effect for connected state.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.3 + 0.7 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 * t),
                blurRadius: 6 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
