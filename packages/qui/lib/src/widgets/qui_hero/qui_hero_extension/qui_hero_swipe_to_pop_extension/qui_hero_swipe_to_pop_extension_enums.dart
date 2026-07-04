part of 'qui_hero_swipe_to_pop_extension.dart';

/// The lifecycle state of a [QuiHeroSwipeToPopExtension] gesture.
enum QuiHeroSwipeToPopState {
  /// No swipe-to-pop gesture is active.
  ///
  /// This is the initial state before the user begins a downward swipe, and
  /// the final state after a gesture is cancelled or restored. When
  /// [QuiHeroSwipeToPopExtension.onSwipeStateChanged] reports [idle], the
  /// hero overlay is fully open and interactive.
  idle,

  /// A downward swipe-to-pop gesture is in progress.
  ///
  /// The hero overlay is tracking the user's finger position. When [dragging]
  /// is reported, the hero page is partially translated downward and the
  /// opacity may change to reflect the closing progress. If the user lifts
  /// their finger before reaching the [QuiHeroSwipeToPopExtension.threshold],
  /// the state returns to [idle]. If the threshold is reached, the route
  /// pops and the extension resets internally.
  dragging,
}
