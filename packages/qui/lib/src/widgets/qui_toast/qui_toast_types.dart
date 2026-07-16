part of 'qui_toast.dart';

/// Builds a custom icon for a [QuiToast].
///
/// Passed to [QuiToast.iconBuilder] to override the default type-driven icon.
/// The [QuiToastState] provides the state about the toast configuration so
/// the icon can be built with the same style as the default icon.
typedef QuiToastIconBuilder = Widget Function(QuiToastState state);

/// State snapshot delivered to [QuiToast] builder callbacks.
///
/// Carries the current toast context — such as layout metrics and theme
/// colors — that builders can use to render consistent widgets.
@immutable
class QuiToastState {
  /// Creates a toast state snapshot.
  const QuiToastState({required this.iconSize, required this.iconColor});

  /// Recommended icon edge size in logical pixels.
  ///
  /// This is a recommendation, not a hard constraint. The value fits circled
  /// icons perfectly; depending on the icon shape a smaller or larger value
  /// may look better. The toast reserves a fixed layout slot regardless of
  /// the size the returned widget actually renders at.
  final double iconSize;

  /// Icon color resolved from the active QUI theme for the toast's [QuiToastType].
  final Color iconColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuiToastState && other.iconSize == iconSize && other.iconColor == iconColor;

  @override
  int get hashCode => Object.hash(iconSize, iconColor);
}
