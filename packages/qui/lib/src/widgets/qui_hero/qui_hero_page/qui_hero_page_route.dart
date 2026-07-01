import 'package:flutter/material.dart';

/// A transparent [PageRoute] used by QuiHeroPage for hero transitions.
///
/// [QuiHeroPageRoute] provides:
///   * `opaque: false` — keeps the source route composited underneath so the
///     hero flight is visible against the previous screen.
///   * [HeroMode] gating — when [transitionDuration] is [Duration.zero],
///     heroes are disabled (reduced-motion).
///   * Interactive pop API — [startInteractivePop], [updateInteractivePop],
///     [cancelInteractivePop], and [commitInteractivePop] for drag-to-close.
///
/// Use [maybeOf] from a descendant widget to access the route and drive
/// interactive closing:
///
/// ```dart
/// final route = QuiHeroPageRoute.maybeOf(context);
/// route?.startInteractivePop();
/// ```
class QuiHeroPageRoute extends PageRoute<void> {
  /// Creates a [QuiHeroPageRoute].
  ///
  /// The [_builder] produces the page content. [transitionDuration] and
  /// [reverseTransitionDuration] control the hero animation timing.
  QuiHeroPageRoute({
    required this._builder,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    super.settings,
  });

  final WidgetBuilder _builder;

  bool _isInteractivePopActive = false;
  bool _hasNavigatorUserGesture = false;

  /// The current transition progress (1.0 = fully open, 0.0 = fully closed).
  double get transitionValue => controller?.value ?? 1;

  /// Whether an interactive pop gesture is currently in progress.
  bool get isInteractivePopActive => _isInteractivePopActive;

  /// Returns the [QuiHeroPageRoute] from the nearest [ModalRoute] ancestor, or
  /// `null` if the current route is not a [QuiHeroPageRoute].
  static QuiHeroPageRoute? maybeOf(BuildContext context) {
    final route = ModalRoute.of(context);

    if (route is QuiHeroPageRoute) return route;
    return null;
  }

  /// Begins an interactive pop gesture.
  ///
  /// Stops the route's [AnimationController] and notifies the navigator that
  /// a user gesture has started. Returns `true` if the gesture was
  /// successfully initiated.
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

  /// Updates the interactive pop progress.
  ///
  /// [closingProgress] ranges from `0.0` (fully open) to `1.0` (fully
  /// closed). This directly sets the route's [AnimationController.value].
  void updateInteractivePop({required double closingProgress}) {
    final routeController = controller;
    if (!_isInteractivePopActive || routeController == null) return;

    routeController.value = (1 - closingProgress).clamp(0, 1);
  }

  /// Cancels the interactive pop and animates the route back to the fully
  /// open position.
  Future<void> cancelInteractivePop() async {
    final routeController = controller;
    if (!_isInteractivePopActive || routeController == null) return;

    final animation = routeController.animateTo(1, duration: reverseTransitionDuration, curve: Curves.easeOutCubic);
    _stopUserGestureWhenAnimationEnds(routeController);
    await animation;
  }

  /// Commits the interactive pop and navigates back.
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
