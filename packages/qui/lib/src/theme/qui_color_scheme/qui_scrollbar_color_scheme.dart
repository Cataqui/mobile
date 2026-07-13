part of 'qui_color_scheme.dart';

@immutable
class QuiScrollbarColorScheme {
  const QuiScrollbarColorScheme({
    required this.thumb,
    required this.thumbHover,
    required this.track,
  });

  final Color thumb;
  final Color thumbHover;
  final Color track;

  QuiScrollbarColorScheme copyWith({
    Color? thumb,
    Color? thumbHover,
    Color? track,
  }) {
    return QuiScrollbarColorScheme(
      thumb: thumb ?? this.thumb,
      thumbHover: thumbHover ?? this.thumbHover,
      track: track ?? this.track,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiScrollbarColorScheme &&
          thumb == other.thumb &&
          thumbHover == other.thumbHover &&
          track == other.track;

  @override
  int get hashCode => Object.hash(thumb, thumbHover, track);

  static QuiScrollbarColorScheme lerp(QuiScrollbarColorScheme a, QuiScrollbarColorScheme b, double t) {
    return QuiScrollbarColorScheme(
      thumb: Color.lerp(a.thumb, b.thumb, t)!,
      thumbHover: Color.lerp(a.thumbHover, b.thumbHover, t)!,
      track: Color.lerp(a.track, b.track, t)!,
    );
  }
}
