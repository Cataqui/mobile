final class MapViewportMotion {
  static const stationaryWindow = Duration(milliseconds: 120);

  double? _position;
  Duration? _timestamp;
  double _cardsPerSecond = 0;
  bool _hasVelocitySample = false;

  Duration? get lastUpdateAt => _timestamp;
  bool isFastTransitAt({required Duration at}) =>
      _hasVelocitySample && _cardsPerSecond.abs() >= 4 && _timestamp != null && at - _timestamp! < stationaryWindow;

  bool shouldDeferFullCapture({required Duration at}) {
    final lastUpdateAt = _timestamp;
    if (lastUpdateAt == null) return true;
    if (at - lastUpdateAt >= stationaryWindow) return false;
    if (!_hasVelocitySample) return true;
    // Keep full native captures off while a card crosses in under half a second.
    return _cardsPerSecond.abs() >= 2;
  }

  int distanceAfter(Duration loadDuration) =>
      (_cardsPerSecond * loadDuration.inMicroseconds / Duration.microsecondsPerSecond).round();

  void update({required double position, required Duration timestamp}) {
    final previousPosition = _position;
    final previousTimestamp = _timestamp;
    _position = position;
    _timestamp = timestamp;
    if (previousPosition == null || previousTimestamp == null) return;
    final seconds = (timestamp - previousTimestamp).inMicroseconds / Duration.microsecondsPerSecond;
    if (seconds <= 0) return;
    _hasVelocitySample = true;
    final velocity = (position - previousPosition) / seconds;
    if (_cardsPerSecond.sign != velocity.sign) {
      _cardsPerSecond = velocity;
      return;
    }
    // Smooth sampling noise over a short part of a swipe, independent of refresh rate.
    final weight = seconds / (seconds + .08);
    _cardsPerSecond += (velocity - _cardsPerSecond) * weight;
  }

  void reset() {
    _position = null;
    _timestamp = null;
    _cardsPerSecond = 0;
    _hasVelocitySample = false;
  }
}
