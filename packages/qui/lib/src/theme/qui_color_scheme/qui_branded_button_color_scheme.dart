part of 'qui_color_scheme.dart';

/// Brand-specific button roles for a single external brand family.
///
/// This group keeps the familiar primary, secondary, and tertiary button shape
/// while allowing their colors to follow an external brand contract instead of
/// the app's primary slot.
@immutable
class QuiBrandedButtonColorScheme {
  /// Creates brand-specific button roles for one external brand family.
  const QuiBrandedButtonColorScheme({required this.primary, required this.secondary, required this.tertiary});

  /// {@macro qui_color_scheme_lerp}
  factory QuiBrandedButtonColorScheme.lerp(QuiBrandedButtonColorScheme a, QuiBrandedButtonColorScheme b, double t) {
    return QuiBrandedButtonColorScheme(
      primary: QuiButtonColorScheme.lerp(a.primary, b.primary, t),
      secondary: QuiButtonColorScheme.lerp(a.secondary, b.secondary, t),
      tertiary: QuiButtonColorScheme.lerp(a.tertiary, b.tertiary, t),
    );
  }

  /// Primary branded button pattern for the family.
  final QuiButtonColorScheme primary;

  /// Secondary branded button pattern for the family.
  final QuiButtonColorScheme secondary;

  /// Tertiary branded button pattern for the family.
  final QuiButtonColorScheme tertiary;

  /// {@macro qui_color_scheme_copy_with}
  QuiBrandedButtonColorScheme copyWith({
    QuiButtonColorScheme? primary,
    QuiButtonColorScheme? secondary,
    QuiButtonColorScheme? tertiary,
  }) {
    return QuiBrandedButtonColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiBrandedButtonColorScheme &&
          primary == other.primary &&
          secondary == other.secondary &&
          tertiary == other.tertiary;

  @override
  int get hashCode => Object.hash(primary, secondary, tertiary);
}
