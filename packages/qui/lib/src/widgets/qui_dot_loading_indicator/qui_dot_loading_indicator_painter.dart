part of 'qui_dot_loading_indicator.dart';

class _QuiDotLoadingIndicatorPainter extends CustomPainter {
  _QuiDotLoadingIndicatorPainter({
    required this.color,
    required this.dotRadius,
    required this.jumpHeight,
    required this.spacing,
    required Animation<double>? progress,
  }) : _progress = progress,
       animated = progress != null,
       super(repaint: progress);

  static const int _dotCount = 3;
  static const double _phaseGap = 0.18;
  static const double _phaseOffset = 0.06;

  final Color color;
  final double dotRadius;
  final double jumpHeight;
  final double spacing;
  final bool animated;
  final Animation<double>? _progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (dotRadius <= 0 || size.width <= 0 || size.height <= 0) return;

    final diameter = dotRadius * 2;
    final centerY = jumpHeight + dotRadius;
    final paint = Paint()..color = color;
    final progress = _progress?.value ?? 0;

    for (var index = 0; index < _dotCount; index++) {
      final phase = (progress - index * _phaseGap + _phaseOffset) % 1;
      final lift = animated ? _liftFor(phase) : 0.0;
      final centerX = dotRadius + index * (diameter + spacing);

      canvas.drawCircle(Offset(centerX, centerY - jumpHeight * lift), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuiDotLoadingIndicatorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.jumpHeight != jumpHeight ||
        oldDelegate.spacing != spacing ||
        oldDelegate._progress != _progress ||
        oldDelegate.animated != animated;
  }

  double _liftFor(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return 0.5 - math.cos(clamped * math.pi * 2) * 0.5;
  }
}
