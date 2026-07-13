part of 'qui_color_scheme.dart';

@immutable
class QuiButtonColorScheme {
  const QuiButtonColorScheme({
    required this.background,
    required this.backgroundHover,
    required this.backgroundDisabled,
    required this.foreground,
    required this.foregroundDisabled,
  });

  final Color background;
  final Color backgroundHover;
  final Color backgroundDisabled;
  final Color foreground;
  final Color foregroundDisabled;

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

  static QuiButtonColorScheme lerp(QuiButtonColorScheme a, QuiButtonColorScheme b, double t) {
    return QuiButtonColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      backgroundHover: Color.lerp(a.backgroundHover, b.backgroundHover, t)!,
      backgroundDisabled: Color.lerp(a.backgroundDisabled, b.backgroundDisabled, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      foregroundDisabled: Color.lerp(a.foregroundDisabled, b.foregroundDisabled, t)!,
    );
  }
}
