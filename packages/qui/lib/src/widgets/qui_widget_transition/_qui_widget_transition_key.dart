part of 'qui_widget_transition.dart';

@immutable
class _QuiWidgetTransitionKey {
  const _QuiWidgetTransitionKey(this.type, this.key);

  final Type type;
  final Key? key;

  @override
  bool operator ==(Object other) => other is _QuiWidgetTransitionKey && other.type == type && other.key == key;

  @override
  int get hashCode => Object.hash(type, key);
}
