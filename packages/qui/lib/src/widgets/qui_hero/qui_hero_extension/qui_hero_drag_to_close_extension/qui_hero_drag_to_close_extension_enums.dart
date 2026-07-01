part of 'qui_hero_drag_to_close_extension.dart';

/// The lifecycle state of a [QuiHeroDragToCloseExtension] gesture.
enum QuiHeroDragToCloseState {
  /// No drag-to-close gesture is active.
  ///
  /// This is the initial state before the user begins a downward drag, and
  /// the final state after a gesture is cancelled or restored. When
  /// [QuiHeroDragToCloseExtension.onDragStateChanged] reports [idle], the
  /// hero overlay is fully open and interactive.
  idle,

  /// A downward drag-to-close gesture is in progress.
  ///
  /// The hero overlay is tracking the user's finger position. When [dragging]
  /// is reported, the hero page is partially translated downward and the
  /// opacity may change to reflect the closing progress. If the user lifts
  /// their finger before reaching the [QuiHeroDragToCloseExtension.commitThreshold],
  /// the state returns to [idle]. If the threshold is reached, the route
  /// pops and the extension resets internally.
  dragging,
}
