part of 'qui_color_scheme.dart';

/// Divider roles for structural separation inside QUI layouts.
///
/// Use this group when an element is acting as a separator rather than as a
/// full interactive border. The roles distinguish standard separation from
/// stronger emphasis without overloading the general border tokens.
@immutable
class QuiDividerColorScheme {
  /// Creates divider roles for structural separation inside QUI layouts.
  const QuiDividerColorScheme({required this.standard, required this.strong});

  /// {@macro qui_color_scheme_lerp}
  factory QuiDividerColorScheme.lerp(QuiDividerColorScheme a, QuiDividerColorScheme b, double t) {
    return QuiDividerColorScheme(
      standard: Color.lerp(a.standard, b.standard, t)!,
      strong: Color.lerp(a.strong, b.strong, t)!,
    );
  }

  /// Default divider color for standard structural separation.
  final Color standard;

  /// Higher-emphasis divider color for stronger separation.
  final Color strong;

  /// {@macro qui_color_scheme_copy_with}
  QuiDividerColorScheme copyWith({Color? standard, Color? strong}) {
    return QuiDividerColorScheme(standard: standard ?? this.standard, strong: strong ?? this.strong);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuiDividerColorScheme && standard == other.standard && strong == other.strong;

  @override
  int get hashCode => Object.hash(standard, strong);
}
