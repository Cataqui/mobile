part of 'qui_swipe_to_pop_surface.dart';

/// The swipe-to-pop preview state made available to hero flights.
///
/// Use this value when a committed pop should continue from the exact preview
/// transform the user saw before release. The state carries the preview scale
/// and the preview border radius together so callers can hand off both values
/// with one lookup.
@immutable
final class QuiSwipeToPopHandoffState {
  /// Creates a swipe-to-pop handoff state.
  const QuiSwipeToPopHandoffState({required this.scale, required this.borderRadius});

  /// The preview scale currently visible on the wrapped route.
  final double scale;

  /// The preview border radius currently visible on the wrapped route.
  final BorderRadiusGeometry? borderRadius;

  @override
  bool operator ==(Object other) {
    return other is QuiSwipeToPopHandoffState && scale == other.scale && borderRadius == other.borderRadius;
  }

  @override
  int get hashCode => Object.hash(scale, borderRadius);
}
