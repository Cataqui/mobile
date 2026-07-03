part of '../qui_hero.dart';

class _QuiHeroLifecycleEndpoint extends StatelessWidget {
  const _QuiHeroLifecycleEndpoint({required this.child, required this.onStartCallbacks, required this.onEndCallbacks});

  final Widget child;
  final List<VoidCallback> onStartCallbacks;
  final List<VoidCallback> onEndCallbacks;

  static _QuiHeroLifecycleEndpoint fromHeroContext(BuildContext context) {
    final hero = context.widget as Hero;
    return hero.child as _QuiHeroLifecycleEndpoint;
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
