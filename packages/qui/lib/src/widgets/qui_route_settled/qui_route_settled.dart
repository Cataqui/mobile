import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/widgets/qui_appear.dart' show QuiAppear, QuiAppearAnimationType, QuiAppearController;

/// A visibility wrapper that fades [child] in once the enclosing route
/// has settled and hides it instantly while the route is mid-transition or
/// the user is performing a navigation gesture.
///
/// Wrap any widget that should be hidden during route transitions and revealed
/// once the route settles — back buttons, dismiss handles, auxiliary chrome
/// that is not part of a shared element. Works on every Flutter route type:
/// `MaterialPageRoute`, `QuiHeroPageRoute`, `NoTransitionPage`, dialog routes,
/// and custom `Page` subclasses. Covers push, pop, iOS swipe-back,
/// `QuiHeroSwipeToPopExtension` swipe-to-pop, and reduced motion with no
/// callback wiring.
///
/// The widget listens to `ModalRoute.animation` and to
/// `Navigator.userGestureInProgressNotifier`
///
/// ```dart
/// QuiRouteSettled(
///   child: QuiViewBackButton(onPressed: () => Navigator.of(context).maybePop()),
/// )
/// ```
///
/// ## How it works
///
/// A dual-listener approach keeps the widget universal:
///
///  1. **Route animation listener** — attached to
///     `ModalRoute.of(context)!.animation`. The `AnimationStatus` encodes
///     whether the route is pushing (`forward`), settled (`completed`),
///     popping (`reverse`), or gone (`dismissed`).
///  2. **Gesture listener** — attached to
///     `Navigator.userGestureInProgressNotifier`. Flutter flips this to
///     `true` for the duration of any user-driven navigation gesture, whether
///     an iOS swipe-back or a custom swipe-to-pop extension. During such
///     gestures the route animation controller is stopped with status
///     `completed` — without this second signal the drag phase would be
///     invisible to the route listener.
///
/// ## Visibility rule
///
/// ```text
/// visible = (routeAnimation.status == completed) && (userGestureInProgress == false)
/// ```
///
/// See also:
///  * [QuiAppear], the fade widget composed internally by this component.
///  * [QuiAppearController], the controller behind the appear/destroy actions.
class QuiRouteSettled extends StatefulWidget {
  /// Creates a QUI route-settled wrapper around [child].
  const QuiRouteSettled({
    required this.child,
    this.animation = QuiAppearAnimationType.fade,
    this.appearDuration = const Duration(milliseconds: 300),
    this.destroyDuration = Duration.zero,
    super.key,
  });

  /// Widget hidden during route transitions and revealed on settle.
  final Widget child;

  /// The type of appear animation.
  final QuiAppearAnimationType animation;

  /// How long the appear animation takes when the route settles.
  ///
  /// Defaults to 300 ms.
  final Duration appearDuration;

  /// How long the destroy (disappear) animation takes when hiding.
  ///
  /// Defaults to [Duration.zero] (instant hide), matching the expectation
  /// that chrome should vanish the moment a transition or gesture begins.
  final Duration destroyDuration;

  @override
  State<QuiRouteSettled> createState() => _QuiRouteSettledState();
}

class _QuiRouteSettledState extends State<QuiRouteSettled> {
  final QuiAppearController _controller = QuiAppearController();
  Animation<double>? _routeAnimation;
  ValueListenable<bool>? _gestureNotifier;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation != null) return;

    final route = ModalRoute.of(context);

    if (route == null) {
      _controller.appear();
      _visible = true;
      return;
    }

    final animation = route.animation;
    _routeAnimation = animation;
    animation?.addStatusListener(_handleStatusChanged);

    final navigator = Navigator.maybeOf(context);

    if (navigator != null) {
      _gestureNotifier = navigator.userGestureInProgressNotifier;
      _gestureNotifier!.addListener(_handleGestureChanged);
    }

    _updateVisibility();
  }

  void _handleStatusChanged(AnimationStatus status) {
    _updateVisibility();
  }

  void _handleGestureChanged() {
    _updateVisibility();
  }

  void _updateVisibility() {
    final routeAnimation = _routeAnimation;
    if (routeAnimation == null) return;

    final settled = routeAnimation.status == AnimationStatus.completed;
    final gestureActive = _gestureNotifier?.value ?? false;
    final shouldShow = settled && !gestureActive;

    if (shouldShow == _visible) return;
    _visible = shouldShow;

    if (shouldShow) {
      _controller.appear();
    } else {
      _controller.destroy();
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleStatusChanged);
    _gestureNotifier?.removeListener(_handleGestureChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuiAppear(
      controller: _controller,
      animation: widget.animation,
      appearDuration: widget.appearDuration,
      destroyDuration: widget.destroyDuration,
      child: widget.child,
    );
  }
}

@Preview(name: 'QuiRouteSettled', group: 'Route')
Widget quiRouteSettledPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: QuiRouteSettled(child: Text('Visible after settle', style: TextStyle(fontSize: 24))),
      ),
    ),
  );
}
