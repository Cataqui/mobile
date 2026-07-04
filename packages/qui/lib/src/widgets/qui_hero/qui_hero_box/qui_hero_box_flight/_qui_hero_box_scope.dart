part of '../../qui_hero.dart';

class _QuiHeroBoxScope extends InheritedWidget {
  const _QuiHeroBoxScope({required this.boxContext, required super.child});

  final BuildContext boxContext;

  static _QuiHeroBoxScope? maybeOf(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_QuiHeroBoxScope>()?.widget as _QuiHeroBoxScope?;
  }

  RenderBox? get boxRenderObject => boxContext.findRenderObject() as RenderBox?;

  @override
  bool updateShouldNotify(_QuiHeroBoxScope oldWidget) => false;
}
