part of 'qui_color_scheme.dart';

@immutable
class QuiBrandedButtonColorScheme {
  const QuiBrandedButtonColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final QuiButtonColorScheme primary;
  final QuiButtonColorScheme secondary;
  final QuiButtonColorScheme tertiary;

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

  static QuiBrandedButtonColorScheme lerp(QuiBrandedButtonColorScheme a, QuiBrandedButtonColorScheme b, double t) {
    return QuiBrandedButtonColorScheme(
      primary: QuiButtonColorScheme.lerp(a.primary, b.primary, t),
      secondary: QuiButtonColorScheme.lerp(a.secondary, b.secondary, t),
      tertiary: QuiButtonColorScheme.lerp(a.tertiary, b.tertiary, t),
    );
  }
}
