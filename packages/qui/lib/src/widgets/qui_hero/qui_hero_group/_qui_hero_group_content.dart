part of '../qui_hero.dart';

class _QuiHeroGroupContent extends StatelessWidget {
  const _QuiHeroGroupContent({required this.layout, required this.heroes, this.allowsFlightOverflow = false});

  final _QuiHeroGroupLayout layout;
  final List<QuiHero> heroes;
  final bool allowsFlightOverflow;

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
    final content = _QuiHeroGroupScope(child: layout.build(children: heroes));

    if (!layout.shouldReserveBoundedWidth) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return content;
        return SizedBox(width: constraints.maxWidth, child: content);
      },
    );
  }
}
