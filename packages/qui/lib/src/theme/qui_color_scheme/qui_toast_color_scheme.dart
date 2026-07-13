part of 'qui_color_scheme.dart';

@immutable
class QuiToastColorScheme {
  const QuiToastColorScheme({
    required this.background,
    required this.foreground,
    required this.successAccent,
    required this.errorAccent,
    required this.warningAccent,
    required this.infoAccent,
  });

  final Color background;
  final Color foreground;
  final Color successAccent;
  final Color errorAccent;
  final Color warningAccent;
  final Color infoAccent;

  QuiToastColorScheme copyWith({
    Color? background,
    Color? foreground,
    Color? successAccent,
    Color? errorAccent,
    Color? warningAccent,
    Color? infoAccent,
  }) {
    return QuiToastColorScheme(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      successAccent: successAccent ?? this.successAccent,
      errorAccent: errorAccent ?? this.errorAccent,
      warningAccent: warningAccent ?? this.warningAccent,
      infoAccent: infoAccent ?? this.infoAccent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiToastColorScheme &&
          background == other.background &&
          foreground == other.foreground &&
          successAccent == other.successAccent &&
          errorAccent == other.errorAccent &&
          warningAccent == other.warningAccent &&
          infoAccent == other.infoAccent;

  @override
  int get hashCode => Object.hash(
    background,
    foreground,
    successAccent,
    errorAccent,
    warningAccent,
    infoAccent,
  );

  static QuiToastColorScheme lerp(QuiToastColorScheme a, QuiToastColorScheme b, double t) {
    return QuiToastColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      successAccent: Color.lerp(a.successAccent, b.successAccent, t)!,
      errorAccent: Color.lerp(a.errorAccent, b.errorAccent, t)!,
      warningAccent: Color.lerp(a.warningAccent, b.warningAccent, t)!,
      infoAccent: Color.lerp(a.infoAccent, b.infoAccent, t)!,
    );
  }
}
