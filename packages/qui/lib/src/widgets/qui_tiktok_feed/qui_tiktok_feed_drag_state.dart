part of 'qui_tiktok_feed.dart';

/// Mutable visual state for the feed during drag and animation.
@immutable
class _QuiTikTokFeedDragState {
  const _QuiTikTokFeedDragState({required this.offsetY, required this.action, required this.currentIndex});

  final double offsetY;
  final QuiTikTokFeedAction action;
  final int currentIndex;

  @override
  bool operator ==(Object other) =>
      other is _QuiTikTokFeedDragState &&
      other.offsetY == offsetY &&
      other.action == action &&
      other.currentIndex == currentIndex;

  @override
  int get hashCode => Object.hash(offsetY, action, currentIndex);
}
