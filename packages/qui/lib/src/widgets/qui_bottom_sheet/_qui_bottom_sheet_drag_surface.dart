part of 'qui_bottom_sheet.dart';

class _QuiBottomSheetDragSurface<T> extends StatefulWidget {
  const _QuiBottomSheetDragSurface({required this.route, required this.child});

  final _QuiBottomSheetRoute<T> route;
  final Widget child;

  @override
  State<_QuiBottomSheetDragSurface<T>> createState() => _QuiBottomSheetDragSurfaceState<T>();
}

class _QuiBottomSheetDragSurfaceState<T> extends State<_QuiBottomSheetDragSurface<T>> {
  static const int _flingCooldownUs = 120 * 1000;
  static const double _scrollAtTopTolerance = 0.5;
  static const double _scrollAwayThreshold = 5;
  static const double _fastScrollDeltaThreshold = 15;
  int? _activePointer;
  bool _isDragActive = false;
  bool _isReducedMotionDrag = false;
  bool _isStartingScrollHold = false;
  bool _hasVerticalScrollable = false;
  bool _scrollWasAwayFromTop = false;
  double _closingProgress = 0;
  double _dragOriginPointerY = 0;
  double _accumulatedPointerX = 0;
  double _accumulatedPointerY = 0;
  double _sheetHeight = 0;
  double _peakScrollDelta = 0;
  int? _flingReachedTopAtUs;
  ScrollHoldController? _activeScrollHold;
  BuildContext? _activeScrollContext;
  ScrollPosition? _activeScrollPosition;
  ScrollableState? _activeScrollableState;
  ScrollMetrics? _activeVerticalMetrics;
  VelocityTracker? _velocityTracker;

