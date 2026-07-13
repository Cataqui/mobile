part of 'qui_button.dart';

/// Visual style variants available to [QuiButton].
///
/// Each variant resolves a [QuiButtonColorScheme] from the active
/// [QuiColorScheme].
enum QuiButtonVariant {
  /// Primary action style for the most important action in a view.
  primary,

  /// Secondary action style for supportive or lower-emphasis actions.
  secondary;

  /// The themed [QuiButtonColorScheme] for this variant.
  QuiButtonColorScheme colorScheme(QuiColorScheme colorScheme) {
    switch (this) {
      case QuiButtonVariant.primary:
        return colorScheme.buttons.primary;
      case QuiButtonVariant.secondary:
        return colorScheme.buttons.secondary;
    }
  }
}
