part of 'qui_color_scheme.dart';

/// High-contrast inverse surface roles.
///
/// Use this group when a surface intentionally flips away from the default page
/// background, such as dark chips, inverse banners, or emphasized containers.
/// These roles stay separate from [QuiColorScheme.text] and
/// [QuiColorScheme.background] so consumers can style inverse surfaces without
/// mixing default-surface roles into them.
@immutable
class QuiInverseColorScheme {
  /// Creates high-contrast inverse surface roles.
  const QuiInverseColorScheme({required this.background, required this.onBackground, required this.primary});

  /// {@macro qui_color_scheme_lerp}
  factory QuiInverseColorScheme.lerp(QuiInverseColorScheme a, QuiInverseColorScheme b, double t) {
    return QuiInverseColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      onBackground: Color.lerp(a.onBackground, b.onBackground, t)!,
      primary: Color.lerp(a.primary, b.primary, t)!,
    );
  }

  /// Background color for the inverse surface.
  final Color background;

  /// Readable foreground color placed on [background].
  final Color onBackground;

  /// Primary accent color intended for use within inverse surfaces.
  final Color primary;

  /// {@macro qui_color_scheme_copy_with}
  QuiInverseColorScheme copyWith({Color? background, Color? onBackground, Color? primary}) {
    return QuiInverseColorScheme(
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      primary: primary ?? this.primary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiInverseColorScheme &&
          background == other.background &&
          onBackground == other.onBackground &&
          primary == other.primary;

  @override
  int get hashCode => Object.hash(background, onBackground, primary);
}
