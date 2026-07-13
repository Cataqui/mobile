part of 'qui_color_scheme.dart';

/// Scrollbar roles for QUI scroll surfaces.
///
/// This group exists so scrollbar chrome can be themed independently from
/// general borders or controls while still remaining part of the semantic color
/// contract.
@immutable
class QuiScrollbarColorScheme {
  /// Creates scrollbar roles for QUI scroll surfaces.
  const QuiScrollbarColorScheme({required this.thumb, required this.thumbHover, required this.track});

  /// {@macro qui_color_scheme_lerp}
  factory QuiScrollbarColorScheme.lerp(QuiScrollbarColorScheme a, QuiScrollbarColorScheme b, double t) {
    return QuiScrollbarColorScheme(
      thumb: Color.lerp(a.thumb, b.thumb, t)!,
      thumbHover: Color.lerp(a.thumbHover, b.thumbHover, t)!,
      track: Color.lerp(a.track, b.track, t)!,
    );
  }

  /// Thumb color for the resting scrollbar handle.
  final Color thumb;

  /// Thumb color for the hovered scrollbar handle.
  final Color thumbHover;

  /// Track color behind the scrollbar thumb.
  final Color track;

  /// {@macro qui_color_scheme_copy_with}
  QuiScrollbarColorScheme copyWith({Color? thumb, Color? thumbHover, Color? track}) {
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
}
