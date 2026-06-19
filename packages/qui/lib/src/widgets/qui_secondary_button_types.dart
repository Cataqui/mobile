part of 'qui_secondary_button.dart';

/// Builds a [QuiSecondaryButton] icon from its current state.
typedef QuiSecondaryButtonIconBuilder = Widget Function(QuiSecondaryButtonIconState state);

/// State passed to [QuiSecondaryButtonIconBuilder].
@immutable
class QuiSecondaryButtonIconState {
  /// Creates a secondary button icon state snapshot.
  const QuiSecondaryButtonIconState({required this.isEnabled, required this.recommendedIconColor});

  /// Whether the button can currently be pressed.
  final bool isEnabled;

  /// Recommended foreground color for the icon.
  final Color recommendedIconColor;
}
