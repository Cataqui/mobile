part of '../../qui_hero.dart';

class _QuiHeroBoxFlight extends StatelessWidget {
  const _QuiHeroBoxFlight({this.decoration});

  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(decoration: decoration ?? const BoxDecoration());
  }
}
