part of 'qui_color_scheme.dart';

/// Semantic roles for input and selection control chrome.
///
/// Use this group for shared control mechanics such as tracks, indicators, and
/// carets. It exists so switches, sliders, toggles, text fields, and similar
/// controls can align on consistent control-specific roles without borrowing
/// from unrelated button or text groups.
@immutable
class QuiControlsColorScheme {
  /// Creates semantic roles for input and selection control chrome.
  const QuiControlsColorScheme({
    required this.track,
    required this.trackFilled,
    required this.indicator,
    required this.indicatorForeground,
    required this.caret,
  });

  /// {@macro qui_color_scheme_lerp}
  factory QuiControlsColorScheme.lerp(QuiControlsColorScheme a, QuiControlsColorScheme b, double t) {
    return QuiControlsColorScheme(
      track: Color.lerp(a.track, b.track, t)!,
      trackFilled: Color.lerp(a.trackFilled, b.trackFilled, t)!,
      indicator: Color.lerp(a.indicator, b.indicator, t)!,
      indicatorForeground: Color.lerp(a.indicatorForeground, b.indicatorForeground, t)!,
      caret: Color.lerp(a.caret, b.caret, t)!,
    );
  }

  /// Unfilled track color for controls such as sliders and toggles.
  final Color track;

  /// Filled track color for selected or progressed control tracks.
  final Color trackFilled;

  /// Indicator color for movable control elements such as thumbs or toggles.
  final Color indicator;

  /// Foreground color rendered on top of a control indicator.
  final Color indicatorForeground;

  /// Caret color for editable text and similar insertion markers.
  final Color caret;

  /// {@macro qui_color_scheme_copy_with}
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
}
