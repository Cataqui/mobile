part of 'qui_bottom_sheet.dart';

class _QuiBottomSheetRoute<T> extends PopupRoute<T> {
  _QuiBottomSheetRoute({
    required this.child,
    required this.capturedThemes,
    required this.barrierColor,
    required this.barrierLabel,
    required this.disableAnimations,
    required this.scrollable,
  }) : _scrollableController = scrollable ? DraggableScrollableController() : null;

  static const double _directionMinIntentDistance = 10;
  static const double _dismissMinVelocity = 100;
  static const double _commitThreshold = 0.5;
  static const double _maximumHeightFraction = 0.85;
  static const double _initialScrollableHeightFraction = 1 / 3;
  static const double _extentTolerance = 0.001;

  final Widget child;
  final CapturedThemes capturedThemes;
  final bool disableAnimations;
  final bool scrollable;
  final DraggableScrollableController? _scrollableController;
  final GlobalKey _sheetMeasurementKey = GlobalKey(debugLabel: 'qui_bottom_sheet_measurement');
  bool _isInteractiveDismissActive = false;
  bool _hasNavigatorUserGesture = false;

  double get transitionValue => controller?.value ?? 1;

  double get _initialScrollableExtent => _initialScrollableHeightFraction / _maximumHeightFraction;

  bool get _canDismissFromCurrentSheetExtent {
    final scrollableController = _scrollableController;
    if (scrollableController == null) return true;
    if (!scrollableController.isAttached) return false;

    return scrollableController.size <= _initialScrollableExtent + _extentTolerance;
  }

  double get _sheetHeight {
    final renderObject = _sheetMeasurementKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return 0;

    return renderObject.size.height;
  }

  bool startInteractiveDismiss() {
    final routeController = controller;
    if (!isCurrent || routeController == null || _isInteractiveDismissActive) return false;
    if (routeController.status != AnimationStatus.completed) return false;

    _isInteractiveDismissActive = true;
    navigator?.didStartUserGesture();
    _hasNavigatorUserGesture = true;
    routeController.stop(canceled: false);
    return true;
  }

  void updateInteractiveDismiss({required double closingProgress}) {
    final routeController = controller;
    if (!_isInteractiveDismissActive || routeController == null || disableAnimations) return;

    routeController.value = 1 - closingProgress;
  }

  Future<void> cancelInteractiveDismiss() async {
    final routeController = controller;
    if (!_isInteractiveDismissActive || routeController == null) return;

    if (disableAnimations) {
      routeController.value = 1;
      _stopInteractiveDismiss();
      return;
    }

    final animation = routeController.animateTo(1, duration: reverseTransitionDuration, curve: Curves.easeOutCubic);
    _stopUserGestureWhenAnimationEnds(routeController);
    await animation;
  }

  Future<void> commitInteractiveDismiss() async {
    final routeController = controller;
    final routeNavigator = navigator;
    if (!_isInteractiveDismissActive || routeController == null || routeNavigator == null) return;

    await routeNavigator.maybePop<T>();
    if (isCurrent) {
      await cancelInteractiveDismiss();
      return;
    }

    if (disableAnimations) {
      _stopInteractiveDismiss();
      return;
    }

    routeController.stop(canceled: false);
    final animation = routeController.animateBack(0, duration: reverseTransitionDuration, curve: Curves.easeOutCubic);
    _stopUserGestureWhenAnimationEnds(routeController);
    await animation;
  }

  void _deferStopInteractiveDismiss() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _stopInteractiveDismiss());
  }

  void _stopUserGestureWhenAnimationEnds(AnimationController routeController) {
    if (!routeController.isAnimating) {
      _deferStopInteractiveDismiss();
      return;
    }

    void listener(AnimationStatus status) {
      if (status.isAnimating) return;

      routeController.removeStatusListener(listener);
      _stopInteractiveDismiss();
    }

    routeController.addStatusListener(listener);
  }

  void _stopInteractiveDismiss() {
    if (!_isInteractiveDismissActive) return;

    _isInteractiveDismissActive = false;
    if (!_hasNavigatorUserGesture) return;

    _hasNavigatorUserGesture = false;
    navigator?.didStopUserGesture();
  }

  Widget buildSheetTransition({required Animation<double> animation, required Widget child}) {
    if (disableAnimations) return child;

    return _QuiBottomSheetTransition(
      key: const Key('qui_bottom_sheet_transition'),
      animation: animation,
      isInteractive: () => _isInteractiveDismissActive,
      child: child,
    );
  }

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  @override
  bool get barrierDismissible => true;

  @override
  Widget buildModalBarrier() {
    return _QuiBottomSheetScrimDragSurface<T>(route: this, child: super.buildModalBarrier());
  }

  @override
  Curve get barrierCurve => Curves.easeOutCubic;

  @override
  Duration get transitionDuration => disableAnimations ? Duration.zero : const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => disableAnimations ? Duration.zero : const Duration(milliseconds: 270);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final sheet = capturedThemes.wrap(_QuiBottomSheetSurface(route: this, animation: animation, child: child));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(systemNavigationBarIconBrightness: Brightness.light),
      child: sheet,
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

  @override
  void dispose() {
    _stopInteractiveDismiss();
    _scrollableController?.dispose();
    super.dispose();
  }
}
