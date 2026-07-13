part of 'qui_color_scheme.dart';

@immutable
class QuiFloatingButtonColorScheme {
  const QuiFloatingButtonColorScheme({
    required this.background,
    required this.backgroundHover,
    required this.backgroundDisabled,
    required this.foreground,
    required this.foregroundDisabled,
    required this.border,
    required this.shadow,
  });

  final Color background;
  final Color backgroundHover;
  final Color backgroundDisabled;
  final Color foreground;
  final Color foregroundDisabled;
  final Color border;
  final Color shadow;

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
  int get hashCode => Object.hash(
    background,
    backgroundHover,
    backgroundDisabled,
    foreground,
    foregroundDisabled,
    border,
    shadow,
  );

  static QuiFloatingButtonColorScheme lerp(
    QuiFloatingButtonColorScheme a,
    QuiFloatingButtonColorScheme b,
    double t,
  ) {
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
}
