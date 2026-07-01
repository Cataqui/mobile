part of '../qui_hero.dart';

class _QuiHeroText extends QuiHero {
  _QuiHeroText({
    required super.tag,
    required this.text,
    this.style,
    this.textAlign = TextAlign.left,
    this.overflow,
    this.maxLines,
    super.key,
  }) : super._(
         child: _QuiHeroTextFlight(
           text: text,
           style: style ?? const TextStyle(),
           textAlign: textAlign,
           overflow: overflow,
           maxLines: maxLines,
         ),
         createRectTween: _createRectTween,
         flightShuttleBuilder: _buildFlightShuttle,
       );

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  static RectTween _createRectTween(Rect? begin, Rect? end) {
    return RectTween(begin: begin, end: end);
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
    final begin = flightDirection == HeroFlightDirection.push ? fromText : toText;
    final end = flightDirection == HeroFlightDirection.push ? toText : fromText;

    if (_hasSameFlightPresentation(begin: begin, end: end)) {
      return RepaintBoundary(
        child: _QuiHeroTextFlight(
          text: begin.text,
          style: begin.style,
          textAlign: begin.textAlign,
          overflow: begin.overflow,
          maxLines: begin.maxLines,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final curvedValue = Curves.easeOutCubic.transform(animation.value);
          final showBeginContent = curvedValue < 0.5;

          return _QuiHeroTextFlight(
            text: showBeginContent ? begin.text : end.text,
            style: TextStyle.lerp(begin.style, end.style, curvedValue)!,
            maxLines: showBeginContent ? begin.maxLines : end.maxLines,
            overflow: showBeginContent ? begin.overflow : end.overflow,
            textAlign: showBeginContent ? begin.textAlign : end.textAlign,
          );
        },
      ),
    );
  }

  static bool _hasSameFlightPresentation({required _QuiHeroTextFlight begin, required _QuiHeroTextFlight end}) {
    return begin.text == end.text &&
        begin.style == end.style &&
        begin.textAlign == end.textAlign &&
        begin.overflow == end.overflow &&
        begin.maxLines == end.maxLines;
  }

  static _QuiHeroTextFlight _textFromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroTextFlight;
  }
}
