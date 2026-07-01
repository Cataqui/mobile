part of '../../qui_hero.dart';

class _QuiHeroTextFlight extends StatelessWidget {
  const _QuiHeroTextFlight({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.overflow,
    required this.maxLines,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow),
        ),
      ),
    );
  }
}
