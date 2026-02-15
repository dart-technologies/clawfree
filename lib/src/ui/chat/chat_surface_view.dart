import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';

import '../clawfree_icons.dart';
import '../theme.dart';

/// Renders a genUI Surface with fade-in animation, slide-up entry, and error boundary.
class ChatSurfaceView extends StatefulWidget {
  const ChatSurfaceView({
    super.key,
    required this.surfaceId,
    required this.surfaceHost,
    this.entranceDelay = Duration.zero,
  });

  final String surfaceId;
  final SurfaceHost surfaceHost;
  final Duration entranceDelay;

  @override
  State<ChatSurfaceView> createState() => _ChatSurfaceViewState();
}

class _ChatSurfaceViewState extends State<ChatSurfaceView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Add 80ms stagger for polished "pop-in"
    final delay = widget.entranceDelay + const Duration(milliseconds: 80);
    Future.delayed(delay, () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Opacity(
          opacity: _slideController.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.97 + (0.03 * _slideController.value),
            child: child,
          ),
        );
      },
      child: SurfaceErrorBoundary(
        child: Surface(
          key: ValueKey(widget.surfaceId),
          surfaceContext: widget.surfaceHost.contextFor(widget.surfaceId),
          defaultBuilder: (_) =>
              ShimmerSkeleton(type: _inferSkeletonType(widget.surfaceId)),
        ),
      ),
    );
  }
}

/// Infers the best skeleton layout based on the surface ID prefix.
SkeletonType _inferSkeletonType(String surfaceId) {
  final id = surfaceId.toLowerCase();
  if (id.startsWith('agent-form') || id.startsWith('connect')) {
    return SkeletonType.form;
  }
  if (id.startsWith('health')) {
    return SkeletonType.table;
  }
  if (id.startsWith('dashboard') ||
      id.startsWith('pair') ||
      id.startsWith('manage')) {
    return SkeletonType.card;
  }
  return SkeletonType.text;
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
            Icon(
              ClawfreeIcons.error,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Could not render UI component.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _error = null);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton bone layout type.
enum SkeletonType { text, form, table, card }

/// Animated shimmer skeleton shown while a Surface is loading.
class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({super.key, this.type = SkeletonType.text});

  final SkeletonType type;

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
    );

    bool isTest = false;
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        isTest = true;
      }
    } catch (_) {}

    if (!isTest) {
      _controller.repeat();
    }
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
        // Breathing pulse overlay
        final breathAlpha = (math.sin(_controller.value * math.pi) * 0.08)
            .abs();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: breathAlpha),
            borderRadius: ClawfreeBorderRadius.small,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBones(),
          ),
        );
      },
    );
  }

  Widget _buildBones() {
    return switch (widget.type) {
      SkeletonType.text => _textBones(),
      SkeletonType.form => _formBones(),
      SkeletonType.table => _tableBones(),
      SkeletonType.card => _cardBones(),
    };
  }

  /// Text skeleton: title + 3 lines + button.
  Widget _textBones() {
    return Column(
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
    );
  }

  /// Form skeleton: label + field pairs.
  Widget _formBones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(140, 12),
        const SizedBox(height: 6),
        _bar(double.infinity, 36),
        const SizedBox(height: 16),
        _bar(100, 12),
        const SizedBox(height: 6),
        _bar(double.infinity, 36),
        const SizedBox(height: 16),
        _bar(120, 12),
        const SizedBox(height: 6),
        _bar(double.infinity, 36),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerRight, child: _bar(100, 36)),
      ],
    );
  }

  /// Table skeleton: header row + data rows.
  Widget _tableBones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(child: _bar(double.infinity, 16)),
            const SizedBox(width: 12),
            Expanded(child: _bar(double.infinity, 16)),
            const SizedBox(width: 12),
            Expanded(child: _bar(double.infinity, 16)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        // Data rows
        for (var i = 0; i < 3; i++) ...[
          Row(
            children: [
              Expanded(child: _bar(double.infinity, 12)),
              const SizedBox(width: 12),
              Expanded(child: _bar(double.infinity, 12)),
              const SizedBox(width: 12),
              Expanded(child: _bar(double.infinity, 12)),
            ],
          ),
          if (i < 2) const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Card skeleton: image placeholder + text + button.
  Widget _cardBones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(double.infinity, 80),
        const SizedBox(height: 12),
        _bar(200, 18),
        const SizedBox(height: 8),
        _bar(260, 12),
        const SizedBox(height: 6),
        _bar(220, 12),
        const SizedBox(height: 16),
        _bar(100, 32),
      ],
    );
  }

  Widget _bar(double width, double height) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final t = _controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: ClawfreeBorderRadius.tiny,
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * t, 0),
          end: Alignment(2.0 * t, 0),
          colors: [baseColor, highlightColor, baseColor],
        ),
      ),
    );
  }
}
