part of '../qui_hero.dart';

final class _QuiHeroBox extends QuiHero {
  const _QuiHeroBox({
    required super.tag,
    required this.extensions,
    required super.onStart,
    required super.onEnd,
    super.key,
    this.decoration,
    this.width,
    this.height,
    this.padding,
    this.userChild,
  }) : super._(defaultTag: _QuiHeroDefaultTag.box, flightShuttleBuilder: _buildFlightShuttle);

  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final List<QuiHeroExtension> extensions;
  final Widget? userChild;

  static _QuiHeroBoxFlight _lerpBoxFlight({
    required _QuiHeroBoxFlight from,
    required _QuiHeroBoxFlight to,
    required double value,
  }) {
    return _QuiHeroBoxFlight(decoration: BoxDecoration.lerp(from.decoration, to.decoration, value));
  }

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
    Widget fromHeroChild,
    Widget toHeroChild,
  ) {
    final fromBox = fromHeroChild as _QuiHeroBoxFlight;
    final toBox = toHeroChild as _QuiHeroBoxFlight;
    final begin = flightDirection == HeroFlightDirection.push ? fromBox : toBox;
    final end = flightDirection == HeroFlightDirection.push ? toBox : fromBox;

    if (begin.decoration == end.decoration) {
      return RepaintBoundary(child: begin);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return _lerpBoxFlight(from: begin, to: end, value: Curves.easeOutCubic.transform(animation.value));
        },
      ),
    );
  }

  @override
  Widget _buildFlightChild(BuildContext context) {
    return _QuiHeroBoxFlight(decoration: decoration);
  }

  @override
  Widget build(BuildContext context) {
    if (_QuiHeroGroupScope.maybeOf(context) != null) {
      return _buildSizedContent(flightChild: _buildFlightChild(context));
    }

    return _wrapWithExtensions(
      context: context,
      child: _buildSizedContent(flightChild: super.build(context), boxContext: context),
    );
  }

  Widget _buildSizedContent({required Widget flightChild, BuildContext? boxContext}) {
    final child = userChild;
    var result = flightChild;

    if (child != null) {
      var content = child;
      if (padding != null) content = Padding(padding: padding!, child: content);
      if (boxContext != null) {
        content = _QuiHeroBoxScope(boxContext: boxContext, child: content);
      }
      result = Stack(
        children: [
          Positioned.fill(child: result),
          content,
        ],
      );
    }

    if (width != null || height != null) result = SizedBox(width: width, height: height, child: result);

    return result;
  }

  @override
  _QuiHeroBox _buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    _QuiHeroTextFlightMetrics? flightMetrics,
  }) {
    final endBox = end as _QuiHeroBox;
    final lerpValue = flightDirection == HeroFlightDirection.push ? value : (1 - value);

    final lerpedBox = _lerpBoxFlight(
      from: _QuiHeroBoxFlight(decoration: decoration),
      to: _QuiHeroBoxFlight(decoration: endBox.decoration),
      value: lerpValue,
    );

    return _QuiHeroBox(
      tag: null,
      decoration: lerpedBox.decoration,
      width: _tryLerpDouble(width, endBox.width, lerpValue),
      height: _tryLerpDouble(height, endBox.height, lerpValue),
      padding: EdgeInsetsGeometry.lerp(padding, endBox.padding, lerpValue),
      extensions: const [],
      onStart: null,
      onEnd: null,
      userChild: lerpValue < 0.5 ? userChild : endBox.userChild,
    );
  }

  static double? _tryLerpDouble(double? begin, double? end, double value) {
    if (begin == null && end == null) return null;

    final beginValue = begin ?? 0;
    return beginValue + ((end ?? 0) - beginValue) * value;
  }

  Widget _wrapWithExtensions({required BuildContext context, required Widget child}) {
    var result = child;

    for (final extension in extensions.reversed) {
      result = extension.wrap(context: context, child: result);
    }

    return result;
  }
}
