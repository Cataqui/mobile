import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part '_qui_swipe_to_pop_surface_handoff_scope.dart';
part 'qui_swipe_to_pop_handoff_state.dart';

/// A route-content wrapper that adds capped swipe-to-pop behavior.
///
/// Wrap the visible surface of a page when users should be able to drag the
/// route slightly, preview it under their finger, and release to
/// pop the current route. The preview is local to the widget:
/// [QuiSwipeToPopSurface] does not drive a route animation controller,
/// and works with any route type that can be dismissed by [Navigator.maybePop].
///
/// ## Scroll safety
///
/// The wrapper listens to descendant vertical scroll notifications. It only
/// starts the pop preview when no scrollable is present, when the content fits
/// the viewport, or when the active scrollable is already at the top. Fast
/// scrolls or flings that recently reached the top start a short cooldown so
/// a user's attempt to quickly return to the top is not mistaken for a route
/// dismissal.
///
/// ```dart
/// QuiSwipeToPopSurface(
///   child: Scaffold(
///     body: CustomScrollView(
///       slivers: [
///         SliverToBoxAdapter(child: Text('Details')),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// See also:
///  * [Navigator.maybePop], which receives the committed pop request.
///  * [ScrollNotification], which powers scroll-safe activation.
class QuiSwipeToPopSurface extends StatefulWidget {
  /// Creates a swipe-to-pop wrapper around [child].
  const QuiSwipeToPopSurface({
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.sensibility = 0.3,
    this.swipeDown = true,
    this.swipeRight = false,
    super.key,
  }) : assert(sensibility >= 0.0 && sensibility <= 1.0, 'sensibility must be between 0.0 and 1.0.');

  /// The route content that follows the user's finger during the preview.
  final Widget child;

  /// The border radius applied as the route content is previewed.
  ///
  /// The preview starts with square corners and interpolates toward
  /// [borderRadius] as the user drags. When the drag reaches the commit
  /// threshold, the preview uses the full [borderRadius] value. Leave this as
  /// [BorderRadius.zero] when the wrapped route should stay square while it is
  /// being previewed.
  final BorderRadiusGeometry borderRadius;

  /// How strongly the preview surface reacts to the user's drag.
  ///
  /// A value of `0.5` follows the finger. Higher values make the surface more
  /// reactive, so small drags move the preview farther. Lower values make the
  /// surface heavier, so the user must drag farther to move the preview the
  /// same distance. Release velocity is still handled separately, so a fast
  /// fling in an enabled direction can pop even when [sensibility] is low.
  final double sensibility;

  /// Whether downward swipes can start the pop preview.
  ///
  /// When this is `true`, the gesture must start with clear downward intent.
  /// Descendant vertical scrollables still receive normal scroll gestures until
  /// they are at the top.
  final bool swipeDown;

  /// Whether rightward swipes can start the pop preview.
  ///
  /// When this is `true`, a clear rightward gesture can start the preview even
  /// without any downward movement. This is useful for back gestures that should
  /// begin with a horizontal swipe.
  final bool swipeRight;

  /// The active swipe-to-pop preview state above [context], if any.
  ///
  /// hero flights can use this to continue a committed pop from the same
  /// preview state the user saw during the drag. It returns `null` when no
  /// [QuiSwipeToPopSurface] preview is visually active.
  static QuiSwipeToPopHandoffState? maybeHandoffStateOf(BuildContext context) {
    return _QuiSwipeToPopSurfaceHandoffScope.maybeStateOf(context);
  }

  @override
  State<QuiSwipeToPopSurface> createState() => _QuiSwipeToPopSurfaceState();
}

class _QuiSwipeToPopSurfaceState extends State<QuiSwipeToPopSurface> with SingleTickerProviderStateMixin {
  static const int _flingCooldownUs = 120 * 1000;
  static const double _scrollAtTopTolerance = 0.5;
  static const double _scrollAwayThreshold = 5;
  static const double _fastScrollDeltaThreshold = 15;
  static const double _directionMinIntentDistance = 10;
  static const double _previewHeightFraction = 0.18;
  static const double _previewMaxDistance = 160;
  static const double _minPreviewScale = 0.88;
  static const double _commitThreshold = 0.5;

  late final AnimationController _restoreAnimationController;

