part of 'qui_toast.dart';

class _QuiToastOverlay extends StatefulWidget {
  const _QuiToastOverlay({
    required this.message,
    required this.type,
    required this.iconBuilder,
    required this.duration,
    required this.disableAnimations,
    required this.padding,
    required this.onDismissed,
  });

  final String message;
  final QuiToastType type;
  final QuiToastIconBuilder? iconBuilder;
  final Duration duration;
  final bool disableAnimations;
  final EdgeInsetsGeometry padding;
  final VoidCallback onDismissed;

  @override
  State<_QuiToastOverlay> createState() => _QuiToastOverlayState();
}

class _QuiToastOverlayState extends State<_QuiToastOverlay> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _dragDismissDistance = 82;
  static const double _dragDismissOffset = 12;
  static const double _dragUpdateMaxDistance = 24;
  static const double _dragDismissProgress = 0.34;
  static const double _dragMinVisibleProgress = 0.24;
  static const double _pressedScale = 0.985;
  static const double _swipeDismissMinVelocity = 250;
  static const Duration _swipeDismissMinDuration = Duration(milliseconds: 140);
  static const Duration _pressScaleDuration = Duration(milliseconds: 300);

  late final AnimationController _animationController;
  late final AnimationController _pressScaleController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _pressScaleAnimation;

  Timer? _dismissTimer;
  VelocityTracker? _velocityTracker;
  double _dragOffsetY = 0;
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
    _dragOffsetY = 0;
  }

  void _handleDragUpdate(Offset delta) {
    if (_isDismissed) return;

    final nextDragOffsetY = (_dragOffsetY + delta.dy).clamp(double.negativeInfinity, 0.0);
    final dragDelta = nextDragOffsetY - _dragOffsetY;
    _dragOffsetY = nextDragOffsetY;
    if (dragDelta == 0) return;

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
      _animationController.value = 1;
      return;
    }

    _dragOffsetY = 0;
    unawaited(_showToast());
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
    _pressScaleAnimation = Tween<double>(
      begin: 1,
      end: _pressedScale,
    ).animate(CurveTween(curve: Curves.easeOutCubic).animate(_pressScaleController));
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
    _pressScaleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _animationController.stop();
        _pressScaleController.stop();
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
                  child: QuiDragResistance(
                    top: false,
                    child: ScaleTransition(
                      key: const Key('qui_toast_press_scale_transition'),
                      alignment: Alignment.topLeft,
                      scale: widget.disableAnimations ? const AlwaysStoppedAnimation<double>(1) : _pressScaleAnimation,
                      child: RepaintBoundary(
                        child: Listener(
                          key: const Key('qui_toast_gesture_target'),
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: _handlePointerDown,
                          onPointerMove: _handlePointerMove,
                          onPointerUp: _handlePointerUp,
                          onPointerCancel: _handlePointerCancel,
                          child: QuiToast(message: widget.message, type: widget.type, iconBuilder: widget.iconBuilder),
                        ),
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
