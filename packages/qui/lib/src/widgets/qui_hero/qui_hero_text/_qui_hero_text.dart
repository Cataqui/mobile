part of '../qui_hero.dart';

final class _QuiHeroText extends QuiHero {
  const _QuiHeroText({
    required super.tag,
    required this.text,
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.overflow,
    this.maxLines,
    this.padding,
    this.switchThreshold = 0.5,
  }) : assert(switchThreshold >= 0.0 && switchThreshold <= 1.0, 'switchThreshold must be between 0.0 and 1.0.'),
       flight = null,
       super._(defaultTag: _QuiHeroDefaultTag.text, flightShuttleBuilder: _buildFlightShuttle);

  _QuiHeroText.fromFlight(_QuiHeroTextFlight flight)
    : text = flight.text,
      style = flight.style,
      textAlign = flight.textAlign,
      overflow = flight.overflow,
      maxLines = flight.maxLines,
      padding = flight.padding,
      switchThreshold = flight.switchThreshold,
      flight = flight,
      super._(tag: null, defaultTag: _QuiHeroDefaultTag.text, flightShuttleBuilder: _buildFlightShuttle);

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final EdgeInsetsGeometry? padding;
  final double switchThreshold;
  final _QuiHeroTextFlight? flight;

  static _QuiHeroTextFlight _lerpTextFlight({
    required _QuiHeroTextFlight from,
    required _QuiHeroTextFlight to,
    required double value,
    required HeroFlightDirection flightDirection,
  }) {
    final lerpValue = flightDirection == HeroFlightDirection.push ? value : (1 - value);
    final showBegin = lerpValue < from.switchThreshold;
    final lerpedStyle = TextStyle.lerp(from.style, to.style, lerpValue)!;
    final progressiveClampMaxLines = _progressiveClampMaxLines(from: from, to: to, showBegin: showBegin);
    return _QuiHeroTextFlight(
      text: showBegin ? from.text : to.text,
      style: lerpedStyle,
      flightBeginStyle: from.style,
      flightEndStyle: to.style,
      flightProgress: lerpValue,
      maxLines: showBegin ? from.maxLines : to.maxLines,
      overflow: showBegin ? from.overflow : to.overflow,
      textAlign: showBegin ? from.textAlign : to.textAlign,
      padding: EdgeInsetsGeometry.lerp(from.padding, to.padding, lerpValue),
      switchThreshold: from.switchThreshold,
      shortenToBounds: true,
      progressiveClampMaxLines: progressiveClampMaxLines,
      progressiveClampProgress: _progressiveClampProgress(
        lerpValue: lerpValue,
        switchThreshold: from.switchThreshold,
        progressiveClampMaxLines: progressiveClampMaxLines,
      ),
    );
  }

  static int? _progressiveClampMaxLines({
    required _QuiHeroTextFlight from,
    required _QuiHeroTextFlight to,
    required bool showBegin,
  }) {
    if (!showBegin) return null;
    if (to.maxLines == null) return null;
    if (from.maxLines != null && from.maxLines! <= to.maxLines!) return null;

    return to.maxLines;
  }

  static double _progressiveClampProgress({
    required double lerpValue,
    required double switchThreshold,
    required int? progressiveClampMaxLines,
  }) {
    if (progressiveClampMaxLines == null) return 0;
    if (switchThreshold <= 0) return 1;

    return (lerpValue / switchThreshold).clamp(0.0, 1.0);
  }

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromText = _textFromHeroContext(fromHeroContext);
    final toText = _textFromHeroContext(toHeroContext);

    if (_hasSamePresentation(begin: fromText, end: toText)) {
      return RepaintBoundary(child: fromText._copyWith(shortenToBounds: true));
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return _lerpTextFlight(
            from: fromText,
            to: toText,
            value: Curves.easeOutCubic.transform(animation.value),
            flightDirection: flightDirection,
          );
        },
      ),
    );
  }

  static bool _hasSamePresentation({required _QuiHeroTextFlight begin, required _QuiHeroTextFlight end}) {
    return begin.text == end.text &&
        begin.style == end.style &&
        begin.textAlign == end.textAlign &&
        begin.overflow == end.overflow &&
        begin.maxLines == end.maxLines &&
        begin.padding == end.padding;
  }

  static _QuiHeroTextFlight _textFromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroTextFlight;
  }

  TextStyle _resolvedStyle(BuildContext context) {
    return DefaultTextStyle.of(context).style.merge(style);
  }

  _QuiHeroText _buildWithResolvedStyle(BuildContext context) {
    return _QuiHeroText(
      tag: tag,
      text: text,
      style: _resolvedStyle(context),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      padding: padding,
      switchThreshold: switchThreshold,
      key: key,
    );
  }

  ({_QuiHeroText hero, double? estimatedHeight}) _buildWithEndpointMetricsAndEstimatedHeight({
    required BuildContext context,
    required double width,
    required Size beginSize,
    required Size endSize,
    required double beginLayoutWidth,
    required double endLayoutWidth,
  }) {
    final flight = this.flight;
    if (flight == null) return (hero: this, estimatedHeight: null);

    final endpointMaxLines = flight._endpointMaxLinesFor(context: context, beginSize: beginSize, endSize: endSize);
    final measuredFlight = flight._copyWith(
      endpointMaxLines: endpointMaxLines,
      endpointReservedLayoutWidth: flight._endpointReservedLayoutWidthFor(
        beginLayoutWidth: beginLayoutWidth,
        endLayoutWidth: endLayoutWidth,
      ),
    );

    return (
      hero: _QuiHeroText.fromFlight(measuredFlight),
      estimatedHeight: measuredFlight._estimatedHeightForWidth(context: context, width: width),
    );
  }

  @override
  Widget _buildFlightChild(BuildContext context) {
    return _QuiHeroTextFlight(
      text: text,
      style: _resolvedStyle(context),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      padding: padding,
      switchThreshold: switchThreshold,
    );
  }

  @override
  _QuiHeroText _buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
  }) {
    final endText = end as _QuiHeroText;

    return _QuiHeroText.fromFlight(
      _lerpTextFlight(
        from: _QuiHeroTextFlight(
          text: text,
          style: style ?? const TextStyle(),
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          padding: padding,
          switchThreshold: switchThreshold,
          shortenToBounds: true,
        ),
        to: _QuiHeroTextFlight(
          text: endText.text,
          style: endText.style ?? const TextStyle(),
          textAlign: endText.textAlign,
          overflow: endText.overflow,
          maxLines: endText.maxLines,
          padding: endText.padding,
          switchThreshold: endText.switchThreshold,
        ),
        value: value,
        flightDirection: flightDirection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_QuiHeroGroupScope.maybeOf(context) != null) {
      if (flight != null) return flight!;

      Widget result = Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
      if (padding != null) result = Padding(padding: padding!, child: result);
      return result;
    }

    return super.build(context);
  }
}