  int? _activePointer;
  bool _isPreviewDragActive = false;
  bool _isPointerDirectionRejected = false;
  bool _isReducedMotionSwipe = false;
  bool _isStartingScrollHold = false;
  bool _hasVerticalScrollable = false;
  bool _scrollWasAwayFromTop = false;
  double _previewDistance = 1;
  double _visualClosingProgress = 0;
  Axis? _activeSwipeAxis;
  Offset _accumulatedPointerOffset = Offset.zero;
  double _peakScrollDelta = 0;
  int? _flingReachedTopAtUs;
  Offset _dragOffset = Offset.zero;
  Offset _rawDragOffset = Offset.zero;
  Offset _restoreStartOffset = Offset.zero;
  double _restoreStartProgress = 0;
  ScrollHoldController? _activeScrollHold;
  ScrollPosition? _activeScrollPosition;
  ScrollMetrics? _activeVerticalMetrics;
  VelocityTracker? _velocityTracker;

  double get _previewScale {
    final easedProgress = Curves.easeOutCubic.transform(_visualClosingProgress);
    return 1 - ((1 - _minPreviewScale) * easedProgress);
  }

  double get _previewBorderRadiusProgress {
    final thresholdProgress = (_visualClosingProgress / _commitThreshold).clamp(0, 1).toDouble();
    return Curves.easeOutCubic.transform(thresholdProgress);
  }

  BorderRadiusGeometry get _previewBorderRadius {
    return BorderRadiusGeometry.lerp(BorderRadius.zero, widget.borderRadius, _previewBorderRadiusProgress)!;
  }

  Clip get _previewClipBehavior {
    if (_visualClosingProgress == 0) return Clip.none;
    if (widget.borderRadius == BorderRadius.zero) return Clip.none;
    return Clip.antiAlias;
  }

  double get _dragReactionMultiplier {
    return 0.1 + (widget.sensibility * 1.8);
  }

