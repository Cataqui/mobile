part of 'qui_hero_group.dart';

class _QuiHeroGroupContent extends StatelessWidget {
  const _QuiHeroGroupContent({
    required this.layout,
    required this.heroes,
    this.allowsFlightOverflow = false,
    this.beginChildMetrics,
    this.endChildMetrics,
    this.flightValue = 0,
    this.maxAvailableHeight,
    this.beginHeight = 0,
    this.endHeight = 0,
  });

  final QuiHeroGroupLayout layout;
  final List<QuiHero> heroes;
  final bool allowsFlightOverflow;
  final List<({double layoutWidth, Offset offset, Size size})>? beginChildMetrics;
  final List<({double layoutWidth, Offset offset, Size size})>? endChildMetrics;
  final double flightValue;
  final double? maxAvailableHeight;
  final double beginHeight;
  final double endHeight;

  bool get canUsePositionedFlight {
    final beginMetrics = beginChildMetrics;
    final endMetrics = endChildMetrics;
    if (!allowsFlightOverflow || beginMetrics == null || endMetrics == null) return false;
    if (layout.type != QuiHeroGroupLayoutType.flex || layout.direction != Axis.vertical) return false;

    return beginMetrics.length >= heroes.length && endMetrics.length >= heroes.length;
  }

  double _positionedChildTop({
    required int index,
    required Offset offset,
    required double previousBottom,
    required List<({double layoutWidth, Offset offset, Size size})> beginMetrics,
    required List<({double layoutWidth, Offset offset, Size size})> endMetrics,
  }) {
    if (index == 0) return offset.dy;

    final beginGap =
        beginMetrics[index].offset.dy - (beginMetrics[index - 1].offset.dy + beginMetrics[index - 1].size.height);
    final endGap = endMetrics[index].offset.dy - (endMetrics[index - 1].offset.dy + endMetrics[index - 1].size.height);
    final gap = beginGap + (endGap - beginGap) * flightValue;

    return math.max(offset.dy, previousBottom + gap);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildWidthAwareContent();

    if (!allowsFlightOverflow) return Material(type: MaterialType.transparency, child: content);

    final maxHeight = maxAvailableHeight;

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (maxHeight != null) {
            final effectiveWidth = constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;

            return OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: effectiveWidth,
              maxWidth: effectiveWidth,
              minHeight: 0,
              maxHeight: maxHeight,
              child: content,
            );
          }

          if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) return content;

          return OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
            minHeight: 0,
            maxHeight: double.infinity,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildWidthAwareContent() {
    final content = QuiHeroGroupScope(child: _buildLayout());

    if (!layout.shouldReserveBoundedWidth) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return content;
        return SizedBox(width: constraints.maxWidth, child: content);
      },
    );
  }

  Widget _buildLayout() {
    if (canUsePositionedFlight) return _buildPositionedFlight();

    final maxHeight = maxAvailableHeight;
    if (maxHeight == null) return layout.build(children: heroes);

    // When height-constrained but positioned flight is unavailable, prevent
    // RenderFlex overflow by switching to mainAxisSize: max and constraining
    // each child to a share of the available height.
    final perChild = maxHeight / math.max(1, heroes.length);
    final constrainedHeroes = heroes.map((hero) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: perChild),
        child: hero,
      );
    }).toList();

    return Flex(
      direction: layout.direction,
      mainAxisAlignment: layout.mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: layout.crossAxisAlignment,
      textDirection: layout.textDirection,
      verticalDirection: layout.verticalDirection,
      textBaseline: layout.textBaseline,
      spacing: layout.spacing,
      children: constrainedHeroes,
    );
  }

  Widget _buildPositionedFlight() {
    final beginMetrics = beginChildMetrics!;
    final endMetrics = endChildMetrics!;
    final childCount = math.min(heroes.length, math.min(beginMetrics.length, endMetrics.length));
    final progress = flightValue;
    final height = beginHeight + (endHeight - beginHeight) * progress;
    final maxHeight = maxAvailableHeight;
    final shouldClip = maxHeight != null;
    final effectiveHeight = shouldClip ? math.min(height, maxHeight) : height;

    return LayoutBuilder(
      builder: (context, constraints) {
        var previousBottom = 0.0;

        Widget content = SizedBox(
          height: effectiveHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: List<Widget>.generate(childCount, (index) {
              final begin = beginMetrics[index];
              final end = endMetrics[index];
              final offset = Offset.lerp(begin.offset, end.offset, progress)!;
              final size = Size.lerp(begin.size, end.size, progress)!;
              final width = constraints.hasBoundedWidth ? constraints.maxWidth - offset.dx : size.width;
              final childData = _positionedChild(
                context: context,
                hero: heroes[index],
                width: width,
                beginSize: begin.size,
                endSize: end.size,
                beginLayoutWidth: begin.layoutWidth,
                endLayoutWidth: end.layoutWidth,
              );
              final childHeight = childData.estimatedHeight ?? size.height;
              final top = _positionedChildTop(
                index: index,
                offset: offset,
                previousBottom: previousBottom,
                beginMetrics: beginMetrics,
                endMetrics: endMetrics,
              );

              final effectiveChildHeight = shouldClip
                  ? math.min(childHeight, math.max(0, maxHeight - top))
                  : childHeight;
              previousBottom = top + effectiveChildHeight;

              final childWidget = shouldClip
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: math.max(0, maxHeight - top)),
                      child: childData.child,
                    )
                  : childData.child;

              return Positioned(left: offset.dx, top: top, width: math.max(0, width), child: childWidget);
            }),
          ),
        );

        if (shouldClip) content = QuiHeroGroupHeightClampScope(child: content);

        return content;
      },
    );
  }

  ({Widget child, double? estimatedHeight}) _positionedChild({
    required BuildContext context,
    required QuiHero hero,
    required double width,
    required Size beginSize,
    required Size endSize,
    required double beginLayoutWidth,
    required double endLayoutWidth,
  }) {
    if (hero is QuiHeroText) {
      final textFlight = hero.buildWithEndpointMetricsAndEstimatedHeight(
        context: context,
        width: width,
        beginSize: beginSize,
        endSize: endSize,
        beginLayoutWidth: beginLayoutWidth,
        endLayoutWidth: endLayoutWidth,
      );
      return (child: textFlight.hero, estimatedHeight: textFlight.estimatedHeight);
    }

    return (child: hero, estimatedHeight: null);
  }
}
