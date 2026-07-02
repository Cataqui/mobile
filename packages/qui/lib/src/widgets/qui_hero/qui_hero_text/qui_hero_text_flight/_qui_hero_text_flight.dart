part of '../../qui_hero.dart';

class _QuiHeroTextFlight extends StatelessWidget {
  const _QuiHeroTextFlight({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.overflow,
    required this.maxLines,
    required this.switchThreshold,
    this.shortenToBounds = false,
    this.padding,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final EdgeInsetsGeometry? padding;
  final double switchThreshold;
  final bool shortenToBounds;

  _QuiHeroTextFlight _copyWith({bool? shortenToBounds}) {
    return _QuiHeroTextFlight(
      text: text,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      switchThreshold: switchThreshold,
      shortenToBounds: shortenToBounds ?? this.shortenToBounds,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = SizedBox(
      width: double.infinity,
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: shortenToBounds ? AlignmentDirectional.topStart : Alignment.centerLeft,
          child: shortenToBounds
              ? _buildShortenedText(context)
              : Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow),
        ),
      ),
    );

    if (padding != null) result = Padding(padding: padding!, child: result);

    return result;
  }

  Widget _buildShortenedText(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxLines = _effectiveMaxLines(context: context, constraints: constraints);
        final text = Text(
          this.text,
          style: style,
          textAlign: textAlign,
          maxLines: effectiveMaxLines,
          overflow: _effectiveOverflow(effectiveMaxLines),
        );

        if (!constraints.hasBoundedHeight) return text;

        return SizedBox(
          width: double.infinity,
          height: constraints.maxHeight,
          child: Align(alignment: AlignmentDirectional.topStart, child: text),
        );
      },
    );
  }

  int? _effectiveMaxLines({required BuildContext context, required BoxConstraints constraints}) {
    if (!shortenToBounds) return maxLines;
    if (!constraints.hasBoundedHeight) return maxLines;

    final lineHeight = _preferredLineHeight(context);
    if (lineHeight <= 0) return maxLines;

    final heightBoundedMaxLines = math.max(1, constraints.maxHeight ~/ lineHeight);
    if (maxLines == null) return heightBoundedMaxLines;

    return math.min(maxLines!, heightBoundedMaxLines);
  }

  TextOverflow? _effectiveOverflow(int? effectiveMaxLines) {
    if (!shortenToBounds) return overflow;
    if (effectiveMaxLines == null) return overflow;

    return overflow ?? TextOverflow.ellipsis;
  }

  double _preferredLineHeight(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: ' ', style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );

    return textPainter.preferredLineHeight;
  }
}
