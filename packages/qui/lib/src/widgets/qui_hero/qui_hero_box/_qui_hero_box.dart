part of '../qui_hero.dart';

class _QuiHeroBox extends QuiHero {
  const _QuiHeroBox({
    required super.tag,
    required this.extensions,
    this.decoration,
    this.width,
    this.height,
    this.padding,
    this.userChild,
    super.key,
  }) : super._(
         child: const SizedBox.shrink(),
         createRectTween: _createRectTween,
         flightShuttleBuilder: _buildFlightShuttle,
       );

  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final List<QuiHeroExtension> extensions;
  final Widget? userChild;

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
    final fromBox = _boxFromHeroContext(fromHeroContext);
    final toBox = _boxFromHeroContext(toHeroContext);
    final begin = flightDirection == HeroFlightDirection.push ? fromBox : toBox;
    final end = flightDirection == HeroFlightDirection.push ? toBox : fromBox;

    if (begin.decoration == end.decoration) {
      return RepaintBoundary(child: _QuiHeroBoxFlight(decoration: begin.decoration));
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final curvedValue = Curves.easeOutCubic.transform(animation.value);
          final lerpedDecoration =
              BoxDecoration.lerp(begin.decoration, end.decoration, curvedValue) ?? const BoxDecoration();

          return _QuiHeroBoxFlight(decoration: lerpedDecoration);
        },
      ),
    );
  }

  static _QuiHeroBoxFlight _boxFromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroBoxFlight;
  }

  @override
  Widget build(BuildContext context) {
    final heroWidget = Hero(
      tag: tag,
      createRectTween: createRectTween,
      flightShuttleBuilder: flightShuttleBuilder,
      transitionOnUserGestures: true,
      child: _QuiHeroBoxFlight(decoration: decoration),
    );

    if (userChild == null) {
      final result = (width != null || height != null)
          ? SizedBox(width: width, height: height, child: heroWidget)
          : heroWidget;

      return _wrapWithExtensions(context: context, child: result);
    }

    var content = userChild!;

    if (padding != null) content = Padding(padding: padding!, child: content);

    Widget result = Stack(
      children: [
        Positioned.fill(child: heroWidget),
        content,
      ],
    );

    if (width != null || height != null) result = SizedBox(width: width, height: height, child: result);

    return _wrapWithExtensions(context: context, child: result);
  }

  Widget _wrapWithExtensions({required BuildContext context, required Widget child}) {
    var result = child;

    for (final extension in extensions.reversed) {
      result = extension.wrap(context: context, child: result);
    }

    return result;
  }
}
