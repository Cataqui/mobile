part of 'welcome_view.dart';

class _WelcomeArtworkBackgroundDecoration extends Decoration {
  const _WelcomeArtworkBackgroundDecoration({
    required this.beginColor,
    required this.endColor,
    required this.colorAnimation,
  });

  final Color beginColor;
  final Color endColor;
  final Animation<double> colorAnimation;

  Color get _color => Color.lerp(beginColor, endColor, Curves.easeOutQuint.transform(colorAnimation.value))!;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    assert(onChanged != null, 'The animated welcome decoration requires a repaint callback.');
    return _WelcomeArtworkBackgroundBoxPainter(decoration: this, onChanged: onChanged!);
  }

  @override
  bool operator ==(Object other) {
    return other is _WelcomeArtworkBackgroundDecoration &&
        other.beginColor == beginColor &&
        other.endColor == endColor &&
        other.colorAnimation == colorAnimation;
  }

  @override
  int get hashCode => Object.hash(beginColor, endColor, colorAnimation);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', _color));
  }
}
