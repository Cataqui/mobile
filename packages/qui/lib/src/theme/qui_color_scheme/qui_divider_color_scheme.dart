part of 'qui_color_scheme.dart';

@immutable
class QuiDividerColorScheme {
  const QuiDividerColorScheme({
    required this.standard,
    required this.strong,
  });

  final Color standard;
  final Color strong;

  QuiDividerColorScheme copyWith({
    Color? standard,
    Color? strong,
  }) {
    return QuiDividerColorScheme(
      standard: standard ?? this.standard,
      strong: strong ?? this.strong,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiDividerColorScheme &&
          standard == other.standard &&
          strong == other.strong;

  @override
  int get hashCode => Object.hash(standard, strong);

  static QuiDividerColorScheme lerp(QuiDividerColorScheme a, QuiDividerColorScheme b, double t) {
    return QuiDividerColorScheme(
      standard: Color.lerp(a.standard, b.standard, t)!,
      strong: Color.lerp(a.strong, b.strong, t)!,
    );
  }
}
