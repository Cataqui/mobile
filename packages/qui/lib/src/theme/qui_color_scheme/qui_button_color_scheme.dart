part of 'qui_color_scheme.dart';

/// Component-pattern roles for a single button treatment.
///
/// This group is for concrete button rendering, not for general semantic color
/// decisions. Reach for [QuiColorVariantColorScheme] when you need a reusable
/// semantic family, and for [QuiButtonColorScheme] when you already know you
/// are painting a specific button pattern.
@immutable
class QuiButtonColorScheme {
  /// Creates component-pattern roles for a single button treatment.
  const QuiButtonColorScheme({
    required this.background,
    required this.backgroundHover,
    required this.backgroundDisabled,
    required this.foreground,
    required this.foregroundDisabled,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiButtonColorScheme.lerp(QuiButtonColorScheme a, QuiButtonColorScheme b, double t) {
    return QuiButtonColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      backgroundHover: Color.lerp(a.backgroundHover, b.backgroundHover, t)!,
      backgroundDisabled: Color.lerp(a.backgroundDisabled, b.backgroundDisabled, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      foregroundDisabled: Color.lerp(a.foregroundDisabled, b.foregroundDisabled, t)!,
    );
  }

  /// Background color for the resting button surface.
  final Color background;

  /// Background color for the hovered button surface.
  final Color backgroundHover;

  /// Background color for the disabled button surface.
  final Color backgroundDisabled;

  /// Foreground color for text and icons on the resting button surface.
  final Color foreground;

  /// Foreground color for text and icons on the disabled button surface.
  final Color foregroundDisabled;

  /// {@macro qui_color_scheme_copy_with}
  QuiButtonColorScheme copyWith({
    Color? background,
    Color? backgroundHover,
    Color? backgroundDisabled,
    Color? foreground,
    Color? foregroundDisabled,
  }) {
    return QuiButtonColorScheme(
      background: background ?? this.background,
      backgroundHover: backgroundHover ?? this.backgroundHover,
      backgroundDisabled: backgroundDisabled ?? this.backgroundDisabled,
      foreground: foreground ?? this.foreground,
      foregroundDisabled: foregroundDisabled ?? this.foregroundDisabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiButtonColorScheme &&
          background == other.background &&
          backgroundHover == other.backgroundHover &&
          backgroundDisabled == other.backgroundDisabled &&
          foreground == other.foreground &&
          foregroundDisabled == other.foregroundDisabled;

  @override
  int get hashCode => Object.hash(background, backgroundHover, backgroundDisabled, foreground, foregroundDisabled);
}
