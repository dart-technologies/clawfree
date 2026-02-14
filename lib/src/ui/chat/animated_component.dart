import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../spring_curve.dart';

/// JSON Schema for the Animated A2UI component.
final animatedSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['Animated']),
    'child': A2uiSchemas.componentReference(
      description: 'Child component to animate.',
    ),
    'animation': S.string(
      enumValues: ['fadeIn', 'slideUp', 'scale', 'slideLeft'],
      description: 'Animation type. Defaults to fadeIn.',
    ),
    'delay': S.number(
      description: 'Delay before animation starts, in milliseconds.',
    ),
    'duration': S.number(
      description: 'Animation duration in milliseconds. Defaults to 600.',
    ),
  },
  required: ['component', 'child'],
);

/// Catalog builder for the Animated component.
Widget animatedCatalogBuilder(CatalogItemContext itemContext) {
  final data = itemContext.data as Map<String, Object?>;
  final childRef = data['child'];
  final childId = childRef is String ? childRef : null;
  final animation = data['animation'] as String? ?? 'fadeIn';
  final delay = (data['delay'] as num?)?.toInt() ?? 0;
  final duration = (data['duration'] as num?)?.toInt() ?? 600;

  if (childId == null) return const SizedBox.shrink();

  return _AnimatedWrapper(
    itemContext: itemContext,
    childId: childId,
    animation: animation,
    delay: Duration(milliseconds: delay),
    duration: Duration(milliseconds: duration),
  );
}

class _AnimatedWrapper extends StatefulWidget {
  const _AnimatedWrapper({
    required this.itemContext,
    required this.childId,
    required this.animation,
    required this.delay,
    required this.duration,
  });

  final CatalogItemContext itemContext;
  final String childId;
  final String animation;
  final Duration delay;
  final Duration duration;

  @override
  State<_AnimatedWrapper> createState() => _AnimatedWrapperState();
}

class _AnimatedWrapperState extends State<_AnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const SpringCurve(),
    );

    if (widget.delay.inMilliseconds > 0) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.itemContext.buildChild(widget.childId);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final value = _animation.value;

        return switch (widget.animation) {
          'slideUp' => Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          'scale' => Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          'slideLeft' => Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          // fadeIn (default)
          _ => Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        };
      },
    );
  }
}
