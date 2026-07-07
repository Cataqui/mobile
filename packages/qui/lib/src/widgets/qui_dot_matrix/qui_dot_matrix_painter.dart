part of 'qui_dot_matrix.dart';

class _QuiDotMatrixPainter extends CustomPainter {
  const _QuiDotMatrixPainter({required this.particles, required this.palette, required this.progress});

  final List<_QuiDotMatrixDot> particles;

  final List<Color> palette;

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || particles.isEmpty) return;

    final cycleT = progress * math.pi * 2;
    final colorCount = palette.length;
    final colorCountMinusOne = colorCount - 1;
    final colorCountMinusTwo = colorCount - 2;
    final paint = Paint();

    if (colorCount == 1) {
      final singleColor = palette[0];
      for (final p in particles) {
        paint.color = singleColor.withValues(alpha: p.alpha);
        canvas.drawCircle(p.position, p.radius, paint);
      }
    } else {
      for (final p in particles) {
        final scaled = ((math.sin(cycleT * p.colorFreq + p.colorPhase) + 1) / 2) * colorCountMinusOne;
        final index = scaled.floor().clamp(0, colorCountMinusTwo);
        final frac = scaled - index;
        paint.color = Color.lerp(palette[index], palette[index + 1], frac)!.withValues(alpha: p.alpha);
        canvas.drawCircle(p.position, p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuiDotMatrixPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.palette != palette ||
        !identical(oldDelegate.particles, particles);
  }
}
