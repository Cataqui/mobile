part of 'qui_tiktok_feed.dart';

/// Directional feed action emitted by [QuiTikTokFeed].
enum QuiTikTokFeedAction {
  /// Down swipe that goes to the previous item.
  previous,

  /// Up swipe that advances to the next item.
  next,
}

/// Discrete feed events that [QuiTikTokFeedController] can broadcast to
/// notification listeners.
///
/// Register a listener via [QuiTikTokFeedController.addNotificationListener]
/// to react to feed actions from any trigger source (swipe gesture,
/// controller method, pagination auto-advance, etc.).
enum QuiTikTokFeedNotification {
  /// The feed committed to advancing to the next item.
  ///
  /// Fired once per successful next-item commit, whether triggered by a
  /// swipe, [QuiTikTokFeedController.next], or automatic navigation after a
  /// load-more completes from await mode. Does not fire when the commit is
  /// canceled, snapped back, or the feed is already at the terminal page.
  nextItem,
}

enum _QuiTikTokFeedAwaitPhase { inactive, deciding, dragging, waiting }
