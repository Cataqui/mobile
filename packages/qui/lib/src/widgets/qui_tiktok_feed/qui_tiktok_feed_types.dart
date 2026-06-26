part of 'qui_tiktok_feed.dart';

/// Called when a [QuiTikTokFeed] item completes a navigation action.
typedef QuiTikTokFeedItemCallback<T> = void Function(T item, int index);

/// Lazily provides the item at [index] for a [QuiTikTokFeed].
typedef QuiTikTokFeedItemProvider<T> = T Function(int index);

/// Builds a stable identity key for an item in a [QuiTikTokFeed].
typedef QuiTikTokFeedItemKeyBuilder<T> = Object Function(T item, int index);

/// Builds the widget for a [QuiTikTokFeed] item.
typedef QuiTikTokFeedItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

/// Called as the [QuiTikTokFeed] swipe position changes.
typedef QuiTikTokFeedProgressCallback =
    void Function({required QuiTikTokFeedAction action, required double percentage});

/// Called when [QuiTikTokFeed] needs more items.
typedef QuiTikTokFeedLoadMoreCallback = Future<void> Function();

/// Builds the load-more error card shown by [QuiTikTokFeed].
typedef QuiTikTokFeedLoadMoreErrorBuilder = Widget Function(BuildContext context, VoidCallback retry);

/// Item source used by [QuiTikTokFeed].
typedef QuiTikTokFeedItems<T> = ({
  int count,
  QuiTikTokFeedItemProvider<T> provider,
  QuiTikTokFeedItemKeyBuilder<T>? keyBuilder,
});
