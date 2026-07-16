part of 'qui_toast.dart';

/// The status category used to style a [QuiToast].
///
/// The type controls the toast background, foreground, and icon. V1 exposes
/// only [error]; future status types can extend the same switch-based resolver.
enum QuiToastType {
  /// Error feedback for failed actions or invalid states.
  error;

  /// Resolves the color triplet for this toast type using [context].
  ///
  /// Returns a record with `background`, `foreground`, and `icon` colors.
  ({Color background, Color foreground, Color icon}) colors(BuildContext context) {
    final colorScheme = context.qui.colorScheme;

    return switch (this) {
      QuiToastType.error => (
        background: colorScheme.toast.error.background,
        foreground: colorScheme.toast.error.foreground,
        icon: colorScheme.toast.error.icon,
      ),
    };
  }
}
