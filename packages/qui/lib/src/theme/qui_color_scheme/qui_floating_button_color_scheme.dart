part of 'qui_color_scheme.dart';

/// Button roles for floating action surfaces.
///
/// Floating actions have extra visual needs beyond a standard button, such as
/// a dedicated border and shadow. This group gives consumers the complete color
/// set needed to render a floating action consistently.
@immutable
class QuiFloatingButtonColorScheme {
  /// Creates button roles for floating action surfaces.
  const QuiFloatingButtonColorScheme({
    required this.background,
    required this.backgroundHover,
    required this.backgroundDisabled,
    required this.foreground,
    required this.foregroundDisabled,
    required this.border,
    required this.shadow,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiFloatingButtonColorScheme.lerp(QuiFloatingButtonColorScheme a, QuiFloatingButtonColorScheme b, double t) {
    return QuiFloatingButtonColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      backgroundHover: Color.lerp(a.backgroundHover, b.backgroundHover, t)!,
      backgroundDisabled: Color.lerp(a.backgroundDisabled, b.backgroundDisabled, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      foregroundDisabled: Color.lerp(a.foregroundDisabled, b.foregroundDisabled, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      shadow: Color.lerp(a.shadow, b.shadow, t)!,
    );
  }

  /// Background color for the resting floating button surface.
  final Color background;

  /// Background color for the hovered floating button surface.
  final Color backgroundHover;

  /// Background color for the disabled floating button surface.
  final Color backgroundDisabled;

  /// Foreground color for text and icons on the resting floating button surface.
  final Color foreground;

  /// Foreground color for text and icons on the disabled floating button surface.
  final Color foregroundDisabled;

  /// Border color that keeps the floating surface legible over variable content.
  final Color border;

  /// Shadow color used to separate the floating surface from underlying content.
  final Color shadow;

  /// {@macro qui_color_scheme_copy_with}
  QuiFloatingButtonColorScheme copyWith({
    Color? background,
    Color? backgroundHover,
    Color? backgroundDisabled,
    Color? foreground,
    Color? foregroundDisabled,
    Color? border,
    Color? shadow,
  }) {
    return QuiFloatingButtonColorScheme(
      background: background ?? this.background,
      backgroundHover: backgroundHover ?? this.backgroundHover,
      backgroundDisabled: backgroundDisabled ?? this.backgroundDisabled,
      foreground: foreground ?? this.foreground,
      foregroundDisabled: foregroundDisabled ?? this.foregroundDisabled,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiFloatingButtonColorScheme &&
          background == other.background &&
          backgroundHover == other.backgroundHover &&
          backgroundDisabled == other.backgroundDisabled &&
          foreground == other.foreground &&
          foregroundDisabled == other.foregroundDisabled &&
          border == other.border &&
          shadow == other.shadow;

  @override
  int get hashCode =>
      Object.hash(background, backgroundHover, backgroundDisabled, foreground, foregroundDisabled, border, shadow);
}
