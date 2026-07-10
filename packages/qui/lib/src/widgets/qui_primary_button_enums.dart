part of 'qui_primary_button.dart';

/// Controls the width sizing behavior of [QuiPrimaryButton].
enum QuiPrimaryButtonFit {
  /// The button shrink-wraps to its content.
  fit,

  /// The button expands to fill the available horizontal width.
  expand,
}

/// Controls the horizontal alignment of [QuiPrimaryButton]'s foreground
/// content (label and icons).
enum QuiPrimaryButtonAlignment {
  /// Aligns content to the left edge of the button.
  left,

  /// Centers content horizontally within the button.
  center,

  /// Aligns content to the right edge of the button.
  right,
}
