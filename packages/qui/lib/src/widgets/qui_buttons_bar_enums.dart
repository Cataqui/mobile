part of 'qui_buttons_bar.dart';

/// Direction used by [QuiButtonsBar] to arrange its items.
///
/// The enum exists even while only one direction is supported so the public API
/// can grow without changing the constructor shape.
enum QuiButtonsBarOrientation {
  /// Places button widgets horizontally in a single row.
  row,
}

/// Width sizing behavior used by [QuiButtonsBar].
///
/// This enum controls width only. Height is either the natural padded item
/// height or a height supplied through `QuiButtonsBar.constraints`.
enum QuiButtonsBarFit {
  /// Sizes the bar to the width of its padded items.
  fitItems,

  /// Expands the bar to the finite available maximum width.
  ///
  /// The maximum can come from the parent layout or from
  /// `QuiButtonsBar.constraints`. If no finite maximum width is available,
  /// `QuiButtonsBar` throws a [FlutterError].
  expand,
}
