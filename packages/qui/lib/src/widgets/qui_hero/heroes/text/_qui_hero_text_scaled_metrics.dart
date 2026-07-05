part of 'qui_hero_text.dart';

class QuiHeroTextScaledMetrics {
  const QuiHeroTextScaledMetrics({
    required this.style,
    required this.scaleX,
    required this.scaleY,
    required this.lineHeight,
    required this.baselineOffset,
    required this.reservedLayoutWidth,
  });

  final TextStyle style;
  final double scaleX;
  final double scaleY;
  final double lineHeight;
  final double baselineOffset;
  final double? reservedLayoutWidth;
}
