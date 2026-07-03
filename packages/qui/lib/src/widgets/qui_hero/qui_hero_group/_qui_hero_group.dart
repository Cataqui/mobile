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
    final beginChildMetrics = _captureFlexChildMetrics(fromHeroContext);
    final endChildMetrics = _captureFlexChildMetrics(toHeroContext);

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
            beginChildMetrics: beginChildMetrics,
            endChildMetrics: endChildMetrics,
            flightValue: value,
          );
        },
      ),
    );
  }

  static _QuiHeroGroupContent _groupFromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroGroupContent;
  }

  static List<({double layoutWidth, Offset offset, Size size})>? _captureFlexChildMetrics(BuildContext context) {
    final groupBox = context.findRenderObject();
    if (groupBox is! RenderBox || !groupBox.hasSize) return null;

    final flex = _findRenderFlex(groupBox);
    if (flex == null || !flex.hasSize || flex.direction != Axis.vertical) return null;

    final groupOrigin = groupBox.localToGlobal(Offset.zero);
    final metrics = <({double layoutWidth, Offset offset, Size size})>[];
    var child = flex.firstChild;

    while (child != null) {
      final parentData = child.parentData;
      if (parentData is! FlexParentData || !child.hasSize) return null;

      metrics.add((
        layoutWidth: _layoutWidthForChild(child: child, fallbackWidth: flex.size.width),
        offset: flex.localToGlobal(parentData.offset) - groupOrigin,
        size: child.size,
      ));
      child = parentData.nextSibling;
    }

    return metrics;
  }

  static double _layoutWidthForChild({required RenderBox child, required double fallbackWidth}) {
    final paragraphWidth = _paragraphLayoutWidth(child);
    if (paragraphWidth != null) return paragraphWidth;

    return fallbackWidth;
  }

  static double? _paragraphLayoutWidth(RenderObject root) {
    if (root is RenderParagraph && root.constraints.hasBoundedWidth) return root.constraints.maxWidth;

    double? result;
    void visit(RenderObject child) {
      if (result != null) return;
      result = _paragraphLayoutWidth(child);
    }

    root.visitChildren(visit);
    return result;
  }

  static RenderFlex? _findRenderFlex(RenderObject root) {
    RenderFlex? result;

    void visit(RenderObject child) {
      if (result != null) return;

      if (child is RenderFlex) {
        result = child;
        return;
      }

      child.visitChildren(visit);
    }

    root.visitChildren(visit);
    return result;
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

  static List<QuiHero> _resolveEndpointHeroes({required BuildContext context, required List<QuiHero> heroes}) {
    return [
      for (final hero in heroes)
        if (hero is _QuiHeroText) hero._buildWithResolvedStyle(context) else hero,
    ];
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
    return _QuiHeroGroupContent(
      layout: _QuiHeroGroupLayout.fromContext(context),
      heroes: _resolveEndpointHeroes(context: context, heroes: heroes),
    );
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
