import 'package:flutter/material.dart';

/// Centralized asset path constants.
abstract final class ClawfreeAssets {
  static const icon = 'assets/icon.png';
}

/// A standardized brand logo widget with a premium proportional "squircle" radius
/// and a subtle breathing animation.
class ClawfreeLogo extends StatefulWidget {
  const ClawfreeLogo({super.key, required this.size});

  final double size;

  @override
  State<ClawfreeLogo> createState() => _ClawfreeLogoState();
}

class _ClawfreeLogoState extends State<ClawfreeLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
      builder: (context, child) {
        final scale = 1.0 + (0.05 * _controller.value);
        return Transform.scale(
          scale: scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size * 0.22),
            child: Image.asset(
              ClawfreeAssets.icon,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
