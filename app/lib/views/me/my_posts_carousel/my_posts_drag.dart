part of 'my_posts_carousel.dart';

class _MyPostsDrag implements Drag {
  _MyPostsDrag(
    this._delegate,
    DragStartDetails startDetails,
    this._maxFlingVelocity,
    this._pointerUpTime,
    this._onPrimaryDelta,
  ) : _startTime = startDetails.sourceTimeStamp;

  static const _flingVelocityMultiplier = 1.4;

  final Drag _delegate;
  final Duration? _startTime;
  final double _maxFlingVelocity;
  final Duration? Function() _pointerUpTime;
  final ValueChanged<double> _onPrimaryDelta;
  final Stopwatch _stopwatch = Stopwatch()..start();
  Duration? _firstUpdateTime;
  Duration? _lastUpdateTime;
  Duration? _lastMovementElapsed;
  double _dragDistance = 0;
  double _lastDelta = 0;

  double? _estimatedPrimaryVelocity() {
    // Fast drags can report zero velocity when pointer samples are delayed.
    final lastUpdateTime = _lastUpdateTime;
    final firstTime = _startTime ?? _firstUpdateTime;
    final lastMovementElapsed = _lastMovementElapsed;
    if (lastUpdateTime == null || firstTime == null || lastMovementElapsed == null) return null;
    // Event timestamps distinguish a paused finger from delayed Dart processing.
    final movementAge = switch (_pointerUpTime()) {
      final pointerUpTime? => pointerUpTime - lastUpdateTime,
      null => _stopwatch.elapsed - lastMovementElapsed,
    };
    if (movementAge < Duration.zero || movementAge > const Duration(milliseconds: 40)) return null;
    if (_dragDistance.abs() < kTouchSlop * 2 || _lastDelta.sign != _dragDistance.sign) return null;

    final elapsedMicroseconds = (lastUpdateTime - firstTime).inMicroseconds;
    if (elapsedMicroseconds <= 0) return null;
    final velocity = _dragDistance * Duration.microsecondsPerSecond / elapsedMicroseconds;
    if (velocity.abs() < kMinFlingVelocity * 4) return null;
    return velocity.clamp(-_maxFlingVelocity, _maxFlingVelocity);
  }

  @override
  void update(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta!;
    _lastDelta = details.primaryDelta!;
    _onPrimaryDelta(_lastDelta);
    if (details.sourceTimeStamp case final timestamp?) {
      _firstUpdateTime ??= timestamp;
      _lastUpdateTime = timestamp;
    }
    if (_lastDelta != 0) _lastMovementElapsed = _stopwatch.elapsed;
    _delegate.update(details);
  }

  @override
  void end(DragEndDetails details) {
    final reportedVelocity = details.primaryVelocity!;
    final primaryVelocity =
        (reportedVelocity.abs() >= kMinFlingVelocity
            ? reportedVelocity
            : _estimatedPrimaryVelocity() ?? reportedVelocity) *
        _flingVelocityMultiplier;
    _delegate.end(
      DragEndDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        velocity: Velocity(pixelsPerSecond: Offset(primaryVelocity, 0)),
        primaryVelocity: primaryVelocity,
      ),
    );
  }

  @override
  void cancel() => _delegate.cancel();
}
