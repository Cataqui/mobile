part of '../qui_hero.dart';

final class _QuiHeroGroup extends QuiHero {
  const _QuiHeroGroup({required super.tag, required this.heroes, super.key})
    : super._(defaultTag: _QuiHeroDefaultTag.group, flightShuttleBuilder: _buildFlightShuttle);

  final List<QuiHero> heroes;

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromGroup = _groupFromHeroContext(fromHeroContext);
    final toGroup = _groupFromHeroContext(toHeroContext);
    final begin = flightDirection == HeroFlightDirection.push ? fromGroup : toGroup;
    final end = flightDirection == HeroFlightDirection.push ? toGroup : fromGroup;
    final flightWidth = _maxHeroWidth(fromHeroContext: fromHeroContext, toHeroContext: toHeroContext);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final value = Curves.easeOutCubic.transform(animation.value);

          return _QuiHeroGroupContent(
            layout: end.layout,
            heroes: _lerpHeroes(begin: begin.heroes, end: end.heroes, value: value),
            allowsFlightOverflow: true,
            flightWidth: flightWidth,
          );
        },
      ),
    );
  }

  static _QuiHeroGroupContent _groupFromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroGroupContent;
  }

  static double? _maxHeroWidth({required BuildContext fromHeroContext, required BuildContext toHeroContext}) {
    final fromWidth = _heroWidth(fromHeroContext);
    final toWidth = _heroWidth(toHeroContext);

    if (fromWidth == null) return toWidth;
    if (toWidth == null) return fromWidth;
    return fromWidth > toWidth ? fromWidth : toWidth;
  }

  static double? _heroWidth(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final size = renderObject.size;
    if (!size.width.isFinite || size.width <= 0) return null;
    return size.width;
  }

  static List<QuiHero> _lerpHeroes({required List<QuiHero> begin, required List<QuiHero> end, required double value}) {
    assert(begin.length == end.length, 'QuiHero.group source and destination must have the same number of heroes.');

    if (begin.length != end.length) return value < 0.5 ? begin : end;

    return List<QuiHero>.generate(begin.length, (index) {
      final beginHero = begin[index];
      final endHero = end[index];

      assert(
        beginHero.runtimeType == endHero.runtimeType,
        'QuiHero.group hero at index $index must have the same variant on source and destination.',
      );

      if (beginHero.runtimeType != endHero.runtimeType) {
        return value < 0.5 ? beginHero : endHero;
      }

      return beginHero._buildForGroupFlight(endHero, value);
    });
  }

  @override
  QuiHero _buildForGroupFlight(QuiHero end, double value) {
    assert(false, 'Nested QuiHero.group is not supported.');
    return value < 0.5 ? this : end;
  }

  @override
  Widget _buildFlightChild(BuildContext context) {
    return _QuiHeroGroupContent(layout: _QuiHeroGroupLayout.fromContext(context), heroes: heroes);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      heroes.every((hero) => hero.tag == null),
      'QuiHero.group heroes must be tagless because the group owns the shared tag.',
    );

    return super.build(context);
  }
}
