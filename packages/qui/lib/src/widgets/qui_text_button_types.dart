part of 'qui_text_button.dart';

/// Builds a [QuiTextButton] icon from its current state.
typedef QuiTextButtonIconBuilder = Widget Function(QuiTextButtonIconState state);

/// State passed to [QuiTextButtonIconBuilder].
@immutable
class QuiTextButtonIconState {
  /// Creates a text button icon state snapshot.
  const QuiTextButtonIconState({required this.isEnabled, required this.recommendedIconColor});

  /// Whether the button can currently be pressed.
  final bool isEnabled;

  /// Recommended foreground color for the icon.
  final Color recommendedIconColor;
}
