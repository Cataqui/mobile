part of 'app_animated_splash.dart';

class _SplashOverlayPainter extends CustomPainter {
  const _SplashOverlayPainter({
    required this.apertureCenter,
    required this.apertureRadius,
    required this.apertureFadeOpacity,
    required this.color,
  });

  final Offset apertureCenter;
  final double apertureRadius;
  final double apertureFadeOpacity;
  final Color color;

  static Path overlayPath({required Size size, required Offset apertureCenter, required double apertureRadius}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: apertureCenter, radius: apertureRadius));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    if (apertureRadius <= 0) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    canvas.drawPath(overlayPath(size: size, apertureCenter: apertureCenter, apertureRadius: apertureRadius), paint);

    if (apertureFadeOpacity <= 0) return;

    canvas.drawCircle(apertureCenter, apertureRadius, Paint()..color = color.withValues(alpha: apertureFadeOpacity));
  }

  @override
  bool shouldRepaint(_SplashOverlayPainter oldDelegate) {
    return apertureCenter != oldDelegate.apertureCenter ||
        apertureRadius != oldDelegate.apertureRadius ||
        apertureFadeOpacity != oldDelegate.apertureFadeOpacity ||
        color != oldDelegate.color;
  }
}
