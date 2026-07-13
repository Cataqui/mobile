part of 'qui_tiktok_feed.dart';

class _QuiTikTokFeedLoadingIndicator extends StatelessWidget {
  const _QuiTikTokFeedLoadingIndicator({required this.visible});

  static const double indicatorBoxSize = 100;

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      key: const ValueKey('qui_tiktok_feed_loading_indicator'),
      width: indicatorBoxSize,
      height: indicatorBoxSize,
      child: visible
          ? Center(child: QuiDotLoadingIndicator(color: context.qui.colorScheme.colors.primary.solid, dotRadius: 5))
          : null,
    );
  }
}
