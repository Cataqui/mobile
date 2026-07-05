part of 'qui_hero_text.dart';

class QuiHeroTextFlight extends StatelessWidget {
  const QuiHeroTextFlight({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.overflow,
    required this.maxLines,
    required this.switchThreshold,
    super.key,
    this.shortenToBounds = false,
    this.flightBeginStyle,
    this.flightEndStyle,
    this.flightProgress = 0,
    this.endpointMaxLines,
    this.endpointReservedLayoutWidth,
    this.progressiveClampMaxLines,
    this.progressiveClampProgress = 0,
    this.padding,
    this.flightMetrics,
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
  final QuiHeroTextFlightMetrics? flightMetrics;

  QuiHeroTextFlight copyWith({bool? shortenToBounds, int? endpointMaxLines, double? endpointReservedLayoutWidth}) {
    return QuiHeroTextFlight(
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
      flightMetrics: flightMetrics,
    );
  }

  static final Map<(String, int), int> _lineCountCache = {};

  int? _effectiveMaxLinesOf({
    required BuildContext context,
    required BoxConstraints constraints,
    required QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    if (!shortenToBounds) return maxLines;

    final lineHeight = _preferredLineHeight(context, scaledMetrics: scaledMetrics);
    if (lineHeight <= 0) return maxLines;

    final heightBoundedMaxLines = constraints.hasBoundedHeight
        ? math.max(1, constraints.maxHeight ~/ lineHeight)
        : null;
    final boundedMaxLines = _boundedMaxLinesOf(heightBoundedMaxLines);
    final progressiveMaxLines = _progressiveMaxLinesOf(
      context: context,
      constraints: constraints,
      boundedMaxLines: boundedMaxLines,
      scaledMetrics: scaledMetrics,
    );
    return progressiveMaxLines;
  }

  int? _boundedMaxLinesOf(int? heightBoundedMaxLines) {
    if (heightBoundedMaxLines == null) return maxLines;
    if (maxLines == null) return heightBoundedMaxLines;

    return math.min(maxLines!, heightBoundedMaxLines);
  }

  int? _progressiveMaxLinesOf({
    required BuildContext context,
    required BoxConstraints constraints,
    required int? boundedMaxLines,
    required QuiHeroTextScaledMetrics? scaledMetrics,
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

  TextOverflow? _effectiveOverflowOf(int? effectiveMaxLines, {BuildContext? context, bool isHeightBounded = false}) {
    if (isHeightBounded &&
        effectiveMaxLines != null &&
        context != null &&
        QuiHeroGroupHeightClampScope.isActive(context)) {
      return TextOverflow.ellipsis;
    }
    return overflow;
  }

  double _preferredLineHeight(BuildContext context, {required QuiHeroTextScaledMetrics? scaledMetrics}) {
    if (scaledMetrics != null) return scaledMetrics.lineHeight;
    if (flightMetrics != null) return flightMetrics!.stylePreferredLineHeight;

    final textPainter = TextPainter(
      text: TextSpan(text: ' ', style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );

    return textPainter.preferredLineHeight;
  }

  double? _estimatedHeightForWidth({required BuildContext context, required double width}) {
    if (width <= 0) return null;

    final metrics = flightMetrics;
    if (metrics != null) {
      return _cachedEstimatedHeight(context: context, width: width, metrics: metrics);
    }

    final scaledMetrics = _scaledMetricsOf(context);
    final constraints = BoxConstraints(maxWidth: width);
    final layoutWidth = scaledMetrics == null
        ? width
        : _layoutWidthFor(
            constraints: constraints,
            scaleX: scaledMetrics.scaleX,
            reservedLayoutWidth: scaledMetrics.reservedLayoutWidth,
          );
    if (layoutWidth == null || layoutWidth <= 0) return null;

    final effectiveMaxLines = shortenToBounds
        ? _effectiveMaxLinesOf(context: context, constraints: constraints, scaledMetrics: scaledMetrics)
        : maxLines;
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(scaledMetrics?.style ?? style)),
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: effectiveMaxLines,
      ellipsis: _ellipsisFor(_effectiveOverflowOf(effectiveMaxLines)),
    )..layout(maxWidth: layoutWidth);
    final textHeight = textPainter.height * (scaledMetrics?.scaleY ?? 1);

    return textHeight + (padding?.resolve(Directionality.of(context)).vertical ?? 0);
  }

  double? _cachedEstimatedHeight({
    required BuildContext context,
    required double width,
    required QuiHeroTextFlightMetrics metrics,
  }) {
    if (width <= 0) return null;

    final scaledMetrics = _scaledMetricsOf(context);
    final constraints = BoxConstraints(maxWidth: width);
    final layoutWidth = scaledMetrics == null
        ? width
        : _layoutWidthFor(
            constraints: constraints,
            scaleX: scaledMetrics.scaleX,
            reservedLayoutWidth: scaledMetrics.reservedLayoutWidth,
          );
    if (layoutWidth == null || layoutWidth <= 0) return null;

    final effectiveMaxLines = shortenToBounds
        ? _optimizedEffectiveMaxLines(
            context: context,
            width: layoutWidth,
            scaledMetrics: scaledMetrics,
            metrics: metrics,
          )
        : maxLines;

    final mergedStyle = metrics.defaultTextStyle.merge(scaledMetrics?.style ?? style);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: mergedStyle),
      textAlign: textAlign,
      textDirection: metrics.textDirection,
      textScaler: metrics.textScaler,
      maxLines: effectiveMaxLines,
      ellipsis: _ellipsisFor(_effectiveOverflowOf(effectiveMaxLines)),
    )..layout(maxWidth: layoutWidth);
    final textHeight = textPainter.height * (scaledMetrics?.scaleY ?? 1);

    return textHeight + (padding?.resolve(metrics.textDirection).vertical ?? 0);
  }

  int? _optimizedEffectiveMaxLines({
    required BuildContext context,
    required double width,
    required QuiHeroTextScaledMetrics? scaledMetrics,
    required QuiHeroTextFlightMetrics metrics,
  }) {
    if (!shortenToBounds) return maxLines;

    final lineHeight = scaledMetrics?.lineHeight ?? metrics.stylePreferredLineHeight;
    if (lineHeight <= 0) return maxLines;

    final boundedMaxLines = _boundedMaxLinesOf(null);
    if (!width.isFinite || width <= 0) return boundedMaxLines;

    final progressiveMaxLines = _progressiveMaxLinesOf(
      context: context,
      constraints: BoxConstraints(maxWidth: width),
      boundedMaxLines: boundedMaxLines,
      scaledMetrics: scaledMetrics,
    );
    return progressiveMaxLines;
  }

  String? _ellipsisFor(TextOverflow? overflow) {
    if (overflow != TextOverflow.ellipsis) return null;

    return '...';
  }

  int _naturalLineCount({
    required BuildContext context,
    required double width,
    required QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    final metrics = flightMetrics;
    if (metrics != null && scaledMetrics != null) {
      return _cachedNaturalLineCount(context: context, width: width, scaledMetrics: scaledMetrics, metrics: metrics);
    }

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

  int _cachedNaturalLineCount({
    required BuildContext context,
    required double width,
    required QuiHeroTextScaledMetrics scaledMetrics,
    required QuiHeroTextFlightMetrics metrics,
  }) {
    final key = (text, (width / 25).round());
    return _lineCountCache.putIfAbsent(key, () {
      final layoutWidth = math.max(width / scaledMetrics.scaleX, scaledMetrics.reservedLayoutWidth ?? 0);
      if (layoutWidth <= 0) return 1;
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: metrics.defaultTextStyle.merge(scaledMetrics.style)),
        textAlign: textAlign,
        textDirection: metrics.textDirection,
        textScaler: metrics.textScaler,
      )..layout(maxWidth: layoutWidth);
      return math.max(1, textPainter.computeLineMetrics().length);
    });
  }

  QuiHeroTextScaledMetrics? _scaledMetricsOf(BuildContext context) {
    final metrics = flightMetrics;
    if (metrics != null && shortenToBounds && flightBeginStyle != null && flightEndStyle != null) {
      return _optimizedScaledMetrics(context: context, metrics: metrics);
    }
    return _legacyScaledMetrics(context);
  }

  QuiHeroTextScaledMetrics? _optimizedScaledMetrics({
    required BuildContext context,
    required QuiHeroTextFlightMetrics metrics,
  }) {
    final currentFontSize = style.fontSize;
    final stableFontSize = flightEndStyle!.fontSize;
    if (currentFontSize == null || currentFontSize <= 0 || stableFontSize == null || stableFontSize <= 0) {
      return null;
    }

    final progress = flightProgress.clamp(0.0, 1.0);
    final lineHeight = _lerpDouble(metrics.beginLineHeight, metrics.endLineHeight, progress);
    final baseline = _lerpDouble(metrics.beginBaseline, metrics.endBaseline, progress);
    final scaledBaseline = metrics.scaledBaseline * (lineHeight / metrics.scaledLineHeight);

    return QuiHeroTextScaledMetrics(
      style: style.copyWith(fontSize: stableFontSize),
      scaleX: currentFontSize / stableFontSize,
      scaleY: lineHeight / metrics.scaledLineHeight,
      lineHeight: lineHeight,
      baselineOffset: baseline - scaledBaseline,
      reservedLayoutWidth: _computeReservedLayoutWidth(metrics: metrics),
    );
  }

  QuiHeroTextScaledMetrics? _legacyScaledMetrics(BuildContext context) {
    final beginStyle = flightBeginStyle;
    final endStyle = flightEndStyle;
    final currentFontSize = style.fontSize;
    final stableFontSize = endStyle?.fontSize;
    if (!shortenToBounds || beginStyle == null || endStyle == null) return null;
    if (currentFontSize == null || currentFontSize <= 0 || stableFontSize == null || stableFontSize <= 0) {
      return null;
    }

    final scaledStyle = style.copyWith(fontSize: stableFontSize);
    final scaledTextMetrics = _textMetrics(context: context, style: scaledStyle);
    if (scaledTextMetrics.lineHeight <= 0) return null;

    final beginTextMetrics = _textMetrics(context: context, style: beginStyle);
    final endTextMetrics = _textMetrics(context: context, style: endStyle);
    final progress = flightProgress.clamp(0.0, 1.0);
    final lineHeight = _lerpDouble(beginTextMetrics.lineHeight, endTextMetrics.lineHeight, progress);
    final baseline = _lerpDouble(beginTextMetrics.baseline, endTextMetrics.baseline, progress);
    final scaledBaseline = scaledTextMetrics.baseline * (lineHeight / scaledTextMetrics.lineHeight);

    return QuiHeroTextScaledMetrics(
      style: scaledStyle,
      scaleX: currentFontSize / stableFontSize,
      scaleY: lineHeight / scaledTextMetrics.lineHeight,
      lineHeight: lineHeight,
      baselineOffset: baseline - scaledBaseline,
      reservedLayoutWidth: _reservedLayoutWidth(context: context, style: scaledStyle),
    );
  }

  double? _computeReservedLayoutWidth({required QuiHeroTextFlightMetrics metrics}) {
    final showBegin = flightProgress < switchThreshold;
    final reservedWidth = showBegin
        ? metrics.reservedLayoutWidthForSourceText
        : metrics.reservedLayoutWidthForTargetText;
    final endpointMaxLines = metrics.endpointMaxLines;
    if (reservedWidth == null || reservedWidth <= 0) return null;
    if (endpointMaxLines != 1) return reservedWidth;
    return reservedWidth;
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
    if (endpointReservedLayoutWidth == null || endpointReservedLayoutWidth <= 0) {
      return null;
    }

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
    final scaledMetrics = _scaledMetricsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxLines = _effectiveMaxLinesOf(
          context: context,
          constraints: constraints,
          scaledMetrics: scaledMetrics,
        );
        final text = _buildText(
          context: context,
          maxLines: effectiveMaxLines,
          overflow: _effectiveOverflowOf(
            effectiveMaxLines,
            context: context,
            isHeightBounded: constraints.hasBoundedHeight,
          ),
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
    QuiHeroTextScaledMetrics? scaledMetrics,
  }) {
    final effectiveScaledMetrics = scaledMetrics ?? _scaledMetricsOf(context);
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
}
