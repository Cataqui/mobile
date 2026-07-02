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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final animationValue = flightDirection == HeroFlightDirection.push ? animation.value : 1 - animation.value;
          final value = Curves.easeOutCubic.transform(animationValue);

          return _QuiHeroGroupContent(
            layout: toGroup.layout,
            heroes: _lerpHeroes(
              begin: fromGroup.heroes,
              end: toGroup.heroes,
              value: value,
              flightDirection: HeroFlightDirection.push,
            ),
            allowsFlightOverflow: true,
          );
        },
      ),
    );
  }

  static _QuiHeroGroupContent _groupFromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroGroupContent;
  }

  static List<QuiHero> _lerpHeroes({
    required List<QuiHero> begin,
    required List<QuiHero> end,
    required double value,
    required HeroFlightDirection flightDirection,
  }) {
    final count = math.min(begin.length, end.length);
    return List<QuiHero>.generate(count, (index) {
      final beginHero = begin[index];
      final endHero = end[index];

      return beginHero._buildForGroupFlight(end: endHero, value: value, flightDirection: flightDirection);
    });
  }

  @override
  QuiHero _buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
  }) {
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
