part of '../qui_hero.dart';

class _QuiHeroLifecycleFlightShuttle extends StatefulWidget {
  const _QuiHeroLifecycleFlightShuttle({
    required this.animation,
    required this.flightDirection,
    required this.onStartCallbacks,
    required this.onEndCallbacks,
    required this.onReceivedCallbacks,
    required this.child,
  });

  final Animation<double> animation;
  final HeroFlightDirection flightDirection;
  final List<VoidCallback> onStartCallbacks;
  final List<VoidCallback> onEndCallbacks;
  final List<VoidCallback> onReceivedCallbacks;
  final Widget child;

  @override
  State<_QuiHeroLifecycleFlightShuttle> createState() => _QuiHeroLifecycleFlightShuttleState();
}

class _QuiHeroLifecycleFlightShuttleState extends State<_QuiHeroLifecycleFlightShuttle> {
  var _didCallEnd = false;

  @override
  void initState() {
    super.initState();
    _callCallbacks(widget.onStartCallbacks);
    widget.animation.addStatusListener(_handleStatusChanged);
  }

  @override
  void didUpdateWidget(_QuiHeroLifecycleFlightShuttle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) return;

    oldWidget.animation.removeStatusListener(_handleStatusChanged);
    widget.animation.addStatusListener(_handleStatusChanged);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (_didCallEnd) return;
    if (!_isSettledStatus(status)) return;

    _didCallEnd = true;
    _callCallbacks(widget.onReceivedCallbacks);
    _callCallbacks(widget.onEndCallbacks);
  }

  bool _isSettledStatus(AnimationStatus status) {
    switch (widget.flightDirection) {
      case HeroFlightDirection.push:
        return status == AnimationStatus.completed;
      case HeroFlightDirection.pop:
        return status == AnimationStatus.dismissed;
    }
  }

  void _callCallbacks(List<VoidCallback> callbacks) {
    for (final callback in callbacks) {
      callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
