part of '../qui_hero.dart';

class _QuiHeroGroupScope extends InheritedWidget {
  const _QuiHeroGroupScope({required super.child});

  static _QuiHeroGroupScope? maybeOf(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_QuiHeroGroupScope>()?.widget as _QuiHeroGroupScope?;
  }

  @override
  bool updateShouldNotify(_QuiHeroGroupScope oldWidget) {
    return false;
  }
}