  bool get _isScrollAtTop {
    final metrics = _activeVerticalMetrics;
    if (!_hasVerticalScrollable || metrics == null) return true;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent + _scrollAtTopTolerance) return true;
    return metrics.pixels <= metrics.minScrollExtent + _scrollAtTopTolerance;
  }

  bool get _canStartDrag {
    if (!_isScrollAtTop) return false;
    if (!widget.route._canDismissFromCurrentSheetExtent) return false;

    final flingReachedTopAtUs = _flingReachedTopAtUs;
    if (flingReachedTopAtUs == null) return true;

    return SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds - flingReachedTopAtUs >=
        _flingCooldownUs;
  }

  bool _hasClearDownwardIntent() {
    final horizontalDistance = _accumulatedPointerX.abs();
    final verticalDistance = _accumulatedPointerY.abs();
    return verticalDistance >= _QuiBottomSheetRoute._directionMinIntentDistance &&
        verticalDistance > horizontalDistance &&
        _accumulatedPointerY > 0;
  }

  bool _startDrag(PointerMoveEvent event) {
    if (!_hasClearDownwardIntent()) return false;
    if (!_canStartDrag) return false;

    final sheetHeight = context.size?.height ?? 0;
    if (sheetHeight <= 0) return false;
    if (!widget.route.startInteractiveDismiss()) return false;

    _isDragActive = true;
    _sheetHeight = sheetHeight;
    _closingProgress = 1 - widget.route.transitionValue;
    _dragOriginPointerY = _accumulatedPointerY - event.delta.dy;
    _holdActiveScrollPosition();
    return true;
  }

  void _updateDragProgress() {
    if (_sheetHeight <= 0) return;

    final rawClosingDistance = _accumulatedPointerY - _dragOriginPointerY;
    _closingProgress = (rawClosingDistance / _sheetHeight).clamp(0, 1);
    widget.route.updateInteractiveDismiss(closingProgress: _closingProgress);
    _restoreActiveScrollPosition();
  }

  bool _shouldCommitDrag(Velocity velocity) {
    if (velocity.isSwipeDown(minVelocity: _QuiBottomSheetRoute._dismissMinVelocity)) return true;
    if (velocity.isSwipeUp(minVelocity: _QuiBottomSheetRoute._dismissMinVelocity)) return false;
    return _closingProgress >= _QuiBottomSheetRoute._commitThreshold;
  }

  void _finishDrag({required Velocity velocity}) {
    if (!_isDragActive) {
      _resetGestureState();
      return;
    }

    final shouldCommit = _shouldCommitDrag(velocity);
    _resetGestureState();
    if (shouldCommit) {
      unawaited(widget.route.commitInteractiveDismiss());
      return;
    }

    unawaited(widget.route.cancelInteractiveDismiss());
  }

  void _cancelDrag() {
    final wasDragActive = _isDragActive;
    _resetGestureState();
    if (!wasDragActive) return;

    unawaited(widget.route.cancelInteractiveDismiss());
  }

  void _resetGestureState() {
    _isDragActive = false;
    _isReducedMotionDrag = false;
    _closingProgress = 0;
    _dragOriginPointerY = 0;
    _accumulatedPointerX = 0;
    _accumulatedPointerY = 0;
    _sheetHeight = 0;
    _velocityTracker = null;
    _flingReachedTopAtUs = null;
    _releaseActiveScrollHold();
  }

  void _updateScrollMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) return;

    _hasVerticalScrollable = true;
    _activeVerticalMetrics = metrics;
  }

  void _updateActiveScrollPosition(BuildContext? scrollContext, {required bool forceRefresh}) {
    if (scrollContext == null) return;
    if (!forceRefresh && identical(scrollContext, _activeScrollContext) && _activeScrollPosition != null) return;

    if (forceRefresh || !identical(scrollContext, _activeScrollContext)) {
      _activeScrollContext = scrollContext;
      _activeScrollableState = Scrollable.of(scrollContext);
    }

    final scrollPosition = _activeScrollableState?.position;
    if (scrollPosition == null || identical(scrollPosition, _activeScrollPosition)) return;

    _releaseActiveScrollHold();
    _activeScrollPosition = scrollPosition;
    if (_isDragActive && !_isReducedMotionDrag) {
      _holdActiveScrollPosition();
    }
  }

  void _holdActiveScrollPosition() {
    if (_isReducedMotionDrag) return;
    if (_activeScrollHold != null || _isStartingScrollHold) return;

    final scrollPosition = _activeScrollPosition;
    if (scrollPosition == null) return;

    _isStartingScrollHold = true;
    try {
      _activeScrollHold = scrollPosition.hold(() {
        _activeScrollHold = null;
      });
    } finally {
      _isStartingScrollHold = false;
    }
  }

  void _releaseActiveScrollHold() {
    final activeScrollHold = _activeScrollHold;
    if (activeScrollHold == null) return;

    _activeScrollHold = null;
    activeScrollHold.cancel();
  }

  void _restoreActiveScrollPosition() {
    if (!_isDragActive || _isReducedMotionDrag) return;

    final scrollPosition = _activeScrollPosition;
    if (scrollPosition == null) return;
    if (scrollPosition.pixels >= scrollPosition.minScrollExtent) return;

    scrollPosition.correctPixels(scrollPosition.minScrollExtent);
  }

  void _trackScrollMovement({required ScrollMetrics metrics, required double scrollDelta, required bool isBallistic}) {
    if (_activePointer != null && _flingReachedTopAtUs != null) {
      _flingReachedTopAtUs = SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    }

    if (metrics.pixels > metrics.minScrollExtent + _scrollAwayThreshold) {
      _scrollWasAwayFromTop = true;
      _flingReachedTopAtUs = null;
      _peakScrollDelta = 0;
      return;
    }

    if (!_scrollWasAwayFromTop) return;

    if (_peakScrollDelta <= _fastScrollDeltaThreshold && scrollDelta.abs() > _peakScrollDelta) {
      _peakScrollDelta = scrollDelta.abs();
    }

    if (_flingReachedTopAtUs != null) return;
    if (metrics.pixels > metrics.minScrollExtent + _scrollAtTopTolerance) return;

    _scrollWasAwayFromTop = false;
    if (isBallistic || _peakScrollDelta > _fastScrollDeltaThreshold) {
      _flingReachedTopAtUs = SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    }
    _peakScrollDelta = 0;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    _updateScrollMetrics(notification.metrics);
    _updateActiveScrollPosition(notification.context, forceRefresh: notification is ScrollStartNotification);
    _restoreDragScrollPosition(notification);
    if (notification is ScrollUpdateNotification) {
      _trackScrollMovement(
        metrics: notification.metrics,
        scrollDelta: notification.scrollDelta ?? 0,
        isBallistic: notification.dragDetails == null,
      );
    }

    return false;
  }

  void _restoreDragScrollPosition(ScrollNotification notification) {
    if (!_isDragActive || _isReducedMotionDrag) return;
    if (notification is! ScrollUpdateNotification && notification is! OverscrollNotification) return;
    if (notification.metrics.pixels >= notification.metrics.minScrollExtent) return;

    _activeScrollPosition?.correctPixels(notification.metrics.minScrollExtent);
  }

  bool _handleScrollMetricsNotification(ScrollMetricsNotification notification) {
    _updateScrollMetrics(notification.metrics);
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;

    _activePointer = event.pointer;
    _isReducedMotionDrag = MediaQuery.disableAnimationsOf(context);
    _velocityTracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    _accumulatedPointerX = 0;
    _accumulatedPointerY = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    _accumulatedPointerX += event.delta.dx;
    _accumulatedPointerY += event.delta.dy;
    if (!_isDragActive) {
      if (!_startDrag(event)) return;
    }

    _updateDragProgress();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final velocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
    _activePointer = null;
    _finishDrag(velocity: velocity);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    _cancelDrag();
  }

  @override
  void dispose() {
    _releaseActiveScrollHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuiDragResistance(
      top: !widget.route.scrollable,
      bottom: false,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        behavior: HitTestBehavior.deferToChild,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleScrollMetricsNotification,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
