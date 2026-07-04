part of '../qui_hero.dart';

final class _QuiHeroGroup extends QuiHero {
  const _QuiHeroGroup({
    required super.tag,
    required this.heroes,
    required super.onStart,
    required super.onEnd,
    super.key,
  }) : super._(defaultTag: _QuiHeroDefaultTag.group, flightShuttleBuilder: _buildFlightShuttle);
  static List<({double layoutWidth, Offset offset, Size size})>? _cachedEndChildMetrics;
  static _QuiHeroBoxFlightMetrics? _cachedEndBoxMetrics;

  final List<QuiHero> heroes;

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
    Widget fromHeroChild,
    Widget toHeroChild,
  ) {
    final fromGroup = fromHeroChild as _QuiHeroGroupContent;
    final toGroup = toHeroChild as _QuiHeroGroupContent;
    final beginChildMetrics = _captureFlexChildMetrics(fromHeroContext);

    final freshEndChildMetrics = _captureFlexChildMetrics(toHeroContext);
    if (freshEndChildMetrics != null) _cachedEndChildMetrics = freshEndChildMetrics;
    final endChildMetrics = freshEndChildMetrics ?? _cachedEndChildMetrics ?? beginChildMetrics;

    final beginBoxMetrics = _captureBoxMetrics(fromHeroContext);

    final freshEndBoxMetrics = _captureBoxMetrics(toHeroContext);
    if (freshEndBoxMetrics != null) _cachedEndBoxMetrics = freshEndBoxMetrics;
    final endBoxMetrics = freshEndBoxMetrics ?? _cachedEndBoxMetrics ?? beginBoxMetrics;

    final beginHeight = _metricsHeight(beginChildMetrics);
    final endHeight = _metricsHeight(endChildMetrics);

    final textMetrics = <_QuiHeroTextFlightMetrics?>[];
    final count = math.min(fromGroup.heroes.length, toGroup.heroes.length);
    for (var i = 0; i < count; i++) {
      final fromHero = fromGroup.heroes[i];
      final toHero = toGroup.heroes[i];

      if (fromHero is _QuiHeroText && toHero is _QuiHeroText) {
        final fromText = fromHero._buildFlightChild(flightContext) as _QuiHeroTextFlight;
        final toText = toHero._buildFlightChild(flightContext) as _QuiHeroTextFlight;

        final beginSize = (beginChildMetrics != null && i < beginChildMetrics.length)
            ? beginChildMetrics[i].size as Size?
            : null;

        final endSize = (endChildMetrics != null && i < endChildMetrics.length)
            ? endChildMetrics[i].size as Size?
            : null;

        final beginLayoutWidth = (beginChildMetrics != null && i < beginChildMetrics.length)
            ? beginChildMetrics[i].layoutWidth as double?
            : null;

        final endLayoutWidth = (endChildMetrics != null && i < endChildMetrics.length)
            ? endChildMetrics[i].layoutWidth as double?
            : null;

        textMetrics.add(
          _QuiHeroTextFlightMetrics.precompute(
            context: flightContext,
            from: fromText,
            to: toText,
            beginSize: beginSize,
            endSize: endSize,
            beginLayoutWidth: beginLayoutWidth,
            endLayoutWidth: endLayoutWidth,
          ),
        );
      } else {
        textMetrics.add(null);
      }
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final animationValue = flightDirection == HeroFlightDirection.push ? animation.value : 1 - animation.value;
          final value = Curves.easeOutCubic.transform(animationValue);

          final availableHeight = _computeAvailableHeight(
            beginBoxMetrics: beginBoxMetrics,
            endBoxMetrics: endBoxMetrics,
            progress: value,
          );

          return _QuiHeroGroupContent(
            layout: toGroup.layout,
            heroes: _lerpHeroes(
              begin: fromGroup.heroes,
              end: toGroup.heroes,
              value: value,
              flightDirection: HeroFlightDirection.push,
              textMetrics: textMetrics,
            ),
            allowsFlightOverflow: true,
            beginChildMetrics: beginChildMetrics,
            endChildMetrics: endChildMetrics,
            flightValue: value,
            maxAvailableHeight: availableHeight,
            beginHeight: beginHeight,
            endHeight: endHeight,
          );
        },
      ),
    );
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
    List<_QuiHeroTextFlightMetrics?>? textMetrics,
  }) {
    final count = math.min(begin.length, end.length);
    return List<QuiHero>.generate(count, (index) {
      final beginHero = begin[index];
      final endHero = end[index];
      final metrics = (textMetrics != null && index < textMetrics.length) ? textMetrics[index] : null;

      return beginHero._buildForGroupFlight(
        end: endHero,
        value: value,
        flightDirection: flightDirection,
        flightMetrics: metrics,
      );
    });
  }

  static _QuiHeroBoxFlightMetrics? _captureBoxMetrics(BuildContext heroContext) {
    final boxScope = _QuiHeroBoxScope.maybeOf(heroContext);
    if (boxScope == null) return null;

    final boxRenderObject = boxScope.boxRenderObject;
    if (boxRenderObject == null || !boxRenderObject.hasSize) return null;

    final groupRenderObject = heroContext.findRenderObject();
    if (groupRenderObject is! RenderBox || !groupRenderObject.hasSize) return null;

    final boxOrigin = boxRenderObject.localToGlobal(Offset.zero);
    final groupOrigin = groupRenderObject.localToGlobal(Offset.zero);
    final groupOffsetInBox = groupOrigin - boxOrigin;

    return _QuiHeroBoxFlightMetrics(boxSize: boxRenderObject.size, groupOffsetInBox: groupOffsetInBox);
  }

  static double? _computeAvailableHeight({
    required _QuiHeroBoxFlightMetrics? beginBoxMetrics,
    required _QuiHeroBoxFlightMetrics? endBoxMetrics,
    required double progress,
  }) {
    if (beginBoxMetrics == null || endBoxMetrics == null) return null;

    final beginBoxHeight = beginBoxMetrics.boxSize.height;
    final endBoxHeight = endBoxMetrics.boxSize.height;
    final currentBoxHeight = beginBoxHeight + (endBoxHeight - beginBoxHeight) * progress;

    final beginGroupOffset = beginBoxMetrics.groupOffsetInBox.dy;
    final endGroupOffset = endBoxMetrics.groupOffsetInBox.dy;
    final currentGroupOffset = beginGroupOffset + (endGroupOffset - beginGroupOffset) * progress;

    final available = currentBoxHeight - currentGroupOffset;
    return available > 0 ? available : 0.0;
  }

  static double _metricsHeight(List<({double layoutWidth, Offset offset, Size size})>? metrics) {
    if (metrics == null || metrics.isEmpty) return 0;

    var height = 0.0;

    for (final metric in metrics) {
      height = math.max(height, metric.offset.dy + metric.size.height);
    }

    return height;
  }

  static List<QuiHero> _resolveEndpointHeroes({required BuildContext context, required List<QuiHero> heroes}) {
    return [
      for (final hero in heroes)
        if (hero is _QuiHeroText) hero._buildWithResolvedStyle(context) else hero,
    ];
  }

  @override
  List<VoidCallback> _lifecycleStartCallbacks(BuildContext context) {
    return [
      ...super._lifecycleStartCallbacks(context),
      for (final hero in heroes) ...hero._lifecycleStartCallbacks(context),
    ];
  }

  @override
  List<VoidCallback> _lifecycleEndCallbacks(BuildContext context) {
    return [
      ...super._lifecycleEndCallbacks(context),
      for (final hero in heroes) ...hero._lifecycleEndCallbacks(context),
    ];
  }

  @override
  QuiHero _buildForGroupFlight({
    required QuiHero end,
    required double value,
    required HeroFlightDirection flightDirection,
    _QuiHeroTextFlightMetrics? flightMetrics,
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

class _QuiHeroBoxFlightMetrics {
  const _QuiHeroBoxFlightMetrics({required this.boxSize, required this.groupOffsetInBox});

  final Size boxSize;
  final Offset groupOffsetInBox;
}
