part of 'welcome_view.dart';

class _WelcomeArtworkBackgroundBoxPainter extends BoxPainter {
  _WelcomeArtworkBackgroundBoxPainter({required this.decoration, required VoidCallback onChanged})
    : _animatesColor = decoration.beginColor != decoration.endColor,
      super(onChanged) {
    if (_animatesColor) decoration.colorAnimation.addListener(onChanged);
  }

  final _WelcomeArtworkBackgroundDecoration decoration;
  final bool _animatesColor;
  final Paint _paint = Paint();

  @override
  void dispose() {
    if (_animatesColor) decoration.colorAnimation.removeListener(onChanged!);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    canvas.drawCircle(rect.center, rect.shortestSide / 2, _paint..color = decoration._color);
  }
}
