part of 'qui_hero_group.dart';

class QuiHeroGroupScope extends InheritedWidget {
  const QuiHeroGroupScope({required super.child, super.key});

  static QuiHeroGroupScope? maybeOf(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<QuiHeroGroupScope>()?.widget as QuiHeroGroupScope?;
  }

  @override
  bool updateShouldNotify(QuiHeroGroupScope oldWidget) {
    return false;
  }
}
