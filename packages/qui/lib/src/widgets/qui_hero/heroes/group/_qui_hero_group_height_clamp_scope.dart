part of 'qui_hero_group.dart';

class QuiHeroGroupHeightClampScope extends InheritedWidget {
  const QuiHeroGroupHeightClampScope({required super.child, super.key});

  static bool isActive(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<QuiHeroGroupHeightClampScope>() != null;
  }

  @override
  bool updateShouldNotify(QuiHeroGroupHeightClampScope oldWidget) => false;
}