  bool get _isScrollAtTop {
    final metrics = _activeVerticalMetrics;
    if (!_hasVerticalScrollable || metrics == null) return true;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent + _scrollAtTopTolerance) return true;
    return metrics.pixels <= metrics.minScrollExtent + _scrollAtTopTolerance;
  }

  bool get _canStartSwipeToPop {
    if (!_isScrollAtTop) return false;
    final flingReachedTopAtUs = _flingReachedTopAtUs;
    if (flingReachedTopAtUs == null) return true;
    return SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds - flingReachedTopAtUs >=
        _flingCooldownUs;
  }

  double _primaryDistance({required Offset dragOffset, required Axis axis}) {
    switch (axis) {
      case Axis.horizontal:
        return dragOffset.dx;
      case Axis.vertical:
        return dragOffset.dy;
    }
  }

  Offset _withPrimaryDistance({required Offset dragOffset, required Axis axis, required double primaryDistance}) {
    switch (axis) {
      case Axis.horizontal:
        return Offset(primaryDistance, dragOffset.dy);
      case Axis.vertical:
        return Offset(dragOffset.dx, primaryDistance);
    }
  }

  void _updatePreviewDistanceForAxis(Axis axis) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenDistance = switch (axis) {
      Axis.horizontal => screenSize.width,
      Axis.vertical => screenSize.height,
    };
    final previewDistance = math.min(screenDistance * _previewHeightFraction, _previewMaxDistance);
    _previewDistance = previewDistance <= 0 ? 1 : previewDistance;
  }

  double _dragOffsetProgress({required Offset dragOffset}) {
    final activeSwipeAxis = _activeSwipeAxis ?? Axis.vertical;
    return (_primaryDistance(dragOffset: dragOffset, axis: activeSwipeAxis) / _previewDistance).clamp(0, 1).toDouble();
  }

  Offset _clampedDragOffset(Offset dragOffset) {
    final activeSwipeAxis = _activeSwipeAxis ?? Axis.vertical;
    final primaryDistance = _primaryDistance(dragOffset: dragOffset, axis: activeSwipeAxis);
    if (primaryDistance <= 0) {
      return _withPrimaryDistance(dragOffset: dragOffset, axis: activeSwipeAxis, primaryDistance: 0);
    }
    if (primaryDistance <= _previewDistance) return dragOffset;

    final overflowDistance = primaryDistance - _previewDistance;
    final maxOverflowDistance = math.min(_previewDistance * 0.75, 96);
    final resistanceDistance = _previewDistance * 1.4;
    final resistedOverflowDistance = maxOverflowDistance * (1 - math.exp(-overflowDistance / resistanceDistance));

    return _withPrimaryDistance(
      dragOffset: dragOffset,
      axis: activeSwipeAxis,
      primaryDistance: _previewDistance + resistedOverflowDistance,
    );
  }

  Axis? _resolveSwipeStartAxis() {
    final horizontalDistance = _accumulatedPointerOffset.dx.abs();
    final verticalDistance = _accumulatedPointerOffset.dy.abs();
    final isClearHorizontalIntent =
        horizontalDistance >= _directionMinIntentDistance && horizontalDistance >= verticalDistance;
    if (isClearHorizontalIntent && widget.swipeRight && _accumulatedPointerOffset.dx > 0) {
      return Axis.horizontal;
    }

    final isClearVerticalIntent =
        verticalDistance >= _directionMinIntentDistance && verticalDistance > horizontalDistance;
    if (isClearVerticalIntent && widget.swipeDown && _accumulatedPointerOffset.dy > 0) {
      return Axis.vertical;
    }

    return null;
  }

  bool _shouldRejectSwipeStart() {
    final horizontalDistance = _accumulatedPointerOffset.dx.abs();
    final verticalDistance = _accumulatedPointerOffset.dy.abs();
    final isClearHorizontalIntent =
        horizontalDistance >= _directionMinIntentDistance && horizontalDistance >= verticalDistance;
    if (isClearHorizontalIntent) return !widget.swipeRight || _accumulatedPointerOffset.dx <= 0;

    final isClearVerticalIntent =
        verticalDistance >= _directionMinIntentDistance && verticalDistance > horizontalDistance;
    if (isClearVerticalIntent && _accumulatedPointerOffset.dy > 0) return !widget.swipeDown;

    return false;
  }

  void _handleRestoreTick() {
    final easedProgress = Curves.easeOutCubic.transform(_restoreAnimationController.value);
    setState(() {
      _dragOffset = Offset.lerp(_restoreStartOffset, Offset.zero, easedProgress) ?? Offset.zero;
      _rawDragOffset = _dragOffset;
      _visualClosingProgress = _restoreStartProgress * (1 - easedProgress);
    });
  }

  void _startPreviewDrag() {
    _restoreAnimationController.stop();
    _isPreviewDragActive = true;
    _holdActiveScrollPosition();
  }

  void _finishPreviewDrag({required Velocity swipeVelocity}) {
    if (!_isPreviewDragActive) return;

    if (_shouldCommitPreviewPop(swipeVelocity: swipeVelocity)) {
      _commitPreviewPop();
      return;
    }

    _cancelPreviewDrag();
  }

  void _finishReducedMotionPreviewDrag({required Velocity swipeVelocity}) {
    if (_shouldCommitPreviewPop(swipeVelocity: swipeVelocity)) {
      _resetGestureState();
      unawaited(Navigator.of(context).maybePop());
      return;
    }

    _restoreInteractiveSurface();
  }

  bool _shouldCommitPreviewPop({required Velocity swipeVelocity}) {
    if (_visualClosingProgress >= _commitThreshold) return true;

    final activeSwipeAxis = _activeSwipeAxis ?? Axis.vertical;

    switch (activeSwipeAxis) {
      case Axis.horizontal:
        return swipeVelocity.isSwipeRight();
      case Axis.vertical:
        return swipeVelocity.isSwipeDown();
    }
  }

  void _commitPreviewPop() {
    _resetGestureState(keepVisualTransform: true);
    unawaited(_restorePreviewIfPopIsVetoed());
  }

  Future<void> _restorePreviewIfPopIsVetoed() async {
    final route = ModalRoute.of(context);
    await Navigator.of(context).maybePop();
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    if (route?.isCurrent == false) return;

    _cancelPreviewDrag();
  }

  void _cancelPreviewDrag() {
    if (_isReducedMotionSwipe) {
      _restoreInteractiveSurface();
      return;
    }

    _restoreStartOffset = _dragOffset;
    _restoreStartProgress = _visualClosingProgress;
    _restoreAnimationController
      ..value = 0
      ..forward();
  }

  void _resetGestureState({bool keepVisualTransform = false}) {
    _isPreviewDragActive = false;
    _isPointerDirectionRejected = false;
    _isReducedMotionSwipe = false;
    _previewDistance = 1;
    _velocityTracker = null;
    _flingReachedTopAtUs = null;
    _activeSwipeAxis = null;
    _accumulatedPointerOffset = Offset.zero;
    _releaseActiveScrollHold();
    if (keepVisualTransform) return;

    _visualClosingProgress = 0;
    _dragOffset = Offset.zero;
    _rawDragOffset = Offset.zero;
    _restoreStartOffset = Offset.zero;
    _restoreStartProgress = 0;
  }

  void _restoreInteractiveSurface() {
    if (!mounted) return;

    _resetGestureState();
  }

  void _updateScrollMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) return;

    _hasVerticalScrollable = true;
    _activeVerticalMetrics = metrics;
  }

  void _updateActiveScrollPosition(BuildContext? scrollContext) {
    if (scrollContext == null) return;

    _activeScrollPosition = Scrollable.of(scrollContext).position;
    if (_isPreviewDragActive && !_isReducedMotionSwipe) {
      _holdActiveScrollPosition();
    }
  }

  void _holdActiveScrollPosition() {
    if (_isReducedMotionSwipe) return;
    if (_activeScrollHold != null) return;
    if (_isStartingScrollHold) return;

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
    if (!_isPreviewDragActive) return;
    if (_isReducedMotionSwipe) return;

    final scrollPosition = _activeScrollPosition;
    if (scrollPosition == null) return;
    if (scrollPosition.pixels >= scrollPosition.minScrollExtent) return;

    scrollPosition.correctPixels(scrollPosition.minScrollExtent);
  }

  void _trackScrollMovement({required ScrollMetrics metrics, required double scrollDelta, required bool isBallistic}) {
    _updateScrollMetrics(metrics);

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
    _updateActiveScrollPosition(notification.context);
    _restorePreviewScrollPosition(notification);
    if (notification is ScrollUpdateNotification) {
      _trackScrollMovement(
        metrics: notification.metrics,
        scrollDelta: notification.scrollDelta ?? 0,
        isBallistic: notification.dragDetails == null,
      );
    }

    return false;
  }

  void _restorePreviewScrollPosition(ScrollNotification notification) {
    if (!_isPreviewDragActive) return;
    if (_isReducedMotionSwipe) return;
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
    _isReducedMotionSwipe = MediaQuery.disableAnimationsOf(context);
    _velocityTracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    _updatePreviewDistanceForAxis(Axis.vertical);
    _accumulatedPointerOffset = Offset.zero;
    _isPointerDirectionRejected = false;
    if (_restoreAnimationController.isAnimating) {
      _restoreAnimationController.stop();
      return;
    }

    _visualClosingProgress = 0;
    _dragOffset = Offset.zero;
    _rawDragOffset = Offset.zero;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    _accumulatedPointerOffset += event.delta;
    if (!_isPreviewDragActive) {
      if (_isPointerDirectionRejected) return;
      final swipeStartAxis = _resolveSwipeStartAxis();
      if (swipeStartAxis == null && _shouldRejectSwipeStart()) {
        _isPointerDirectionRejected = true;
        return;
      }
      if (swipeStartAxis == null) return;
      if (swipeStartAxis == Axis.vertical && !_canStartSwipeToPop) return;

      _activeSwipeAxis = swipeStartAxis;
      _updatePreviewDistanceForAxis(swipeStartAxis);
    }

    final wasPreviewDragActive = _isPreviewDragActive;
    if (!_isPreviewDragActive) {
      if (_isReducedMotionSwipe) {
        _isPreviewDragActive = true;
      } else {
        _startPreviewDrag();
      }
    }

    if (!_isPreviewDragActive) return;

    final nextRawDragOffset = wasPreviewDragActive
        ? _rawDragOffset + (event.delta * _dragReactionMultiplier)
        : _accumulatedPointerOffset * _dragReactionMultiplier;
    final nextDragOffset = _clampedDragOffset(nextRawDragOffset);
    final nextClosingProgress = _dragOffsetProgress(dragOffset: nextDragOffset);

    if (_isReducedMotionSwipe) {
      _rawDragOffset = nextRawDragOffset;
      _dragOffset = nextDragOffset;
      _visualClosingProgress = nextClosingProgress;
      _restoreActiveScrollPosition();
      return;
    }

    setState(() {
      _rawDragOffset = nextRawDragOffset;
      _dragOffset = nextDragOffset;
      _visualClosingProgress = nextClosingProgress;
    });
    _restoreActiveScrollPosition();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final swipeVelocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
    _activePointer = null;

    if (_isReducedMotionSwipe) {
      _finishReducedMotionPreviewDrag(swipeVelocity: swipeVelocity);
      return;
    }

    _finishPreviewDrag(swipeVelocity: swipeVelocity);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    if (!_isPreviewDragActive) {
      _resetGestureState();
      return;
    }

    _cancelPreviewDrag();
  }

  @override
  void initState() {
    super.initState();
    _restoreAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;

        _restoreInteractiveSurface();
      });
    _restoreAnimationController.addListener(_handleRestoreTick);
  }

  @override
  void dispose() {
    _releaseActiveScrollHold();
    _restoreAnimationController
      ..removeListener(_handleRestoreTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handoffState = _visualClosingProgress == 0
        ? null
        : QuiSwipeToPopHandoffState(scale: _previewScale, borderRadius: _previewBorderRadius);

    return _QuiSwipeToPopSurfaceHandoffScope(
      state: handoffState,
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
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.scale(
                scale: _previewScale,
                child: ClipRRect(
                  borderRadius: _previewBorderRadius,
                  clipBehavior: _previewClipBehavior,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
