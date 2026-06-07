part of 'qui_swipe_list.dart';

/// Called when a [QuiSwipeList] item completes an action.
typedef QuiSwipeListItemCallback<T> = void Function(T item, int index);

/// Lazily provides the item at [index] for a [QuiSwipeList].
typedef QuiSwipeListItemProvider<T> = T Function(int index);

/// Builds the widget for a [QuiSwipeList] item.
typedef QuiSwipeListItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

/// Called as the [QuiSwipeList] swipe position changes.
typedef QuiSwipeListProgressCallback = void Function({required QuiSwipeListAction action, required double percentage});

/// Called when [QuiSwipeList] needs more items.
typedef QuiSwipeListLoadMoreCallback = Future<void> Function();

/// Builds the load-more error card shown by [QuiSwipeList].
typedef QuiSwipeListLoadMoreErrorBuilder = Widget Function(BuildContext context, VoidCallback retry);
