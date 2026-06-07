part of 'qui_icon_button.dart';

/// Builds a [QuiIconButton] icon from its current state.
typedef QuiIconButtonIconBuilder = Widget Function(QuiIconButtonIconState state);

/// State passed to [QuiIconButtonIconBuilder].
@immutable
class QuiIconButtonIconState {
  /// Creates an icon button state snapshot.
  const QuiIconButtonIconState({required this.isEnabled, required this.recommendedIconColor, required this.iconSize});

  /// Whether the button can currently be pressed.
  final bool isEnabled;

  /// Recommended foreground color for the icon.
  final Color recommendedIconColor;

  /// Recommended icon size.
  final double iconSize;
}
