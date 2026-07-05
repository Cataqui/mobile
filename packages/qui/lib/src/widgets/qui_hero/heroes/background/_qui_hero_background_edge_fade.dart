part of 'qui_hero_background.dart';

class QuiHeroBackgroundEdgeFade extends StatelessWidget {
  const QuiHeroBackgroundEdgeFade({super.key, this.edgeFade, this.borderRadius});

  final QuiHeroEdgeFade? edgeFade;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fade = edgeFade;
    if (fade == null) return const SizedBox.shrink();

    final clip = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: _fadeStack(fade))
        : _fadeStack(fade);

    return IgnorePointer(child: RepaintBoundary(child: clip));
  }

  Widget _fadeStack(QuiHeroEdgeFade fade) {
    final children = <Widget>[];

    for (final position in QuiEdgeFadePosition.values) {
      final style = fade.styleFor(position);

      if (style == null) continue;
      final insets = _insetsFor(position);

      children.add(
        Positioned(
          top: insets.top,
          bottom: insets.bottom,
          left: insets.left,
          right: insets.right,
          child: QuiEdgeFade(position: position, style: style),
        ),
      );
    }

    return Stack(children: children);
  }

  ({double? top, double? bottom, double? left, double? right}) _insetsFor(QuiEdgeFadePosition position) {
    return switch (position) {
      QuiEdgeFadePosition.top => (top: 0.0, bottom: null, left: 0.0, right: 0.0),
      QuiEdgeFadePosition.bottom => (top: null, bottom: 0.0, left: 0.0, right: 0.0),
    };
  }
}
