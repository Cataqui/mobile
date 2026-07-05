part of 'qui_hero_text.dart';

class QuiHeroTextFlightMetrics {
  const QuiHeroTextFlightMetrics({
    required this.beginLineHeight,
    required this.beginBaseline,
    required this.endLineHeight,
    required this.endBaseline,
    required this.scaledLineHeight,
    required this.scaledBaseline,
    required this.stylePreferredLineHeight,
    required this.textDirection,
    required this.textScaler,
    required this.defaultTextStyle,
    this.endpointMaxLines,
    this.reservedLayoutWidthForSourceText,
    this.reservedLayoutWidthForTargetText,
  });

  factory QuiHeroTextFlightMetrics.precompute({
    required BuildContext context,
    required QuiHeroTextFlight from,
    required QuiHeroTextFlight to,
    Size? beginSize,
    Size? endSize,
    double? beginLayoutWidth,
    double? endLayoutWidth,
  }) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    final beginMetrics = _singleTextMetrics(
      defaultStyle: defaultTextStyle.style,
      style: from.style,
      direction: direction,
      textScaler: textScaler,
    );
    final endMetrics = _singleTextMetrics(
      defaultStyle: defaultTextStyle.style,
      style: to.style,
      direction: direction,
      textScaler: textScaler,
    );

    final scaledStyle = defaultTextStyle.style.merge(to.style);
    final scaledMetrics = _singleTextMetrics(
      defaultStyle: defaultTextStyle.style,
      style: scaledStyle,
      direction: direction,
      textScaler: textScaler,
    );

    final int? endpointMaxLines;
    if (beginSize != null && endSize != null) {
      endpointMaxLines = math.max(
        _endpointLineCountStatic(size: beginSize, lineHeight: beginMetrics.lineHeight),
        _endpointLineCountStatic(size: endSize, lineHeight: endMetrics.lineHeight),
      );
    } else {
      endpointMaxLines = null;
    }

    double? reservedLayoutWidthForSourceText;
    double? reservedLayoutWidthForTargetText;

    if (beginLayoutWidth != null && endLayoutWidth != null) {
      final hasSourceFontSize = from.style.fontSize != null && from.style.fontSize! > 0;
      final hasTargetFontSize = to.style.fontSize != null && to.style.fontSize! > 0;

      if (hasSourceFontSize && hasTargetFontSize) {
        final beginFontSize = from.style.fontSize!;
        final endFontSize = to.style.fontSize!;
        final sourceWidthInEndFont = beginLayoutWidth * (endFontSize / beginFontSize);
        reservedLayoutWidthForSourceText = math.min(sourceWidthInEndFont, endLayoutWidth);
        reservedLayoutWidthForTargetText = endLayoutWidth;
      }
    }

    return QuiHeroTextFlightMetrics(
      beginLineHeight: beginMetrics.lineHeight,
      beginBaseline: beginMetrics.baseline,
      endLineHeight: endMetrics.lineHeight,
      endBaseline: endMetrics.baseline,
      scaledLineHeight: scaledMetrics.lineHeight,
      scaledBaseline: scaledMetrics.baseline,
      stylePreferredLineHeight: scaledMetrics.lineHeight,
      textDirection: direction,
      textScaler: textScaler,
      defaultTextStyle: defaultTextStyle.style,
      endpointMaxLines: endpointMaxLines,
      reservedLayoutWidthForSourceText: reservedLayoutWidthForSourceText,
      reservedLayoutWidthForTargetText: reservedLayoutWidthForTargetText,
    );
  }

  final double beginLineHeight;
  final double beginBaseline;
  final double endLineHeight;
  final double endBaseline;
  final double scaledLineHeight;
  final double scaledBaseline;
  final double stylePreferredLineHeight;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextStyle defaultTextStyle;
  final int? endpointMaxLines;
  final double? reservedLayoutWidthForSourceText;
  final double? reservedLayoutWidthForTargetText;

  static ({double lineHeight, double baseline}) _singleTextMetrics({
    required TextStyle defaultStyle,
    required TextStyle style,
    required TextDirection direction,
    required TextScaler textScaler,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: ' ', style: defaultStyle.merge(style)),
      textDirection: direction,
      textScaler: textScaler,
    )..layout();
    final lineMetrics = textPainter.computeLineMetrics();
    return (
      lineHeight: textPainter.preferredLineHeight,
      baseline: lineMetrics.isNotEmpty ? lineMetrics.first.baseline : 0,
    );
  }

  static int _endpointLineCountStatic({required Size size, required double lineHeight}) {
    if (lineHeight <= 0) return 1;
    return math.max(1, (size.height / lineHeight).round());
  }
}
