part of 'qui_color_scheme.dart';

/// Toast-specific roles for transient messaging surfaces.
///
/// Toasts combine a shared container treatment with status accents. This group
/// keeps those roles together so transient messaging can stay consistent
/// without borrowing unrelated status or button tokens directly.
@immutable
class QuiToastColorScheme {
  /// Creates toast-specific roles for transient messaging surfaces.
  const QuiToastColorScheme({
    required this.background,
    required this.foreground,
    required this.successAccent,
    required this.errorAccent,
    required this.warningAccent,
    required this.infoAccent,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiToastColorScheme.lerp(QuiToastColorScheme a, QuiToastColorScheme b, double t) {
    return QuiToastColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      successAccent: Color.lerp(a.successAccent, b.successAccent, t)!,
      errorAccent: Color.lerp(a.errorAccent, b.errorAccent, t)!,
      warningAccent: Color.lerp(a.warningAccent, b.warningAccent, t)!,
      infoAccent: Color.lerp(a.infoAccent, b.infoAccent, t)!,
    );
  }

  /// Container background color for toast surfaces.
  final Color background;

  /// Readable foreground color placed on the toast background.
  final Color foreground;

  /// Accent color used when the toast communicates success.
  final Color successAccent;

  /// Accent color used when the toast communicates an error.
  final Color errorAccent;

  /// Accent color used when the toast communicates a warning.
  final Color warningAccent;

  /// Accent color used when the toast communicates information.
  final Color infoAccent;

  /// {@macro qui_color_scheme_copy_with}
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
  int get hashCode => Object.hash(background, foreground, successAccent, errorAccent, warningAccent, infoAccent);
}
