part of 'package:qui/src/widgets/qui_skeleton/qui_skeleton.dart';

/// A skeleton effect that fades the bone body in and out in a smooth loop.
///
/// Produces a gentle "coming soon" breathing pulse: the skeleton bones dim
/// toward [opacity]'s `start` and brighten toward `end`, oscillating forever
/// with a cosine curve so the loop seam is invisible (both value and velocity
/// are continuous at the loop boundary).
///
/// ```dart
/// // Default — gentle 0.3 -> 1.0 breathing at 1000ms per loop.
/// QuiSkeleton(style: QuiSkeletonStyle(effect: QuiSkeletonFadeEffect()));
///
/// // Custom range and tempo.
/// QuiSkeleton(
///   style: QuiSkeletonStyle(
///     effect: QuiSkeletonFadeEffect(
///       duration: Duration(milliseconds: 1000),
///       opacity: (start: 0.0, end: 1.0),
///     ),
///   ),
/// );
/// ```
///
/// ## Performance
///
/// The fade reuses the skeleton's render-object animation pipeline: each frame
/// only recomputes the bone [Paint]'s color alpha (one cosine + one color
/// allocation). No shaders are built and no widget rebuilds occur. The
/// skeleton render object is a repaint boundary, so repaints stay isolated to
/// the skeleton subtree. When the platform disables animations, the effect
/// falls back to a static solid fill at zero per-frame cost.
///
/// See also:
///  * [QuiSkeletonAnimatedEffectBase], the base class for animated skeleton effects.
///  * [QuiSkeletonShimmerEffect], the built-in animated shimmer sweep effect.
@immutable
class QuiSkeletonFadeEffect extends QuiSkeletonAnimatedEffectBase {
  /// Creates a fade skeleton effect.
  ///
  /// [duration] is the time to complete one fade-in + fade-out loop, defaulting
  /// to 1000ms. [opacity] controls the alpha range the bones breathe between,
  /// defaulting to `(start: 0.4, end: 1.0)` — a gentle pulse where the bones
  /// never fully vanish.
  const QuiSkeletonFadeEffect({
    this.duration = const Duration(milliseconds: 1000),
    this.opacity = const (start: 0.4, end: 1.0),
  });

  /// The duration of one full fade-in + fade-out loop.
  @override
  final Duration duration;

  /// The alpha range the bone body breathes between each loop.
  ///
  /// The loop goes [opacity]'s `start -> end -> start` via a cosine curve.
  /// Values are clamped to `0.0–1.0` at paint time. `start` and `end` may be
  /// in any order; when `start > end` the effect fades out then in.
  final ({double start, double end}) opacity;

  @override
  double get lowerBound => 0;

  @override
  double get upperBound => math.pi * 2;

  @override
  Paint buildPaint({
    required Rect bounds,
    required double t,
    required QuiColorScheme colorScheme,
    required QuiSkeletonStyle style,
  }) {
    final boneColor = style.color ?? colorScheme.skeleton.bone;
    final phase = (1 - math.cos(t)) / 2;
    final fadeAlpha = (opacity.start + (opacity.end - opacity.start) * phase).clamp(0.0, 1.0);
    return Paint()..color = boneColor.withValues(alpha: boneColor.a * fadeAlpha);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuiSkeletonFadeEffect && other.duration == duration && other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(duration, opacity);
}
