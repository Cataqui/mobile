part of 'qui_primary_button.dart';

/// Builds a [QuiPrimaryButton] icon from its current state.
typedef QuiPrimaryButtonIconBuilder = Widget Function(QuiPrimaryButtonIconState state);

/// State passed to [QuiPrimaryButtonIconBuilder].
@immutable
class QuiPrimaryButtonIconState {
  /// Creates a primary button icon state snapshot.
  const QuiPrimaryButtonIconState({required this.isEnabled, required this.recommendedIconColor});

  /// Whether the button can currently be pressed.
  final bool isEnabled;

  /// Recommended foreground color for the icon.
  final Color recommendedIconColor;
}
