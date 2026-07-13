part of 'qui_color_scheme.dart';

/// Placeholder and shimmer roles for loading skeletons.
///
/// Use this group when rendering loading placeholders that should feel tied to
/// the active theme instead of appearing as hardcoded greys. The roles separate
/// the base placeholder treatment from the glow used by animated effects.
@immutable
class QuiSkeletonColorScheme {
  /// Creates placeholder and shimmer roles for loading skeletons.
  const QuiSkeletonColorScheme({
    required this.bone,
    required this.shimmerGlow,
    required this.skeletonText,
    required this.skeletonTextGlow,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiSkeletonColorScheme.lerp(QuiSkeletonColorScheme a, QuiSkeletonColorScheme b, double t) {
    return QuiSkeletonColorScheme(
      bone: Color.lerp(a.bone, b.bone, t)!,
      shimmerGlow: Color.lerp(a.shimmerGlow, b.shimmerGlow, t)!,
      skeletonText: Color.lerp(a.skeletonText, b.skeletonText, t)!,
      skeletonTextGlow: Color.lerp(a.skeletonTextGlow, b.skeletonTextGlow, t)!,
    );
  }

  /// Base fill color for skeleton blocks and shapes.
  final Color bone;

  /// Highlight glow color used by shimmer-style skeleton effects.
  final Color shimmerGlow;

  /// Base fill color for skeleton text placeholders.
  final Color skeletonText;

  /// Highlight glow color used by skeleton text shimmer effects.
  final Color skeletonTextGlow;

  /// {@macro qui_color_scheme_copy_with}
  QuiSkeletonColorScheme copyWith({Color? bone, Color? shimmerGlow, Color? skeletonText, Color? skeletonTextGlow}) {
    return QuiSkeletonColorScheme(
      bone: bone ?? this.bone,
      shimmerGlow: shimmerGlow ?? this.shimmerGlow,
      skeletonText: skeletonText ?? this.skeletonText,
      skeletonTextGlow: skeletonTextGlow ?? this.skeletonTextGlow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiSkeletonColorScheme &&
          bone == other.bone &&
          shimmerGlow == other.shimmerGlow &&
          skeletonText == other.skeletonText &&
          skeletonTextGlow == other.skeletonTextGlow;

  @override
  int get hashCode => Object.hash(bone, shimmerGlow, skeletonText, skeletonTextGlow);
}
