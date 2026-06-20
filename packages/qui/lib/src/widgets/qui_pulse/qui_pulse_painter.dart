part of 'qui_pulse.dart';

class _PulseRingPainter extends CustomPainter {
  const _PulseRingPainter({
    required this.steps,
    required this.progress,
    required this.animated,
    required this.maxScale,
    required this.primary,
  });

  final List<QuiPulseStep> steps;
  final double progress;
  final bool animated;
  final double maxScale;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final count = steps.length;
    final center = size.center(Offset.zero);
    final childWidth = size.width;
    final childHeight = size.height;

    final paint = Paint();

    for (var i = 0; i < count; i++) {
      final step = steps[i];
      final baseAlpha = step.alpha ?? 0.35;
      final double scale;
      final double alpha;

      if (animated) {
        final phase = (progress + i / count) % 1.0;
        final eased = Curves.easeOut.transform(phase);
        scale = 1.0 + (maxScale - 1.0) * eased;
        alpha = baseAlpha * (1 - eased);
      } else {
        final fraction = (i + 1) / count;
        scale = 1.0 + (maxScale - 1.0) * fraction;
        alpha = baseAlpha;
      }

      if (alpha <= 0.001) continue;

      final color = (step.color ?? primary).withValues(alpha: alpha);

      final outerW = childWidth * scale;
      final outerH = childHeight * scale;
      final outerRect = Rect.fromCenter(center: center, width: outerW, height: outerH);

      final outerRRect = _scaledRRect(outerRect, step.borderRadius, scale);

      paint.color = color;
      canvas.drawRRect(outerRRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.maxScale != maxScale ||
        oldDelegate.primary != primary ||
        oldDelegate.animated != animated ||
        oldDelegate.steps != steps;
  }

  static RRect _scaledRRect(Rect rect, BorderRadius borderRadius, double scale) {
    return RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.elliptical(borderRadius.topLeft.x * scale, borderRadius.topLeft.y * scale),
      topRight: Radius.elliptical(borderRadius.topRight.x * scale, borderRadius.topRight.y * scale),
      bottomLeft: Radius.elliptical(borderRadius.bottomLeft.x * scale, borderRadius.bottomLeft.y * scale),
      bottomRight: Radius.elliptical(borderRadius.bottomRight.x * scale, borderRadius.bottomRight.y * scale),
    );
  }
}
