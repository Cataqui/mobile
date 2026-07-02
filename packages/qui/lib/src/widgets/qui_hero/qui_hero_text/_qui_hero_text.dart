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
       super._(defaultTag: _QuiHeroDefaultTag.text, flightShuttleBuilder: _buildFlightShuttle);

  _QuiHeroText.fromFlight(_QuiHeroTextFlight flight)
    : text = flight.text,
      style = flight.style,
      textAlign = flight.textAlign,
      overflow = flight.overflow,
      maxLines = flight.maxLines,
      padding = flight.padding,
      switchThreshold = flight.switchThreshold,
      super._(tag: null, defaultTag: _QuiHeroDefaultTag.text, flightShuttleBuilder: _buildFlightShuttle);

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final EdgeInsetsGeometry? padding;
  final double switchThreshold;

  static _QuiHeroTextFlight _lerpTextFlight({
    required _QuiHeroTextFlight from,
    required _QuiHeroTextFlight to,
    required double value,
    required HeroFlightDirection flightDirection,
  }) {
    final lerpValue = flightDirection == HeroFlightDirection.push ? value : (1 - value);
    final showBegin = lerpValue < from.switchThreshold;
    return _QuiHeroTextFlight(
      text: showBegin ? from.text : to.text,
      style: TextStyle.lerp(from.style, to.style, lerpValue)!,
      maxLines: showBegin ? from.maxLines : to.maxLines,
      overflow: showBegin ? from.overflow : to.overflow,
      textAlign: showBegin ? from.textAlign : to.textAlign,
      padding: EdgeInsetsGeometry.lerp(from.padding, to.padding, lerpValue),
      switchThreshold: from.switchThreshold,
      shortenToBounds: true,
    );
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
          return RepaintBoundary(
            child: _lerpTextFlight(
              from: fromText,
              to: toText,
              value: Curves.easeOutCubic.transform(animation.value),
              flightDirection: flightDirection,
            ),
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

  @override
  Widget _buildFlightChild(BuildContext context) {
    return _QuiHeroTextFlight(
      text: text,
      style: style ?? const TextStyle(),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      padding: padding,
      switchThreshold: switchThreshold,
    );
  }

  @override
  _QuiHeroText _buildForGroupFlight(QuiHero end, double value) {
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
        flightDirection: HeroFlightDirection.push,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_QuiHeroGroupScope.maybeOf(context) != null) {
      Widget result = Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
      if (padding != null) result = Padding(padding: padding!, child: result);
      return result;
    }

    return super.build(context);
  }
}
