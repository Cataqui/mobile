part of '../qui_hero.dart';

class _QuiHeroGroupContent extends StatelessWidget {
  const _QuiHeroGroupContent({
    required this.layout,
    required this.heroes,
    this.allowsFlightOverflow = false,
    this.beginChildMetrics,
    this.endChildMetrics,
    this.flightValue = 0,
  });

  final _QuiHeroGroupLayout layout;
  final List<QuiHero> heroes;
  final bool allowsFlightOverflow;
  final List<({double layoutWidth, Offset offset, Size size})>? beginChildMetrics;
  final List<({double layoutWidth, Offset offset, Size size})>? endChildMetrics;
  final double flightValue;

  bool get _canUsePositionedFlight {
    final beginMetrics = beginChildMetrics;
    final endMetrics = endChildMetrics;
    if (!allowsFlightOverflow || beginMetrics == null || endMetrics == null) return false;
    if (layout.type != _QuiHeroGroupLayoutType.flex || layout.direction != Axis.vertical) return false;

    return beginMetrics.length >= heroes.length && endMetrics.length >= heroes.length;
  }

  double _metricsHeight(List<({double layoutWidth, Offset offset, Size size})> metrics) {
    if (metrics.isEmpty) return 0;

    var height = 0.0;

    for (final metric in metrics) {
      height = math.max(height, metric.offset.dy + metric.size.height);
    }

    return height;
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildWidthAwareContent();

    if (!allowsFlightOverflow) {
      return Material(type: MaterialType.transparency, child: content);
    }

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
    final content = _QuiHeroGroupScope(child: _buildLayout());

    if (!layout.shouldReserveBoundedWidth) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return content;
        return SizedBox(width: constraints.maxWidth, child: content);
      },
    );
  }

  Widget _buildLayout() {
    if (_canUsePositionedFlight) return _buildPositionedFlight();

    return layout.build(children: heroes);
  }

  Widget _buildPositionedFlight() {
    final beginMetrics = beginChildMetrics!;
    final endMetrics = endChildMetrics!;
    final childCount = math.min(heroes.length, math.min(beginMetrics.length, endMetrics.length));
    final progress = flightValue;
    final beginHeight = _metricsHeight(beginMetrics);
    final height = beginHeight + (_metricsHeight(endMetrics) - beginHeight) * progress;

    return LayoutBuilder(
      builder: (context, constraints) {
        var previousBottom = 0.0;

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: List<Widget>.generate(childCount, (index) {
              final begin = beginMetrics[index];
              final end = endMetrics[index];
              final offset = Offset.lerp(begin.offset, end.offset, progress)!;
              final size = Size.lerp(begin.size, end.size, progress)!;
              final width = constraints.hasBoundedWidth ? constraints.maxWidth - offset.dx : size.width;
              final childHeight = _positionedChildHeight(
                context: context,
                hero: heroes[index],
                width: width,
                beginSize: begin.size,
                endSize: end.size,
                beginLayoutWidth: begin.layoutWidth,
                endLayoutWidth: end.layoutWidth,
              );
              final top = _positionedChildTop(
                index: index,
                offset: offset,
                previousBottom: previousBottom,
                beginMetrics: beginMetrics,
                endMetrics: endMetrics,
              );
              final child = _buildPositionedChild(
                context: context,
                hero: heroes[index],
                beginSize: begin.size,
                endSize: end.size,
                beginLayoutWidth: begin.layoutWidth,
                endLayoutWidth: end.layoutWidth,
              );

              previousBottom = top + childHeight;

              return Positioned(left: offset.dx, top: top, width: math.max(0, width), child: child);
            }),
          ),
        );
      },
    );
  }

  double _positionedChildHeight({
    required BuildContext context,
    required QuiHero hero,
    required double width,
    required Size beginSize,
    required Size endSize,
    required double beginLayoutWidth,
    required double endLayoutWidth,
  }) {
    if (hero is _QuiHeroText) {
      final estimatedHeight = hero._estimatedFlightHeight(
        context: context,
        width: width,
        beginSize: beginSize,
        endSize: endSize,
        beginLayoutWidth: beginLayoutWidth,
        endLayoutWidth: endLayoutWidth,
      );
      if (estimatedHeight != null) return estimatedHeight;
    }

    return Size.lerp(beginSize, endSize, flightValue)!.height;
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

  Widget _buildPositionedChild({
    required BuildContext context,
    required QuiHero hero,
    required Size beginSize,
    required Size endSize,
    required double beginLayoutWidth,
    required double endLayoutWidth,
  }) {
    if (hero is _QuiHeroText) {
      return hero._buildWithEndpointMetrics(
        context: context,
        beginSize: beginSize,
        endSize: endSize,
        beginLayoutWidth: beginLayoutWidth,
        endLayoutWidth: endLayoutWidth,
      );
    }

    return hero;
  }
}
