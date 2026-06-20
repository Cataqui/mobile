part of 'qui_swipe_deck.dart';

/// Mutable visual state for the card stack during drag and animation.
@immutable
class _QuiSwipeDeckCardDragState {
  const _QuiSwipeDeckCardDragState({required this.offset, required this.action, required this.currentIndex});

  final Offset offset;
  final QuiSwipeDeckAction action;
  final int currentIndex;

  @override
  bool operator ==(Object other) =>
      other is _QuiSwipeDeckCardDragState &&
      other.offset == offset &&
      other.action == action &&
      other.currentIndex == currentIndex;

  @override
  int get hashCode => Object.hash(offset, action, currentIndex);
}
