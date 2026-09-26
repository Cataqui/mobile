import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

class PostActivationLandingCurve extends Curve {
  const PostActivationLandingCurve();

  static const _landingStart = 0.6;
  // Curve time is normalized to one second; the slide controller owns wall time.
  static final _spring = SpringSimulation(
    SpringDescription.withDurationAndBounce(duration: const Duration(milliseconds: 900), bounce: 0),
    0,
    1,
    0,
  );

  @override
  double transformInternal(double t) {
    final springProgress = _spring.x(t);
    if (t <= _landingStart) return springProgress;

    // Keep the spring's motion at the handoff, then flatten velocity,
    // acceleration, and jerk into the exact endpoint.
    final landingProgress = (t - _landingStart) / (1 - _landingStart);
    final squared = landingProgress * landingProgress;
    final fourth = squared * squared;
    final landingBlend = fourth * (35 + landingProgress * (-84 + landingProgress * (70 - 20 * landingProgress)));
    return springProgress + (1 - springProgress) * landingBlend;
  }
}
