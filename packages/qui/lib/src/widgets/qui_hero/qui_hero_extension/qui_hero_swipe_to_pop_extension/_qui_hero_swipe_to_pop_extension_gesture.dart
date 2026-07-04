part of 'qui_hero_swipe_to_pop_extension.dart';

class _QuiHeroSwipeToPopExtensionGesture extends StatefulWidget {
  const _QuiHeroSwipeToPopExtensionGesture({
    required this.child,
    this.scrollController,
    this.commitThreshold = 0.5,
    this.sensibility = 0.5,
    this.onSwipeStateChanged,
  });

  final Widget child;
  final ScrollController? scrollController;
  final double commitThreshold;
  final double sensibility;
  final ValueChanged<QuiHeroSwipeToPopState>? onSwipeStateChanged;

  @override
  State<_QuiHeroSwipeToPopExtensionGesture> createState() => _QuiHeroSwipeToPopExtensionGestureState();
}

class _QuiHeroSwipeToPopExtensionGestureState extends State<_QuiHeroSwipeToPopExtensionGesture> {
  int? _activePointer;
  bool _isInteractivePopActive = false;
  bool _isReducedMotionSwipe = false;
  double _closeSwipeDistance = 1;
  double _interactiveClosingProgress = 0;
  VelocityTracker? _velocityTracker;
  QuiHeroPageRoute? _activeRoute;

  bool _scrollWasAwayFromTop = false;
  double _peakScrollDelta = 0;
  int? _flingReachedTopAtUs;

