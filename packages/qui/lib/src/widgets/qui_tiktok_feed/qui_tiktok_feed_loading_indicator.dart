part of 'qui_tiktok_feed.dart';

class _QuiTikTokFeedLoadingIndicator extends StatelessWidget {
  const _QuiTikTokFeedLoadingIndicator({required this.visible});

  static const double indicatorSize = 80;

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('qui_tiktok_feed_loading_indicator'),
      width: indicatorSize,
      height: indicatorSize,
      child: visible
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(context.qui.colors.primary, BlendMode.srcIn),
              child: Assets.lottie.loadingSlime.lottie(
                width: indicatorSize,
                height: indicatorSize,
                fit: BoxFit.contain,
                repeat: true,
              ),
            )
          : null,
    );
  }
}
