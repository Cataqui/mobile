import 'package:flutter/material.dart';

import '../qui_hero.dart';
import '../qui_hero_extension/qui_hero_drag_to_close_extension/qui_hero_drag_to_close_extension.dart';
import 'qui_hero_page.dart';

/// A transparent [PageRoute] that manages hero flights for [QuiHeroPage].
///
/// ## What it provides
///
/// [QuiHeroPageRoute] is created by [QuiHeroPage.createRoute] and offers:
///
///  * **Transparent compositing** — `opaque: false` keeps the source route
///    rendered underneath so hero elements fly against the original background
///    instead of a blank canvas.
///  * **Reduced-motion gating** — when [transitionDuration] is [Duration.zero]
///    (set automatically by [QuiHeroPage] when reduced motion is enabled),
///    [HeroMode] is disabled so no heroes animate.
///  * **Interactive pop API** — [startInteractivePop], [updateInteractivePop],
///    [cancelInteractivePop], and [commitInteractivePop] expose a
///    programmatic drag-to-close surface for extensions like
///    [QuiHeroDragToCloseExtension].
///
/// ## Accessing the route from descendants
///
/// Use [maybeOf] from any widget inside the route to obtain a reference:
///
/// ```dart
/// final route = QuiHeroPageRoute.maybeOf(context);
/// if (route != null && route.isInteractivePopActive) {
///   // Hide dismiss affordances during the gesture.
/// }
/// ```
///
/// ## Interactive pop lifecycle
///
/// The interactive pop API follows a three-phase lifecycle:
///
///  1. **Start** — call [startInteractivePop] to begin. This stops the
///     route's [AnimationController] and notifies the [Navigator] that a
///     user gesture is in progress. Returns `true` on success.
///  2. **Update** — call [updateInteractivePop] repeatedly as the gesture
///     progresses, passing a `closingProgress` from `0.0` (fully open) to
///     `1.0` (fully closed). The route's [transitionValue] reflects the
///     inverse: `1.0 - closingProgress`.
///  3. **Cancel or commit** — call [cancelInteractivePop] to animate back
///     open, or [commitInteractivePop] to dismiss the route.
///
/// See also:
///  * [QuiHeroPage], the [Page] that creates this route.
///  * [QuiHeroDragToCloseExtension], a built-in extension that drives the
///    interactive pop API from drag gestures.
///  * [QuiHero], the hero widget that flies during the transition.
class QuiHeroPageRoute extends PageRoute<void> {
  /// Creates a [QuiHeroPageRoute].
  ///
  /// Prefer using [QuiHeroPage] directly — it creates the route automatically
  /// and handles reduced-motion detection. Create a [QuiHeroPageRoute]
  /// manually only when you need to control the route independently of a
  /// [Page] subclass.
  QuiHeroPageRoute({
    required this._builder,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    super.settings,
  });

  final WidgetBuilder _builder;

  bool _isInteractivePopActive = false;
  bool _hasNavigatorUserGesture = false;

  /// The current transition progress, from `0.0` (fully closed) to `1.0`
  /// (fully open).
  ///
  /// When an interactive pop is active, this value is driven by the
  /// [updateInteractivePop] method rather than the default route
  /// animation.
  double get transitionValue => controller?.value ?? 1;

  /// Whether an interactive pop gesture is currently in progress.
  ///
  /// Returns `true` after a successful call to [startInteractivePop] and
  /// `false` after [cancelInteractivePop] or [commitInteractivePop]
  /// completes.
  bool get isInteractivePopActive => _isInteractivePopActive;

