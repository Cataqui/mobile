part of 'qui_button.dart';

/// Builds a [QuiButton] icon from its current state.
typedef QuiButtonIconBuilder = Widget Function(QuiButtonState state);

/// State passed to button builders.
@immutable
class QuiButtonState {
  /// Creates a button state snapshot.
  const QuiButtonState({required this.isEnabled, required this.foregroundColor});

  /// Whether the button can currently be pressed.
  final bool isEnabled;

  /// Foreground color derived from the button state.
  final Color foregroundColor;
}
