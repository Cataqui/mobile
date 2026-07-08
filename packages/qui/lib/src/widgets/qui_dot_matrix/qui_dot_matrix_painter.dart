part of 'qui_dot_matrix.dart';

const double _kMinOpacity = 0.01;
const double _kOneMinusMinOpacity = 1.0 - _kMinOpacity;
const double _kBandSigma = 0.18;
const double _kInvTwoSigmaSq = 1.0 / (2.0 * _kBandSigma * _kBandSigma);

class _QuiDotMatrixPainter extends CustomPainter {
  const _QuiDotMatrixPainter({required this.particles, required this.color, required this.progress});

  final List<_QuiDotMatrixDot> particles;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || particles.isEmpty) return;

    // ---- diagonal sweep band ----
    final rawPos = progress % 1.0;
    final double bandCenter;
    if (rawPos < 0.5) {
      bandCenter = 2.0 * rawPos * rawPos;
    } else {
      final t = rawPos - 1.0;
      bandCenter = 1.0 - 2.0 * t * t;
    }

    final invSumWH = 1.0 / (size.width + size.height);

    final paint = Paint();
    for (final pDot in particles) {
      final t = (pDot.position.dx + pDot.position.dy) * invSumWH;
      final rawDist = (t - bandCenter).abs();
      final dist = rawDist < 0.5 ? rawDist : 1.0 - rawDist;
      final activation = math.exp(-dist * dist * _kInvTwoSigmaSq);

      final opacity = _kMinOpacity + _kOneMinusMinOpacity * activation;

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(pDot.position, pDot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuiDotMatrixPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        !identical(oldDelegate.particles, particles);
  }
}
