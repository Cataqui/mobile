part of 'qui_tiktok_feed.dart';

@immutable
class _QuiTikTokFeedWindow<T> {
  const _QuiTikTokFeedWindow({
    required this.previousCard,
    required this.currentCard,
    required this.nextCard,
    required this.paginationCard,
    required this.terminalCard,
  });

  final _QuiTikTokFeedCachedCard<T>? previousCard;
  final _QuiTikTokFeedCachedCard<T>? currentCard;
  final _QuiTikTokFeedCachedCard<T>? nextCard;
  final Widget? paginationCard;
  final Widget? terminalCard;
}
