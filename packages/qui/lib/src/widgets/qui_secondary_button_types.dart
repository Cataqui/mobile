part of 'qui_secondary_button.dart';

/// Builds a [QuiSecondaryButton] icon from its current state.
typedef QuiSecondaryButtonIconBuilder = Widget Function(QuiSecondaryButtonIconState state);

/// State passed to [QuiSecondaryButtonIconBuilder].
@immutable
class QuiSecondaryButtonIconState {
  /// Creates a secondary button icon state snapshot.
  const QuiSecondaryButtonIconState({required this.isEnabled, required this.foregroundColor});

  /// Whether the button can currently be pressed.
  final bool isEnabled;

  /// Foreground color derived from the button state.
  final Color foregroundColor;
}
