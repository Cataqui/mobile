part of 'qui_appear.dart';

/// Controls a [QuiAppear] widget from parent code.
///
/// Call [appear] to start the appear animation or [destroy] to start the
/// destroy (disappear) animation. The animation plays with the [QuiAppear]
/// widget's configured animation and duration.
///
/// ```dart
/// final controller = QuiAppearController();
///
/// // Later, trigger the appear animation:
/// controller.appear();
/// ```
class QuiAppearController {
  void Function(double)? _onTrigger;
  double? _pendingValue;

  /// Tells the associated [QuiAppear] to start its appear animation.
  void appear() {
    if (_onTrigger != null) {
      _onTrigger!(1);
    } else {
      _pendingValue = 1;
    }
  }

  /// Tells the associated [QuiAppear] to start its destroy (disappear) animation.
  void destroy() {
    if (_onTrigger != null) {
      _onTrigger!(0);
    } else {
      _pendingValue = 0;
    }
  }

  void _register(void Function(double) onTrigger) {
    _onTrigger = onTrigger;
    final pending = _pendingValue;
    if (pending != null) {
      _pendingValue = null;
      onTrigger(pending);
    }
  }

  void _unregister() {
    _onTrigger = null;
  }
}
