part of 'welcome_view.dart';

@immutable
final class _WelcomeJob {
  const _WelcomeJob({
    required this.title,
    required this.amount,
    required this.description,
    required this.postedTime,
    required this.artwork,
  });

  final String title;
  final String amount;
  final String description;
  final String postedTime;
  final _WelcomeJobArtwork artwork;
}

@immutable
final class _WelcomeJobArtwork {
  const _WelcomeJobArtwork({
    required this.top,
    required this.right,
    required this.left,
    required this.bottom,
    required this.corner,
  });

  final _WelcomeJobIllustration top;
  final _WelcomeJobIllustration right;
  final _WelcomeJobIllustration left;
  final _WelcomeJobIllustration bottom;
  final _WelcomeJobIllustration corner;
}

@immutable
final class _WelcomeJobIllustration {
  const _WelcomeJobIllustration({
    required this.builder,
    required this.precache,
    required this.backgroundColor,
    required this.illustrationColor,
    required this.width,
    this.height,
  });

  final Widget Function({required double width, double? height, Color? color}) builder;
  final Future<void> Function(BuildContext context, {double? width, double? height}) precache;
  final Color Function(MateoPalette palette) backgroundColor;
  final Color Function(MateoPalette palette)? illustrationColor;
  final double width;
  final double? height;
}
