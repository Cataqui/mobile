import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

final class MyPostMorphCurve extends Curve {
  const MyPostMorphCurve();

  static const _landingStart = 0.55;
  static final _spring = SpringSimulation(
    SpringDescription.withDurationAndBounce(duration: const Duration(seconds: 1)),
    0,
    1,
    0,
  );

  @override
  double transformInternal(double t) {
    final progress = _spring.x(t);
    if (t <= _landingStart) return progress;

    // Keep the spring's motion through the main travel. This seventh-order
    // landing joins it without a velocity, acceleration, or jerk discontinuity
    // and reaches an exact rest at the end of the finite Morph flight.
    final landingProgress = (t - _landingStart) / (1 - _landingStart);
    final squared = landingProgress * landingProgress;
    final fourth = squared * squared;
    final landingBlend = fourth * (35 + landingProgress * (-84 + landingProgress * (70 - 20 * landingProgress)));
    return progress + (1 - progress) * landingBlend;
  }
}
