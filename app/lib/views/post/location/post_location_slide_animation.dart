part of 'post_location_view.dart';

class _PostLocationSlideAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _PostLocationSlideAnimation({required this.parent}) {
    parent.addStatusListener(_handleStatusChanged);
  }

  @override
  final Animation<double> parent;

  double? _reverseStartProgress;
  late double _reverseStartValue;

  void dispose() => parent.removeStatusListener(_handleStatusChanged);

  void _handleStatusChanged(AnimationStatus status) {
    if (status != .reverse) return;

    // Retarget from the painted position, even while the entrance is still settling.
    _reverseStartValue = value;
    _reverseStartProgress = parent.value;
  }

  @override
  double get value {
    final reverseStartProgress = _reverseStartProgress;
    if (reverseStartProgress == null) return const Cubic(0.32, 1, 0, 1).transform(parent.value);
    if (reverseStartProgress == 0) return 0;

    final exitProgress = (1 - parent.value / reverseStartProgress).clamp(0.0, 1.0);
    return _reverseStartValue * (1 - const Cubic(0.1, 0.3, 0.4, 0.6).transform(exitProgress));
  }
}
