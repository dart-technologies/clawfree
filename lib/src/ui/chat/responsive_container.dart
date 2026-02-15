import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'chat_surface_view.dart';

/// A genUI component that adapts its layout based on available width and
/// configurable column counts.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({super.key, required this.itemContext});

  final CatalogItemContext itemContext;

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, Object?>;
    final childrenRaw = data['children'];
    final spacing = (data['spacing'] as num?)?.toDouble() ?? 16.0;
    final columns = (data['columns'] as num?)?.toInt() ?? 2;
    final mobileColumns = (data['mobileColumns'] as num?)?.toInt() ?? 1;
    final skeletonRaw = data['skeleton'] as String?;

    // Extract child IDs from the children array.
    final childIds = <String>[];
    if (childrenRaw is List) {
      for (final item in childrenRaw) {
        if (item is String) childIds.add(item);
      }
    }

    if (childIds.isEmpty && skeletonRaw != null) {
      final skeletonType = _parseSkeletonType(skeletonRaw);
      return ShimmerSkeleton(type: skeletonType);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = <Widget>[];
        for (var i = 0; i < childIds.length; i++) {
          final child = itemContext.buildChild(
            childIds[i],
            itemContext.dataContext,
          );
          // Apply 80ms stagger per child
          children.add(_StaggeredEntrance(index: i, child: child));
        }

        final isMobile = constraints.maxWidth <= 600;
        final activeColumns = isMobile ? mobileColumns : columns;

        if (activeColumns > 1) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children.map((child) {
              final itemWidth = math.max(0.0, (constraints.maxWidth - (spacing * (activeColumns - 1))) /
                        activeColumns -
                    0.5);
              return SizedBox(
                width: itemWidth,
                child: child,
              );
            }).toList(),
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((child) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: child,
              );
            }).toList(),
          );
        }
      },
    );
  }

  SkeletonType _parseSkeletonType(String value) {
    return SkeletonType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkeletonType.text,
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.97 + (0.03 * _controller.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
