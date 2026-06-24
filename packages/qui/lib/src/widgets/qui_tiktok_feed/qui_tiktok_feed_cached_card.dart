part of 'qui_tiktok_feed.dart';

@immutable
class _QuiTikTokFeedCachedCard<T> {
  const _QuiTikTokFeedCachedCard({required this.item, required this.itemKey, required this.index, required this.child});

  final T item;
  final Object itemKey;
  final int index;
  final Widget child;
}
