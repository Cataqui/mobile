part of 'qui_hero.dart';

/// The top and bottom edge-fade configuration for a [QuiHero.background].
///
/// Each side accepts a [QuiEdgeFadeStyle]. When a side is `null`, no fade is
/// rendered on that edge at rest. During a hero flight, an absent side on one
/// endpoint animates its height to `0` against the present side so the fade
/// gracefully grows in or out instead of jumping.
///
/// See also:
///  * [QuiEdgeFadeStyle], the style of a single fade edge.
///  * [QuiEdgeFade], the widget that renders a single fade edge.
@immutable
class QuiHeroEdgeFade {
  /// Creates a QUI hero edge-fade configuration.
  const QuiHeroEdgeFade({this.top, this.bottom});

  /// Style for the top edge fade. `null` means no top fade at rest.
  final QuiEdgeFadeStyle? top;

  /// Style for the bottom edge fade. `null` means no bottom fade at rest.
  final QuiEdgeFadeStyle? bottom;

  /// Convenience constant enabling both vertical edges with default
  /// (runtime-resolved) styles — mirrors [QuiEdgeFade]'s out-of-the-box look
  /// on both the top and bottom edges.
  static const vertical = QuiHeroEdgeFade(top: QuiEdgeFadeStyle(), bottom: QuiEdgeFadeStyle());

  /// Returns the style for a given [position], or `null` if that side has no
  /// fade configured.
  QuiEdgeFadeStyle? styleFor(QuiEdgeFadePosition position) {
    return switch (position) {
      QuiEdgeFadePosition.top => top,
      QuiEdgeFadePosition.bottom => bottom,
    };
  }

  /// Resolves both sides against [context] so the flight shuttle can
  /// interpolate fully concrete styles. Absent sides become a style with
  /// `height: 0` and the resolved background color, so lerping to/from an
  /// absent side animates height to/from `0` rather than jumping.
  QuiHeroEdgeFade resolve(BuildContext context) {
    final resolvedColor = Theme.of(context).extension<QuiThemeData>()?.colors.background ?? const Color(0xFFFFFFFF);

    return QuiHeroEdgeFade(
      top: top?.resolve(context) ?? QuiEdgeFadeStyle(color: resolvedColor, height: 0),
      bottom: bottom?.resolve(context) ?? QuiEdgeFadeStyle(color: resolvedColor, height: 0),
    );
  }

  /// Interpolates between two resolved configurations. Both sides are always
  /// lerped; callers should render a side only when its lerped `height > 0`.
  // ignore: prefer_constructors_over_static_methods
  static QuiHeroEdgeFade lerp(QuiHeroEdgeFade a, QuiHeroEdgeFade b, double t) {
    return QuiHeroEdgeFade(
      top: QuiEdgeFadeStyle.lerp(a.top, b.top, t),
      bottom: QuiEdgeFadeStyle.lerp(a.bottom, b.bottom, t),
    );
  }

  QuiHeroEdgeFade copyWith({QuiEdgeFadeStyle? top, QuiEdgeFadeStyle? bottom}) =>
      QuiHeroEdgeFade(top: top ?? this.top, bottom: bottom ?? this.bottom);

  @override
  bool operator ==(Object other) => other is QuiHeroEdgeFade && other.top == top && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(top, bottom);
}