  /// Returns the nearest [QuiHeroPageRoute] ancestor from [context], or
  /// `null` if the current route is not a [QuiHeroPageRoute].
  ///
  /// This is the entry point for extensions that need to drive the
  /// interactive pop API. Call it from any descendant widget to access
  /// [startInteractivePop], [updateInteractivePop], [cancelInteractivePop],
  /// and [commitInteractivePop].
  ///
  /// ```dart
  /// final route = QuiHeroPageRoute.maybeOf(context);
  /// if (route != null) {
  ///   route.startInteractivePop();
  /// }
  /// ```
  static QuiHeroPageRoute? maybeOf(BuildContext context) {
    final route = ModalRoute.of(context);

    if (route is QuiHeroPageRoute) return route;
    return null;
  }

  /// Begins an interactive pop gesture.
  ///
  /// Stops the route's [AnimationController] and notifies the [Navigator]
  /// that a user gesture has started. After calling this method,
  /// [isInteractivePopActive] returns `true`.
  ///
  /// Returns `true` if the gesture was successfully initiated. Returns
  /// `false` if:
  ///
  ///  * This route is not the current route.
  ///  * The route's [AnimationController] is `null`.
  ///  * An interactive pop is already active.
  ///  * The route's animation is not in the [AnimationStatus.completed]
  ///    state.
  bool startInteractivePop() {
    final routeController = controller;
    if (!isCurrent || routeController == null || _isInteractivePopActive) return false;
    if (routeController.status != AnimationStatus.completed) return false;

    _isInteractivePopActive = true;
    navigator?.didStartUserGesture();
    _hasNavigatorUserGesture = true;
    routeController.stop(canceled: false);
    return true;
  }

  /// Updates the translation progress of an active interactive pop.
  ///
  /// [closingProgress] ranges from `0.0` (fully open) to `1.0` (fully
  /// closed). The route's [transitionValue] is set to
  /// `1.0 - closingProgress`, clamped between `0` and `1`.
  ///
  /// This is a no-op if no interactive pop is active.
  void updateInteractivePop({required double closingProgress}) {
    final routeController = controller;
    if (!_isInteractivePopActive || routeController == null) return;

    routeController.value = (1 - closingProgress).clamp(0, 1);
  }

  /// Cancels the interactive pop and animates the route back to the fully
  /// open position.
  ///
  /// The animation uses [reverseTransitionDuration] and
  /// [Curves.easeOutCubic]. After the animation completes,
  /// [isInteractivePopActive] returns `false` and the navigator is notified
  /// that the user gesture has ended.
  Future<void> cancelInteractivePop() async {
    final routeController = controller;
    if (!_isInteractivePopActive || routeController == null) return;

    final animation = routeController.animateTo(1, duration: reverseTransitionDuration, curve: Curves.easeOutCubic);
    _stopUserGestureWhenAnimationEnds(routeController);
    await animation;
  }

  /// Commits the interactive pop and pops the route.
  ///
  /// Calls [Navigator.pop] to dismiss the route. If the route's
  /// [AnimationController] is still animating, the user gesture cleanup is
  /// deferred until the animation completes.
  void commitInteractivePop() {
    final routeController = controller;
    if (!_isInteractivePopActive || routeController == null) return;

    navigator?.pop();
    if (routeController.isAnimating) {
      _stopUserGestureWhenAnimationEnds(routeController);
      return;
    }

    _stopInteractivePop();
  }

  void _stopUserGestureWhenAnimationEnds(AnimationController routeController) {
    if (!routeController.isAnimating) {
      _stopInteractivePop();
      return;
    }

    void listener(AnimationStatus status) {
      if (status.isAnimating) return;

      routeController.removeStatusListener(listener);
      _stopInteractivePop();
    }

    routeController.addStatusListener(listener);
  }

  void _stopInteractivePop() {
    if (!_isInteractivePopActive) return;

    _isInteractivePopActive = false;
    if (!_hasNavigatorUserGesture) return;

    _hasNavigatorUserGesture = false;
    navigator?.didStopUserGesture();
  }

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get fullscreenDialog => false;

  @override
  bool get maintainState => true;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final disableAnimations = transitionDuration == Duration.zero;

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: HeroMode(enabled: !disableAnimations, child: _builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
