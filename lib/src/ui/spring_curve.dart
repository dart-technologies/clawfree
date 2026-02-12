import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// A damped spring oscillation curve for micro-interactions.
///
/// Produces an overshooting bounce effect that settles to 1.0.
/// Used by VoiceOrb and AnimatedMessageEntry.
class SpringCurve extends Curve {
  const SpringCurve({
    this.damping = 0.6,
    this.stiffness = 8.0,
  });

  /// Controls how quickly oscillations decay (0.0 = none, 1.0 = critical).
  final double damping;

  /// Controls oscillation frequency.
  final double stiffness;

  @override
  double transformInternal(double t) {
    // Damped harmonic oscillation: e^(-d*t) * cos(s*t)
    final decay = math.exp(-damping * stiffness * t);
    return 1.0 - decay * math.cos(stiffness * math.pi * t);
  }
}
