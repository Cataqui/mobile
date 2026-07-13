part of 'qui_color_scheme.dart';

@immutable
class QuiOverlayColorScheme {
  const QuiOverlayColorScheme({required this.scrim});

  final Color scrim;

  QuiOverlayColorScheme copyWith({Color? scrim}) {
    return QuiOverlayColorScheme(scrim: scrim ?? this.scrim);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuiOverlayColorScheme && scrim == other.scrim;

  @override
  int get hashCode => scrim.hashCode;

  static QuiOverlayColorScheme lerp(QuiOverlayColorScheme a, QuiOverlayColorScheme b, double t) {
    return QuiOverlayColorScheme(scrim: Color.lerp(a.scrim, b.scrim, t)!);
  }
}
