part of '../../qui_hero.dart';

class _QuiHeroTextFlight extends StatelessWidget {
  const _QuiHeroTextFlight({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.overflow,
    required this.maxLines,
    this.padding,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget result = SizedBox(
      width: double.infinity,
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow),
        ),
      ),
    );

    if (padding != null) result = Padding(padding: padding!, child: result);

    return result;
  }
}
