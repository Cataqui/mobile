part of 'qui_edge_fade.dart';

/// A screen edge that a [QuiEdgeFade] gradient anchors to.
///
/// Controls only the gradient's opaque-to-transparent axis. The consumer is
/// responsible for placing the widget at the matching screen edge (typically
/// by wrapping it in a [Positioned] inside a [Stack]).
enum QuiEdgeFadePosition {
  /// Opaque at the top edge, transparent toward the bottom.
  top,

  /// Opaque at the bottom edge, transparent toward the top.
  bottom,
}
