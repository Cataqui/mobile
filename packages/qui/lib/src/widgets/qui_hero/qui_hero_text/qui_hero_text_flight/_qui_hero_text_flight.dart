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
    this.flightBeginStyle,
    this.flightEndStyle,
    this.flightProgress = 0,
    this.endpointMaxLines,
    this.endpointReservedLayoutWidth,
    this.progressiveClampMaxLines,
    this.progressiveClampProgress = 0,
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
  final TextStyle? flightBeginStyle;
  final TextStyle? flightEndStyle;
  final double flightProgress;
  final int? endpointMaxLines;
  final double? endpointReservedLayoutWidth;
  final int? progressiveClampMaxLines;
  final double progressiveClampProgress;

  _QuiHeroTextFlight _copyWith({bool? shortenToBounds, int? endpointMaxLines, double? endpointReservedLayoutWidth}) {
    return _QuiHeroTextFlight(
      text: text,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      switchThreshold: switchThreshold,
      shortenToBounds: shortenToBounds ?? this.shortenToBounds,
      flightBeginStyle: flightBeginStyle,
      flightEndStyle: flightEndStyle,
      flightProgress: flightProgress,
      endpointMaxLines: endpointMaxLines ?? this.endpointMaxLines,
      endpointReservedLayoutWidth: endpointReservedLayoutWidth ?? this.endpointReservedLayoutWidth,
      progressiveClampMaxLines: progressiveClampMaxLines,
      progressiveClampProgress: progressiveClampProgress,
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
              : _buildText(context: context, maxLines: maxLines, overflow: overflow),
        ),
      ),
    );

    if (padding != null) result = Padding(padding: padding!, child: result);

    return result;
  }

  Widget _buildShortenedText(BuildContext context) {
    final scaledMetrics = _scaledMetrics(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxLines = _effectiveMaxLines(
          context: context,
          constraints: constraints,
          scaledMetrics: scaledMetrics,
        );
        final text = _buildText(
          context: context,
          maxLines: effectiveMaxLines,
          overflow: _effectiveOverflow(effectiveMaxLines),
          scaledMetrics: scaledMetrics,
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

  Widget _buildText({
    required BuildContext context,
    required int? maxLines,
    required TextOverflow? overflow,
    _QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    final effectiveScaledMetrics = scaledMetrics ?? _scaledMetrics(context);
    if (effectiveScaledMetrics == null) {
      return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth = _layoutWidthFor(
          constraints: constraints,
          scaleX: effectiveScaledMetrics.scaleX,
          reservedLayoutWidth: effectiveScaledMetrics.reservedLayoutWidth,
        );
        Widget result = Text(
          text,
          style: effectiveScaledMetrics.style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

        if (layoutWidth != null) {
          result = OverflowBox(
            alignment: AlignmentDirectional.topStart,
            fit: OverflowBoxFit.deferToChild,
            minWidth: layoutWidth,
            maxWidth: layoutWidth,
            child: SizedBox(width: layoutWidth, child: result),
          );
        }

        final scaledText = Align(
          alignment: AlignmentDirectional.topStart,
          widthFactor: effectiveScaledMetrics.scaleX,
          heightFactor: effectiveScaledMetrics.scaleY,
          child: Transform.scale(
            scaleX: effectiveScaledMetrics.scaleX,
            scaleY: effectiveScaledMetrics.scaleY,
            alignment: AlignmentDirectional.topStart,
            child: result,
          ),
        );

        if (effectiveScaledMetrics.baselineOffset == 0) return scaledText;

        return Transform.translate(offset: Offset(0, effectiveScaledMetrics.baselineOffset), child: scaledText);
      },
    );
  }

  int? _effectiveMaxLines({
    required BuildContext context,
    required BoxConstraints constraints,
    required _QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    if (!shortenToBounds) return maxLines;

    final lineHeight = _preferredLineHeight(context, scaledMetrics: scaledMetrics);
    if (lineHeight <= 0) return maxLines;

    final heightBoundedMaxLines = constraints.hasBoundedHeight
        ? math.max(1, constraints.maxHeight ~/ lineHeight)
        : null;
    final boundedMaxLines = _boundedMaxLines(heightBoundedMaxLines);
    final progressiveMaxLines = _progressiveMaxLines(
      context: context,
      constraints: constraints,
      boundedMaxLines: boundedMaxLines,
      scaledMetrics: scaledMetrics,
    );
    return progressiveMaxLines;
  }

  int? _boundedMaxLines(int? heightBoundedMaxLines) {
    if (heightBoundedMaxLines == null) return maxLines;
    if (maxLines == null) return heightBoundedMaxLines;

    return math.min(maxLines!, heightBoundedMaxLines);
  }

  int? _progressiveMaxLines({
    required BuildContext context,
    required BoxConstraints constraints,
    required int? boundedMaxLines,
    required _QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    final targetMaxLines = progressiveClampMaxLines;
    if (targetMaxLines == null) return boundedMaxLines;
    if (!constraints.hasBoundedWidth) return boundedMaxLines;

    final naturalMaxLines = _naturalLineCount(
      context: context,
      width: constraints.maxWidth,
      scaledMetrics: scaledMetrics,
    );
    final beginMaxLines = math.max(boundedMaxLines ?? naturalMaxLines, targetMaxLines);
    final clampedProgress = progressiveClampProgress.clamp(0.0, 1.0);
    final interpolatedMaxLines = _lerpDouble(beginMaxLines.toDouble(), targetMaxLines.toDouble(), clampedProgress);

    return math.max(targetMaxLines, interpolatedMaxLines.ceil());
  }

  TextOverflow? _effectiveOverflow(int? effectiveMaxLines) {
    return overflow;
  }

  double _preferredLineHeight(BuildContext context, {required _QuiHeroTextScaledMetrics? scaledMetrics}) {
    if (scaledMetrics != null) return scaledMetrics.lineHeight;

    final textPainter = TextPainter(
      text: TextSpan(text: ' ', style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );

    return textPainter.preferredLineHeight;
  }

  int _naturalLineCount({
    required BuildContext context,
    required double width,
    required _QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    if (scaledMetrics != null) {
      final layoutWidth = math.max(width / scaledMetrics.scaleX, scaledMetrics.reservedLayoutWidth ?? 0);
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(scaledMetrics.style)),
        textAlign: textAlign,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: layoutWidth);

      return math.max(1, textPainter.computeLineMetrics().length);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);

    return math.max(1, textPainter.computeLineMetrics().length);
  }

  _QuiHeroTextScaledMetrics? _scaledMetrics(BuildContext context) {
    final beginStyle = flightBeginStyle;
    final endStyle = flightEndStyle;
    final currentFontSize = style.fontSize;
    final stableFontSize = endStyle?.fontSize;
    if (!shortenToBounds || beginStyle == null || endStyle == null) return null;
    if (currentFontSize == null || currentFontSize <= 0 || stableFontSize == null || stableFontSize <= 0) return null;

    final scaledStyle = style.copyWith(fontSize: stableFontSize);
    final scaledTextMetrics = _textMetrics(context: context, style: scaledStyle);
    if (scaledTextMetrics.lineHeight <= 0) return null;

    final beginTextMetrics = _textMetrics(context: context, style: beginStyle);
    final endTextMetrics = _textMetrics(context: context, style: endStyle);
    final progress = flightProgress.clamp(0.0, 1.0);
    final lineHeight = _lerpDouble(beginTextMetrics.lineHeight, endTextMetrics.lineHeight, progress);
    final baseline = _lerpDouble(beginTextMetrics.baseline, endTextMetrics.baseline, progress);
    final scaledBaseline = scaledTextMetrics.baseline * (lineHeight / scaledTextMetrics.lineHeight);

    return _QuiHeroTextScaledMetrics(
      style: scaledStyle,
      scaleX: currentFontSize / stableFontSize,
      scaleY: lineHeight / scaledTextMetrics.lineHeight,
      lineHeight: lineHeight,
      baselineOffset: baseline - scaledBaseline,
      reservedLayoutWidth: _reservedLayoutWidth(context: context, style: scaledStyle),
    );
  }

  static double _lerpDouble(double begin, double end, double value) {
    return begin + (end - begin) * value;
  }

  double? _layoutWidthFor({
    required BoxConstraints constraints,
    required double scaleX,
    required double? reservedLayoutWidth,
  }) {
    if (!constraints.hasBoundedWidth) return reservedLayoutWidth;

    if (reservedLayoutWidth != null) {
      final widthForCurrentHero = constraints.maxWidth / scaleX;
      if (scaleX > 1) return math.min(reservedLayoutWidth, widthForCurrentHero);

      return reservedLayoutWidth;
    }

    return constraints.maxWidth / scaleX;
  }

  int? _endpointMaxLinesFor({required BuildContext context, required Size beginSize, required Size endSize}) {
    final beginStyle = flightBeginStyle;
    final endStyle = flightEndStyle;
    if (beginStyle == null || endStyle == null) return null;

    return math.max(
      _endpointLineCount(context: context, size: beginSize, style: beginStyle),
      _endpointLineCount(context: context, size: endSize, style: endStyle),
    );
  }

  double? _endpointReservedLayoutWidthFor({required double beginLayoutWidth, required double endLayoutWidth}) {
    final beginFontSize = flightBeginStyle?.fontSize;
    final endFontSize = flightEndStyle?.fontSize;
    if (beginFontSize == null || beginFontSize <= 0) return null;
    if (endFontSize == null || endFontSize <= 0) return null;

    if (flightProgress < switchThreshold) {
      final beginLayoutWidthInEndFont = beginLayoutWidth * (endFontSize / beginFontSize);

      return math.min(beginLayoutWidthInEndFont, endLayoutWidth);
    }

    return endLayoutWidth;
  }

  int _endpointLineCount({required BuildContext context, required Size size, required TextStyle style}) {
    final lineHeight = _textMetrics(context: context, style: style).lineHeight;
    if (lineHeight <= 0) return 1;

    return math.max(1, (size.height / lineHeight).round());
  }

  double? _reservedLayoutWidth({required BuildContext context, required TextStyle style}) {
    final endpointReservedLayoutWidth = this.endpointReservedLayoutWidth;
    final endpointMaxLines = this.endpointMaxLines;
    if (endpointReservedLayoutWidth == null || endpointReservedLayoutWidth <= 0) return null;

    if (endpointMaxLines != 1) return endpointReservedLayoutWidth;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return math.max(endpointReservedLayoutWidth, textPainter.width);
  }

  ({double lineHeight, double baseline}) _textMetrics({required BuildContext context, required TextStyle style}) {
    final textPainter = TextPainter(
      text: TextSpan(text: ' ', style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return (lineHeight: textPainter.preferredLineHeight, baseline: textPainter.computeLineMetrics().first.baseline);
  }
}

class _QuiHeroTextScaledMetrics {
  const _QuiHeroTextScaledMetrics({
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
