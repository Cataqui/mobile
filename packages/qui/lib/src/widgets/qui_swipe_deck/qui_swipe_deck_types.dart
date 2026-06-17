part of 'qui_swipe_deck.dart';

/// Called when a [QuiSwipeDeck] item completes an action.
typedef QuiSwipeDeckItemCallback<T> = void Function(T item, int index);

/// Lazily provides the item at [index] for a [QuiSwipeDeck].
typedef QuiSwipeDeckItemProvider<T> = T Function(int index);

/// Builds the widget for a [QuiSwipeDeck] item.
typedef QuiSwipeDeckItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

/// Called as the [QuiSwipeDeck] swipe position changes.
typedef QuiSwipeDeckProgressCallback = void Function({required QuiSwipeDeckAction action, required double percentage});

/// Called when [QuiSwipeDeck] needs more items.
typedef QuiSwipeDeckLoadMoreCallback = Future<void> Function();

/// Builds the load-more error card shown by [QuiSwipeDeck].
typedef QuiSwipeDeckLoadMoreErrorBuilder = Widget Function(BuildContext context, VoidCallback retry);
