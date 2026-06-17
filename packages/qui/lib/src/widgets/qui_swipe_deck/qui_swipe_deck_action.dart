part of 'qui_swipe_deck.dart';

/// Directional swipe action emitted by [QuiSwipeDeck].
enum QuiSwipeDeckAction {
  /// Left swipe that dismisses the current item and advances to the next one.
  dismiss,

  /// Right swipe that accepts the current item without advancing the deck.
  accept,
}
