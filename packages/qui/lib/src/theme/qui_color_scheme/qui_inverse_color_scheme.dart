part of 'qui_color_scheme.dart';

@immutable
class QuiInverseColorScheme {
  const QuiInverseColorScheme({required this.background, required this.onBackground, required this.primary});

  final Color background;
  final Color onBackground;
  final Color primary;

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

  static QuiInverseColorScheme lerp(QuiInverseColorScheme a, QuiInverseColorScheme b, double t) {
    return QuiInverseColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      onBackground: Color.lerp(a.onBackground, b.onBackground, t)!,
      primary: Color.lerp(a.primary, b.primary, t)!,
    );
  }
}
