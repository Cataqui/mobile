part of 'qui_color_scheme.dart';

@immutable
class QuiSkeletonColorScheme {
  const QuiSkeletonColorScheme({
    required this.bone,
    required this.shimmerGlow,
    required this.skeletonText,
    required this.skeletonTextGlow,
  });

  final Color bone;
  final Color shimmerGlow;
  final Color skeletonText;
  final Color skeletonTextGlow;

  QuiSkeletonColorScheme copyWith({
    Color? bone,
    Color? shimmerGlow,
    Color? skeletonText,
    Color? skeletonTextGlow,
  }) {
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

  static QuiSkeletonColorScheme lerp(QuiSkeletonColorScheme a, QuiSkeletonColorScheme b, double t) {
    return QuiSkeletonColorScheme(
      bone: Color.lerp(a.bone, b.bone, t)!,
      shimmerGlow: Color.lerp(a.shimmerGlow, b.shimmerGlow, t)!,
      skeletonText: Color.lerp(a.skeletonText, b.skeletonText, t)!,
      skeletonTextGlow: Color.lerp(a.skeletonTextGlow, b.skeletonTextGlow, t)!,
    );
  }
}
