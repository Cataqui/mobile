part of 'qui_toast.dart';

class _QuiToastOverlay extends StatefulWidget {
  const _QuiToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.disableAnimations,
    required this.padding,
    required this.onDismissed,
  });

  final String message;
  final QuiToastType type;
  final Duration duration;
  final bool disableAnimations;
  final EdgeInsetsGeometry padding;
  final VoidCallback onDismissed;

  @override
  State<_QuiToastOverlay> createState() => _QuiToastOverlayState();
}

class _QuiToastOverlayState extends State<_QuiToastOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _dragDismissDistance = 82;
  static const double _dragDismissOffset = 12;
  static const double _dragUpdateMaxDistance = 24;
  static const double _dragDismissProgress = 0.34;
  static const double _dragMinVisibleProgress = 0.24;
  static const double _resistanceMaxOffset = 6;
  static const double _resistanceDampingDistance = 96;
  static const double _pressedScale = 0.985;
  static const double _swipeDismissMinVelocity = 250;
  static const Duration _swipeDismissMinDuration = Duration(milliseconds: 140);
  static const Duration _resistanceResetDuration = Duration(milliseconds: 180);
  static const Duration _pressScaleDuration = Duration(milliseconds: 300);

  late final AnimationController _animationController;
  late final AnimationController _resistanceResetController;
  late final AnimationController _pressScaleController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _pressScaleAnimation;
  late final Animation<double> _resistanceResetAnimation;

  final ValueNotifier<Offset> _resistanceOffsetNotifier = ValueNotifier<Offset>(Offset.zero);

  Timer? _dismissTimer;
  VelocityTracker? _velocityTracker;
  double _dragOffsetY = 0;
  Offset _resistanceDragOffset = Offset.zero;
  Offset _resistanceOffsetAtResetStart = Offset.zero;
  Offset? _pointerStartPosition;
  int? _activePointer;
  bool _isDismissed = false;
  bool _hasDraggedPointer = false;
  bool _isPressed = false;
  bool _dismissTimerPaused = false;
  bool _pendingTimerDismiss = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null || _isDismissed) return;

    _setPressed(true);
    _activePointer = event.pointer;
    _pointerStartPosition = event.position;
    _hasDraggedPointer = false;
    _velocityTracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    _handleDragStart();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _isDismissed) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    _hasDraggedPointer = _hasDraggedPointer || _hasMovedPastTapSlop(event.position);
    _handleDragUpdate(event.delta);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer || _isDismissed) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);

    final velocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
    final shouldDismissAsTap = !_hasDraggedPointer;

    _clearPointerTracking();
    _setPressed(false);

    if (_flushPendingDismiss()) return;

    if (shouldDismissAsTap) {
      _dismiss();
      return;
    }

    _handleDragEnd(velocity);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer || _isDismissed) return;

    _clearPointerTracking();
    _setPressed(false);

    if (_flushPendingDismiss()) return;

    _handleDragEnd(Velocity.zero);
  }

  bool _hasMovedPastTapSlop(Offset position) {
    final pointerStartPosition = _pointerStartPosition;
    if (pointerStartPosition == null) return false;

    return (position - pointerStartPosition).distance > kTouchSlop;
  }

  void _clearPointerTracking() {
    _activePointer = null;
    _pointerStartPosition = null;
    _velocityTracker = null;
    _hasDraggedPointer = false;
  }

  void _handleDragStart() {
    _animationController.stop();
    _resistanceResetController.stop();
    _dragOffsetY = 0;
    _resistanceDragOffset = Offset.zero;
  }

  void _handleDragUpdate(Offset delta) {
    if (_isDismissed) return;

    final dragDelta = _resolveDismissDragDelta(delta);
    if (dragDelta == 0) return;

    _dragOffsetY = (_dragOffsetY + dragDelta).clamp(double.negativeInfinity, 0);
    final dragDistance = dragDelta.clamp(-_dragUpdateMaxDistance, _dragUpdateMaxDistance);
    final dismissDelta = -dragDistance / _dragDismissDistance;
    _animationController.value = (_animationController.value - dismissDelta).clamp(_dragMinVisibleProgress, 1);
  }

  void _handleDragEnd(Velocity velocity) {
    if (_isDismissed) return;

    if (velocity.isSwipeUp(minVelocity: _swipeDismissMinVelocity)) {
      _dismiss(minimumDuration: _swipeDismissMinDuration);
      return;
    }

    if (_dragOffsetY <= -_dragDismissOffset || _animationController.value <= _dragDismissProgress) {
      _dismiss();
      return;
    }

    if (widget.disableAnimations) {
      _dragOffsetY = 0;
      _resistanceDragOffset = Offset.zero;
      _resistanceOffsetNotifier.value = Offset.zero;
      _animationController.value = 1;
      return;
    }

    _dragOffsetY = 0;
    _resistanceDragOffset = Offset.zero;
    _resetResistanceOffset();
    unawaited(_showToast());
  }

  double _resolveDismissDragDelta(Offset delta) {
    var resistanceDelta = Offset(_shouldApplyResistance ? delta.dx : 0, 0);
    var dismissDeltaY = 0.0;

    if (delta.dy > 0 && _dragOffsetY < 0) {
      final restoreDeltaY = delta.dy.clamp(0, -_dragOffsetY).toDouble();
      final remainingDeltaY = delta.dy - restoreDeltaY;
      dismissDeltaY = restoreDeltaY;

      if (remainingDeltaY > 0 && _shouldApplyResistance) {
        resistanceDelta += Offset(0, remainingDeltaY);
      }
    } else if (delta.dy > 0) {
      resistanceDelta += Offset(0, delta.dy);
    } else if (_resistanceDragOffset.dy > 0) {
      final nextResistanceY = _resistanceDragOffset.dy + delta.dy;
      resistanceDelta += Offset(0, -_resistanceDragOffset.dy);
      dismissDeltaY = nextResistanceY;

      if (nextResistanceY > 0) {
        resistanceDelta = Offset(delta.dx, delta.dy);
        dismissDeltaY = 0;
      }
    } else {
      dismissDeltaY = delta.dy;
    }

    _resistanceDragOffset += resistanceDelta;

    if (_resistanceDragOffset.dy < 0) {
      _resistanceDragOffset = Offset(_resistanceDragOffset.dx, 0);
    }
    _resistanceOffsetNotifier.value = _resolveResistanceOffset(_resistanceDragOffset);

    return dismissDeltaY;
  }

  bool get _shouldApplyResistance {
    return _dragOffsetY == 0 && _animationController.value == 1;
  }

  Offset _resolveResistanceOffset(Offset dragOffset) {
    final distance = dragOffset.distance;
    if (distance == 0) return Offset.zero;

    final resistedDistance = _resistanceMaxOffset * (1 - 1 / (1 + distance / _resistanceDampingDistance));
    return Offset.fromDirection(dragOffset.direction, resistedDistance);
  }

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;

    _isPressed = value;

    if (widget.disableAnimations) return;

    if (value) {
      unawaited(_pressScaleController.forward());
    } else {
      unawaited(_pressScaleController.reverse());
    }
  }

  void _resetResistanceOffset() {
    final current = _resistanceOffsetNotifier.value;
    if (current == Offset.zero) return;

    _resistanceOffsetAtResetStart = current;

    unawaited(_resistanceResetController.forward(from: 0));
  }

  void _syncResistanceResetOffset() {
    if (!mounted) return;

    _resistanceOffsetNotifier.value = Offset.lerp(
      _resistanceOffsetAtResetStart,
      Offset.zero,
      _resistanceResetAnimation.value,
    )!;
  }

  void _dismiss({Duration? minimumDuration}) {
    if (_isDismissed) return;
    if (_isPressed) {
      _pendingTimerDismiss = true;
      return;
    }

    _isDismissed = true;
    _dismissTimer?.cancel();
    _setPressed(false);

    if (widget.disableAnimations) {
      widget.onDismissed();
      return;
    }

    unawaited(
      _hideToast(minimumDuration: minimumDuration).then((_) {
        if (!mounted) return;
        widget.onDismissed();
      }),
    );
  }

  bool _flushPendingDismiss() {
    if (!_pendingTimerDismiss) return false;
    _pendingTimerDismiss = false;
    _dismiss();
    return true;
  }

  Future<void> _showToast() {
    return _animationController.animateTo(1, duration: QuiToast._appearDuration, curve: Curves.easeOutCubic);
  }

  Future<void> _hideToast({Duration? minimumDuration}) {
    var duration = QuiToast._dismissDuration;
    if (minimumDuration != null && duration < minimumDuration) {
      duration = minimumDuration;
    }

    return _animationController.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: QuiToast._appearDuration,
      reverseDuration: QuiToast._dismissDuration,
      vsync: this,
    );
    _pressScaleController = AnimationController(
      duration: _pressScaleDuration,
      reverseDuration: _pressScaleDuration,
      vsync: this,
    );
    _pressScaleAnimation = Tween<double>(begin: 1, end: _pressedScale)
        .animate(CurveTween(curve: Curves.easeOutCubic).animate(_pressScaleController));
    _resistanceResetController = AnimationController(duration: _resistanceResetDuration, vsync: this)
      ..addListener(_syncResistanceResetOffset);
    _resistanceResetAnimation = CurveTween(curve: Curves.easeOutCubic).animate(_resistanceResetController);
    _opacityAnimation = _animationController;
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -0.22), end: Offset.zero).animate(_animationController);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_animationController.value == 0) {
      if (widget.disableAnimations) {
        _animationController.value = 1;
      } else {
        unawaited(_showToast());
      }
    }

    _dismissTimer ??= Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dismissTimer?.cancel();
    _resistanceOffsetNotifier.dispose();
    _pressScaleController.dispose();
    _resistanceResetController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _animationController.stop();
        _pressScaleController.stop();
        _resistanceResetController.stop();
        _dismissTimer?.cancel();
        _dismissTimerPaused = true;
      case AppLifecycleState.resumed:
        if (_dismissTimerPaused && !_isDismissed) {
          _dismissTimer = Timer(widget.duration, _dismiss);
          _dismissTimerPaused = false;
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: RepaintBoundary(
        child: FadeTransition(
          key: const Key('qui_toast_fade_transition'),
          opacity: _opacityAnimation,
          child: _QuiToastSlideWidget(
            position: _offsetAnimation,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: widget.padding,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _QuiToastGestureTransformWidget(
                    key: const Key('qui_toast_resistance_transform'),
                    resistanceListenable: _resistanceOffsetNotifier,
                    pressScaleAnimation: widget.disableAnimations ? null : _pressScaleAnimation,
                    child: RepaintBoundary(
                      child: Listener(
                        key: const Key('qui_toast_gesture_target'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _handlePointerDown,
                        onPointerMove: _handlePointerMove,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerCancel,
                        child: QuiToast(message: widget.message, type: widget.type),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