  static const int _flingCooldownUs = 200 * 1000;
  static const double _scrollAtTopTolerance = 0.5;
  static const double _scrollAwayThreshold = 5;
  static const double _fastScrollDeltaThreshold = 15;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.deferToChild,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.child,
      ),
    );
  }

  double _swipeToPopHeightFraction() {
    if (widget.sensibility <= 0.5) return 0.5 * (1 + ((0.5 - widget.sensibility) / 0.5));
    return 0.5 * (1 - (((widget.sensibility - 0.5) / 0.5) * 0.75));
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;

    _activePointer = event.pointer;
    _activeRoute = null;
    _isReducedMotionSwipe = MediaQuery.disableAnimationsOf(context);
    _velocityTracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    final closeSwipeDistance = MediaQuery.sizeOf(context).height * _swipeToPopHeightFraction();
    _closeSwipeDistance = closeSwipeDistance <= 0 ? 1 : closeSwipeDistance;
    _interactiveClosingProgress = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    if (!_isInteractivePopActive && event.delta.dy <= 0) return;
    if (!_isInteractivePopActive && !_canStartSwipeToPop) return;

    if (!_isInteractivePopActive) {
      if (_isReducedMotionSwipe) {
        _isInteractivePopActive = true;
        widget.onSwipeStateChanged?.call(QuiHeroSwipeToPopState.dragging);
      } else if (!_startInteractivePop()) {
        return;
      }
    }

    _interactiveClosingProgress = (_interactiveClosingProgress + (event.delta.dy / _closeSwipeDistance))
        .clamp(0, 1)
        .toDouble();

    if (_isReducedMotionSwipe) return;

    _activeRoute?.updateInteractivePop(closingProgress: _interactiveClosingProgress);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final swipeVelocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
    _activePointer = null;
    _finishInteractivePop(swipeVelocity: swipeVelocity);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    _cancelInteractivePop();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (widget.scrollController == null) return false;
    if (notification is! ScrollUpdateNotification) return false;

    final metrics = notification.metrics;
    final scrollDelta = notification.scrollDelta ?? 0;
    final isBallistic = notification.dragDetails == null;

    if (_activePointer != null && _flingReachedTopAtUs != null) {
      _flingReachedTopAtUs = SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    }

    if (metrics.pixels > metrics.minScrollExtent + _scrollAwayThreshold) {
      _scrollWasAwayFromTop = true;
      _flingReachedTopAtUs = null;
      _peakScrollDelta = 0;
      return false;
    }

    if (!_scrollWasAwayFromTop) return false;

    if (_peakScrollDelta <= _fastScrollDeltaThreshold && scrollDelta.abs() > _peakScrollDelta) {
      _peakScrollDelta = scrollDelta.abs();
    }

    if (_flingReachedTopAtUs != null) return false;
    if (metrics.pixels > metrics.minScrollExtent + _scrollAtTopTolerance) return false;

    _scrollWasAwayFromTop = false;
    if (isBallistic || _peakScrollDelta > _fastScrollDeltaThreshold) {
      _flingReachedTopAtUs = SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    }
    _peakScrollDelta = 0;

    return false;
  }

  bool _startInteractivePop() {
    final route = QuiHeroPageRoute.maybeOf(context);
    assert(
      _debugAssertUsesQuiHeroPageRoute(route),
      'QuiHeroSwipeToPopExtension must be used inside a QuiHeroPageRoute.',
    );

    if (route == null) return false;
    if (!route.startInteractivePop()) return false;

    _activeRoute = route;
    _isInteractivePopActive = true;
    _interactiveClosingProgress = 0;
    widget.onSwipeStateChanged?.call(QuiHeroSwipeToPopState.dragging);
    return true;
  }

  bool _debugAssertUsesQuiHeroPageRoute(QuiHeroPageRoute? route) {
    if (route != null) return true;

    throw FlutterError.fromParts([
      ErrorSummary('QuiHeroSwipeToPopExtension must be used inside a QuiHeroPageRoute.'),
      ErrorDescription(
        'QuiHeroSwipeToPopExtension drives the interactive pop API owned by QuiHeroPageRoute, '
        'so it cannot work from a regular route.',
      ),
      ErrorHint(
        'Create the destination page with QuiHeroPage, then pass QuiHeroSwipeToPopExtension '
        'to the destination QuiHero extensions list.',
      ),
    ]);
  }

  void _finishInteractivePop({required Velocity swipeVelocity}) {
    if (!_isInteractivePopActive) return;

    if (_isReducedMotionSwipe) {
      _finishReducedMotionInteractivePop(swipeVelocity: swipeVelocity);
      return;
    }

    final route = _activeRoute;
    if (route == null) {
      _restoreInteractiveChrome();
      return;
    }

    if (_shouldCommitInteractivePop(swipeVelocity: swipeVelocity)) {
      route.commitInteractivePop();
      _resetGestureState();
      return;
    }

    _cancelInteractivePop();
  }

  void _finishReducedMotionInteractivePop({required Velocity swipeVelocity}) {
    if (_shouldCommitInteractivePop(swipeVelocity: swipeVelocity)) {
      _resetGestureState();
      unawaited(Navigator.of(context).maybePop());
      return;
    }

    _restoreInteractiveChrome();
  }

  bool _shouldCommitInteractivePop({required Velocity swipeVelocity}) {
    return _interactiveClosingProgress >= widget.commitThreshold || swipeVelocity.isSwipeDown();
  }

  void _cancelInteractivePop() {
    final route = _activeRoute;
    if (route == null) {
      _restoreInteractiveChrome();
      return;
    }

    unawaited(route.cancelInteractivePop().whenComplete(_restoreInteractiveChrome));
  }

  void _resetGestureState() {
    _isInteractivePopActive = false;
    _isReducedMotionSwipe = false;
    _closeSwipeDistance = 1;
    _interactiveClosingProgress = 0;
    _velocityTracker = null;
    _activeRoute = null;
    _flingReachedTopAtUs = null;
  }

  void _restoreInteractiveChrome() {
    if (!mounted) return;

    _resetGestureState();
    widget.onSwipeStateChanged?.call(QuiHeroSwipeToPopState.idle);
  }

  bool get _isScrollAtTop {
    final controller = widget.scrollController;
    if (controller == null) return true;
    if (!controller.hasClients) return true;

    final position = controller.position;
    return position.pixels <= position.minScrollExtent + _scrollAtTopTolerance;
  }

  bool get _canStartSwipeToPop {
    if (!_isScrollAtTop) return false;
    if (_flingReachedTopAtUs == null) return true;
    return SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds - _flingReachedTopAtUs! >= _flingCooldownUs;
  }
}
