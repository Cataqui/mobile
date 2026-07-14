part of 'qui_swipe_to_pop_surface.dart';

class _QuiSwipeToPopSurfaceHandoffScope extends InheritedWidget {
  const _QuiSwipeToPopSurfaceHandoffScope({required this.state, required super.child});

  final QuiSwipeToPopHandoffState? state;

  static QuiSwipeToPopHandoffState? maybeStateOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_QuiSwipeToPopSurfaceHandoffScope>()?.state;
  }

  @override
  bool updateShouldNotify(_QuiSwipeToPopSurfaceHandoffScope oldWidget) {
    return state != oldWidget.state;
  }
}
