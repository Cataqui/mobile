part of 'qui_tiktok_feed.dart';

/// Directional feed action emitted by [QuiTikTokFeed].
enum QuiTikTokFeedAction {
  /// Down swipe that goes to the previous item.
  previous,

  /// Up swipe that advances to the next item.
  next,
}

enum _QuiTikTokFeedAwaitPhase { inactive, deciding, dragging, waiting }
