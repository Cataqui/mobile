part of 'qui_hero_drag_to_close_extension.dart';

class _QuiHeroDragToCloseExtensionGesture extends StatefulWidget {
  const _QuiHeroDragToCloseExtensionGesture({
    required this.child,
    this.scrollController,
    this.commitThreshold = 0.5,
    this.sensibility = 0.5,
    this.onDragStateChanged,
  });

  final Widget child;
  final ScrollController? scrollController;
  final double commitThreshold;
  final double sensibility;
  final ValueChanged<QuiHeroDragToCloseState>? onDragStateChanged;

  @override
  State<_QuiHeroDragToCloseExtensionGesture> createState() => _QuiHeroDragToCloseExtensionGestureState();
}

class _QuiHeroDragToCloseExtensionGestureState extends State<_QuiHeroDragToCloseExtensionGesture> {
  int? _activePointer;
  bool _isInteractivePopActive = false;
  bool _isReducedMotionDrag = false;
  double _closeDragDistance = 1;
  double _interactiveClosingProgress = 0;
  VelocityTracker? _velocityTracker;
  QuiHeroPageRoute? _activeRoute;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.deferToChild,
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;

    _activePointer = event.pointer;
    _activeRoute = null;
    _isReducedMotionDrag = MediaQuery.disableAnimationsOf(context);
    _velocityTracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    final closeDragDistance = MediaQuery.sizeOf(context).height * _dragToCloseHeightFraction();
    _closeDragDistance = closeDragDistance <= 0 ? 1 : closeDragDistance;
    _interactiveClosingProgress = 0;
  }

  double _dragToCloseHeightFraction() {
    // sensibility 0.5 → 0.5 (half-screen drag), 0.0 → 1.0, 1.0 → 0.125.
    if (widget.sensibility <= 0.5) return 0.5 * (1 + ((0.5 - widget.sensibility) / 0.5));
    return 0.5 * (1 - (((widget.sensibility - 0.5) / 0.5) * 0.75));
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    if (!_isInteractivePopActive && event.delta.dy <= 0) return;
    if (!_isInteractivePopActive && !_isScrollAtTop) return;

    if (!_isInteractivePopActive) {
      if (_isReducedMotionDrag) {
        _isInteractivePopActive = true;
        widget.onDragStateChanged?.call(QuiHeroDragToCloseState.dragging);
      } else if (!_startInteractivePop()) {
        return;
      }
    }

    _interactiveClosingProgress = (_interactiveClosingProgress + (event.delta.dy / _closeDragDistance))
        .clamp(0, 1)
        .toDouble();

    if (_isReducedMotionDrag) return;

    _activeRoute?.updateInteractivePop(closingProgress: _interactiveClosingProgress);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final dragVelocity = _velocityTracker?.getVelocity() ?? Velocity.zero;
    _activePointer = null;
    _finishInteractivePop(dragVelocity: dragVelocity);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    _cancelInteractivePop();
  }

  bool _startInteractivePop() {
    final route = QuiHeroPageRoute.maybeOf(context);
    assert(
      _debugAssertUsesQuiHeroPageRoute(route),
      'QuiHeroDragToCloseExtension must be used inside a QuiHeroPageRoute.',
    );

    if (route == null) return false;
    if (!route.startInteractivePop()) return false;

    _activeRoute = route;
    _isInteractivePopActive = true;
    _interactiveClosingProgress = 0;
    widget.onDragStateChanged?.call(QuiHeroDragToCloseState.dragging);
    return true;
  }

  bool _debugAssertUsesQuiHeroPageRoute(QuiHeroPageRoute? route) {
    if (route != null) return true;

    throw FlutterError.fromParts([
      ErrorSummary('QuiHeroDragToCloseExtension must be used inside a QuiHeroPageRoute.'),
      ErrorDescription(
        'QuiHeroDragToCloseExtension drives the interactive pop API owned by QuiHeroPageRoute, '
        'so it cannot work from a regular route.',
      ),
      ErrorHint(
        'Create the destination page with QuiHeroPage, then pass QuiHeroDragToCloseExtension '
        'to the destination QuiHero extensions list.',
      ),
    ]);
  }

  void _finishInteractivePop({required Velocity dragVelocity}) {
    if (!_isInteractivePopActive) return;

    if (_isReducedMotionDrag) {
      _finishReducedMotionInteractivePop(dragVelocity: dragVelocity);
      return;
    }

    final route = _activeRoute;
    if (route == null) {
      _restoreInteractiveChrome();
      return;
    }

    if (_shouldCommitInteractivePop(dragVelocity: dragVelocity)) {
      route.commitInteractivePop();
      _resetGestureState();
      return;
    }

    _cancelInteractivePop();
  }

  void _finishReducedMotionInteractivePop({required Velocity dragVelocity}) {
    if (_shouldCommitInteractivePop(dragVelocity: dragVelocity)) {
      _resetGestureState();
      unawaited(Navigator.of(context).maybePop());
      return;
    }

    _restoreInteractiveChrome();
  }

  bool _shouldCommitInteractivePop({required Velocity dragVelocity}) {
    return _interactiveClosingProgress >= widget.commitThreshold || dragVelocity.isSwipeDown();
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
    _isReducedMotionDrag = false;
    _closeDragDistance = 1;
    _interactiveClosingProgress = 0;
    _velocityTracker = null;
    _activeRoute = null;
  }

  void _restoreInteractiveChrome() {
    if (!mounted) return;

    _resetGestureState();
    widget.onDragStateChanged?.call(QuiHeroDragToCloseState.idle);
  }

  bool get _isScrollAtTop {
    final controller = widget.scrollController;
    if (controller == null) return true;
    if (!controller.hasClients) return true;

    final position = controller.position;
    return position.pixels <= position.minScrollExtent + 0.5;
  }
}
