part of 'qui_hero_background.dart';

class QuiHeroBackgroundFlight extends StatelessWidget {
  const QuiHeroBackgroundFlight({super.key, this.decoration});

  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(decoration: decoration ?? const BoxDecoration());
  }
}
