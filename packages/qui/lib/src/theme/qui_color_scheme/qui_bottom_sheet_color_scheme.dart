part of 'qui_color_scheme.dart';

/// Semantic colors for QUI bottom sheets.
///
/// Use these roles for a bottom sheet instead of
/// borrowing general background or border tokens. This keeps bottom-sheet
/// styling independently themeable while the default light scheme remains
/// aligned with the app background and neutral palette.
@immutable
class QuiBottomSheetColorScheme {
  /// Creates semantic colors for QUI bottom sheets.
  const QuiBottomSheetColorScheme({required this.background, required this.handle});

  /// {@macro qui_color_scheme_lerp}
  factory QuiBottomSheetColorScheme.lerp(QuiBottomSheetColorScheme a, QuiBottomSheetColorScheme b, double t) {
    return QuiBottomSheetColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      handle: Color.lerp(a.handle, b.handle, t)!,
    );
  }

  /// Surface color behind bottom-sheet content.
  final Color background;

  /// Subtle color for the draggable handle on a bottom-sheet surface.
  final Color handle;

  /// {@macro qui_color_scheme_copy_with}
  QuiBottomSheetColorScheme copyWith({Color? background, Color? handle}) {
    return QuiBottomSheetColorScheme(background: background ?? this.background, handle: handle ?? this.handle);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiBottomSheetColorScheme && background == other.background && handle == other.handle;

  @override
  int get hashCode => Object.hash(background, handle);
}
