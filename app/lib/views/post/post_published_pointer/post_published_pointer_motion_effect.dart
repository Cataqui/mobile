import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class PostPublishedPointerMotionEffect extends MotionEffect {
  const PostPublishedPointerMotionEffect()
    : super(delay: const Duration(milliseconds: 150), duration: const Duration(milliseconds: 1800), playback: .loop);

  @override
  MotionEffectBounds get bounds => const MotionEffectBounds(maximumOffset: Offset(0, 4));

  @override
  void apply(double progress, MotionEffectTransform transform) {
    if (progress >= 0.5) return;
    final point = math.sin(4 * math.pi * progress);
    transform.translate(x: 0, y: 3 * point * point);
  }
}
