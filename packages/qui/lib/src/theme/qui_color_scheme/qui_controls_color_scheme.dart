part of 'qui_color_scheme.dart';

@immutable
class QuiControlsColorScheme {
  const QuiControlsColorScheme({
    required this.track,
    required this.trackFilled,
    required this.indicator,
    required this.indicatorForeground,
    required this.caret,
  });

  final Color track;
  final Color trackFilled;
  final Color indicator;
  final Color indicatorForeground;
  final Color caret;

  QuiControlsColorScheme copyWith({
    Color? track,
    Color? trackFilled,
    Color? indicator,
    Color? indicatorForeground,
    Color? caret,
  }) {
    return QuiControlsColorScheme(
      track: track ?? this.track,
      trackFilled: trackFilled ?? this.trackFilled,
      indicator: indicator ?? this.indicator,
      indicatorForeground: indicatorForeground ?? this.indicatorForeground,
      caret: caret ?? this.caret,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiControlsColorScheme &&
          track == other.track &&
          trackFilled == other.trackFilled &&
          indicator == other.indicator &&
          indicatorForeground == other.indicatorForeground &&
          caret == other.caret;

  @override
  int get hashCode => Object.hash(track, trackFilled, indicator, indicatorForeground, caret);

  static QuiControlsColorScheme lerp(QuiControlsColorScheme a, QuiControlsColorScheme b, double t) {
    return QuiControlsColorScheme(
      track: Color.lerp(a.track, b.track, t)!,
      trackFilled: Color.lerp(a.trackFilled, b.trackFilled, t)!,
      indicator: Color.lerp(a.indicator, b.indicator, t)!,
      indicatorForeground: Color.lerp(a.indicatorForeground, b.indicatorForeground, t)!,
      caret: Color.lerp(a.caret, b.caret, t)!,
    );
  }
}
