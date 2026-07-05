part of 'qui_hero_background.dart';

class QuiHeroBackgroundScope extends InheritedWidget {
  const QuiHeroBackgroundScope({required this.context, required super.child, super.key});

  final BuildContext context;

  static QuiHeroBackgroundScope? maybeOf(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<QuiHeroBackgroundScope>()?.widget as QuiHeroBackgroundScope?;
  }

  RenderBox? get boxRenderObject => context.findRenderObject() as RenderBox?;

  @override
  bool updateShouldNotify(QuiHeroBackgroundScope oldWidget) => false;
}
