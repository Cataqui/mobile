part of 'package:qui/src/widgets/qui_skeleton/qui_skeleton.dart';

/// A skeleton effect that sweeps a highlight band across the bones.
///
/// Reproduces the classic shimmer loading animation: a narrow gradient band
/// travels along a configurable angle, revealing a highlight color against
/// the resting bone color.
///
/// ```dart
/// // Default — horizontal sweep, highlight from theme.
/// QuiSkeleton(effect: QuiSkeletonShimmerEffect());
///
/// // Diagonal sweep with a custom highlight.
/// QuiSkeleton(
///   effect: QuiSkeletonShimmerEffect(
///     color: Color(0xFFFFFFFF),
///     angle: math.pi / 4,
///   ),
/// );
/// ```
///
/// See also:
///  * [QuiSkeletonStaticEffectBase], the base class for all skeleton effects.
///  * [QuiSkeletonAnimatedEffectBase], the base class for animated skeleton effects.
@immutable
class QuiSkeletonShimmerEffect extends QuiSkeletonAnimatedEffectBase {
  /// Creates a shimmer skeleton effect.
  ///
  /// [color] overrides the theme's `skeletonShimmerGlow` token when non-null.
  /// This overrides ONLY the highlight — the resting bone color
  /// ([QuiColors.skeleton]) is always theme-driven and not overridable here.
  /// [angle] is in radians, where `0.0` sweeps left-to-right horizontally.
  const QuiSkeletonShimmerEffect({this.color, this.angle = 0.0});

  /// The highlight color of the shimmer band.
  ///
  /// When `null`, the effect falls back to the theme's `skeletonShimmerGlow`
  /// token at paint time (see [QuiColors.skeletonShimmerGlow]).
  final Color? color;

  /// The sweep angle in radians, where `0.0` is horizontal left-to-right.
  ///
  /// `math.pi / 2` sweeps top-to-bottom; `math.pi / 4` sweeps diagonally.
  final double angle;

  @override
  Paint buildPaint({
    required Rect bounds,
    required double t,
    required QuiColors colors,
  }) {
    final skeletonColor = colors.skeleton;
    final glow = color ?? colors.skeletonShimmerGlow;
    final gradientColors = <Color>[skeletonColor, glow, skeletonColor];
    const stops = <double>[0.1, 0.3, 0.4];

    final center = bounds.center;
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    final halfLength = (dx * bounds.width / 2).abs() + (dy * bounds.height / 2).abs();
    final travel = halfLength * 2;
    final shift = Offset(dx * travel * t, dy * travel * t);
    final start = center - Offset(dx * halfLength, dy * halfLength) + shift;
    final end = center + Offset(dx * halfLength, dy * halfLength) + shift;

    return Paint()..shader = ui.Gradient.linear(start, end, gradientColors, stops, TileMode.clamp);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuiSkeletonShimmerEffect && other.color == color && other.angle == angle;
  }

  @override
  int get hashCode => Object.hash(color, angle);
}
