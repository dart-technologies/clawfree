import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../clawfree_icons.dart';

/// Renders a genUI Surface with fade-in animation and error boundary.
class ChatSurfaceView extends StatelessWidget {
  const ChatSurfaceView({
    super.key,
    required this.surfaceId,
    required this.surfaceHost,
  });

  final String surfaceId;
  final SurfaceHost surfaceHost;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeIn,
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: SurfaceErrorBoundary(
        child: Surface(
          genUiContext: surfaceHost.contextFor(surfaceId),
          defaultBuilder: (_) => const ShimmerSkeleton(),
        ),
      ),
    );
  }
}

/// Catches errors during Surface build and shows a fallback card.
class SurfaceErrorBoundary extends StatefulWidget {
  const SurfaceErrorBoundary({super.key, required this.child});
  final Widget child;

  @override
  State<SurfaceErrorBoundary> createState() => _SurfaceErrorBoundaryState();
}

class _SurfaceErrorBoundaryState extends State<SurfaceErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildFallback();
    }
    return widget.child;
  }

  Widget _buildFallback() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ClawfreeIcons.error,
                color: Theme.of(context).colorScheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Could not render UI component.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _error = null),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated shimmer skeleton shown while a Surface is loading.
class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({super.key});

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(180, 20),
              const SizedBox(height: 16),
              _bar(280, 14),
              const SizedBox(height: 8),
              _bar(240, 14),
              const SizedBox(height: 8),
              _bar(200, 14),
              const SizedBox(height: 20),
              _bar(120, 36),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double width, double height) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor =
        Theme.of(context).colorScheme.surfaceContainerHigh;
    final t = _controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * t, 0),
          end: Alignment(2.0 * t, 0),
          colors: [baseColor, highlightColor, baseColor],
        ),
      ),
    );
  }
}
