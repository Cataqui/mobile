part of 'my_posts_carousel.dart';

class _MyPostsScrollPosition extends ScrollPositionWithSingleContext {
  _MyPostsScrollPosition({
    required super.physics,
    required super.context,
    required this.onBallisticTargetChanged,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
  });

  final ValueChanged<double?> onBallisticTargetChanged;
  DateTime? _lastProgressLog;
  Duration? pointerUpTime;
  double? _ballisticTarget;
  Timer? _stationaryHoldTimer;

  void _clearBallisticTarget() {
    _stationaryHoldTimer?.cancel();
    _stationaryHoldTimer = null;
    if (_ballisticTarget == null) return;
    _ballisticTarget = null;
    onBallisticTargetChanged(null);
  }

  void _restartStationaryHoldTimer() {
    _stationaryHoldTimer?.cancel();
    if (_ballisticTarget == null) return;
    _stationaryHoldTimer = Timer(const Duration(milliseconds: 120), _clearBallisticTarget);
  }

  void _onDragUpdate(double primaryDelta) {
    final target = _ballisticTarget;
    if (target == null) return;
    if (primaryDelta * (target - pixels) > 0) {
      _clearBallisticTarget();
      return;
    }
    _restartStationaryHoldTimer();
  }

  double? _ballisticTargetPixels(double velocity) {
    if (!hasContentDimensions || velocity.abs() < physics.minFlingVelocity) return null;
    final simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation == null) return null;

    var elapsedSeconds = 0.0;
    while (elapsedSeconds < 10 && !simulation.isDone(elapsedSeconds)) {
      elapsedSeconds += 0.05;
    }
    return simulation.x(elapsedSeconds).clamp(minScrollExtent, maxScrollExtent);
  }

  void _logScroll(String event, {double? velocity}) {
    if (!kDebugMode) return;
    debugPrint(
      '[MyPostsScroll] ${DateTime.now().toIso8601String()} $event '
      'px=${hasPixels ? pixels.toStringAsFixed(1) : "?"} '
      'max=${hasContentDimensions ? maxScrollExtent.toStringAsFixed(1) : "?"} '
      'activity=${activity.runtimeType} '
      'velocity=${(velocity ?? activity?.velocity ?? 0).toStringAsFixed(1)}',
    );
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    _logScroll('finger_down');
    _restartStationaryHoldTimer();
    return super.hold(holdCancelCallback);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _logScroll('drag_start');
    pointerUpTime = null;
    return _MyPostsDrag(
      super.drag(details, dragCancelCallback),
      details,
      physics.maxFlingVelocity,
      () => pointerUpTime,
      _onDragUpdate,
    );
  }

  @override
  void goBallistic(double velocity) {
    _logScroll('release', velocity: velocity);
    _stationaryHoldTimer?.cancel();
    _stationaryHoldTimer = null;
    _ballisticTarget = _ballisticTargetPixels(velocity);
    onBallisticTargetChanged(_ballisticTarget);
    super.goBallistic(velocity);
  }

  @override
  void dispose() {
    _stationaryHoldTimer?.cancel();
    super.dispose();
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    final previousActivity = activity.runtimeType;
    super.beginActivity(newActivity);
    _logScroll('$previousActivity -> ${newActivity.runtimeType}');
  }

  @override
  void didUpdateScrollPositionBy(double delta) {
    super.didUpdateScrollPositionBy(delta);
    if (!kDebugMode) return;

    final now = DateTime.now();
    if (_lastProgressLog case final last? when now.difference(last) < const Duration(milliseconds: 250)) return;
    _lastProgressLog = now;
    _logScroll('progress');
  }
}
