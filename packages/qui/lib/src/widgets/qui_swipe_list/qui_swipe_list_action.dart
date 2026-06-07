part of 'qui_swipe_list.dart';

/// Directional swipe action emitted by [QuiSwipeList].
enum QuiSwipeListAction {
  /// Left swipe that dismisses the current item and advances to the next one.
  dismiss,

  /// Right swipe that accepts the current item without advancing the list.
  accept,
}
