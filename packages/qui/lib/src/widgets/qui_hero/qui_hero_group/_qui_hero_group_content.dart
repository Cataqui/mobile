part of '../qui_hero.dart';

class _QuiHeroGroupContent extends StatelessWidget {
  const _QuiHeroGroupContent({
    required this.layout,
    required this.heroes,
    this.allowsFlightOverflow = false,
    this.flightWidth,
  });

  final _QuiHeroGroupLayout layout;
  final List<QuiHero> heroes;
  final bool allowsFlightOverflow;
  final double? flightWidth;

  @override
  Widget build(BuildContext context) {
    final content = _QuiHeroGroupScope(child: layout.build(children: heroes));

    if (!allowsFlightOverflow) {
      return Material(type: MaterialType.transparency, child: content);
    }

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) return content;

          final maxFlightWidth = flightWidth;
          final width = maxFlightWidth == null || maxFlightWidth < constraints.maxWidth
              ? constraints.maxWidth
              : maxFlightWidth;

          return OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: 0,
            maxHeight: double.infinity,
            child: content,
          );
        },
      ),
    );
  }
}
