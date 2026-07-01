part of 'qui_hero_drag_to_close_extension.dart';

class _QuiHeroDragToCloseExtensionGesture extends StatefulWidget {
  const _QuiHeroDragToCloseExtensionGesture({
    required this.child,
    this.scrollController,
    this.closeDragHeightFactor = 0.42,
    this.commitThreshold = 0.5,
    this.onDragStateChanged,
  });

  final Widget child;
  final ScrollController? scrollController;
  final double closeDragHeightFactor;
  final double commitThreshold;
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
    final closeDragDistance = MediaQuery.sizeOf(context).height * widget.closeDragHeightFactor;
    _closeDragDistance = closeDragDistance <= 0 ? 1 : closeDragDistance;
    _interactiveClosingProgress = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;
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

    _activePointer = null;
    _finishInteractivePop();
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

  void _finishInteractivePop() {
    if (!_isInteractivePopActive) return;

    if (_isReducedMotionDrag) {
      _finishReducedMotionInteractivePop();
      return;
    }

    final route = _activeRoute;
    if (route == null) {
      _restoreInteractiveChrome();
      return;
    }

    if (_interactiveClosingProgress >= widget.commitThreshold) {
      route.commitInteractivePop();
      _resetGestureState();
      return;
    }

    _cancelInteractivePop();
  }

  void _finishReducedMotionInteractivePop() {
    if (_interactiveClosingProgress >= widget.commitThreshold) {
      _resetGestureState();
      unawaited(Navigator.of(context).maybePop());
      return;
    }

    _restoreInteractiveChrome();
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
