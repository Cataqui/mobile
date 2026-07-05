part of 'qui_edge_fade.dart';

/// The visual configuration of a single QUI edge-fade gradient.
///
/// When [color] is `null` it resolves to `context.qui.colors.background` at build time;
/// when [height] is `null` it resolves to a fraction of the viewport height.
///
/// See also:
///  * [QuiEdgeFade], the widget that renders this style.
@immutable
class QuiEdgeFadeStyle {
  /// Creates a QUI edge-fade style.
  const QuiEdgeFadeStyle({this.color, this.height});

  /// Solid color the gradient fades from.
  ///
  /// When `null`, resolves to `context.qui.colors.background` at build time.
  final Color? color;

  /// Height of the fade band, in logical pixels.
  ///
  /// When `null`, resolves to `1/7` of the device viewport height
  final double? height;

  static const double _defaultHeightFactor = 1 / 7;
  static const double _defaultMinHeight = 72;
  static const double _defaultMaxHeight = 120;

  /// Resolves `null` fields against [context], returning a fully concrete
  /// style. Used by [QuiEdgeFade] and by the hero flight shuttle so that
  /// runtime theme + viewport values are pinned before interpolation.
  QuiEdgeFadeStyle resolve(BuildContext context) {
    return QuiEdgeFadeStyle(
      color: color ?? Theme.of(context).scaffoldBackgroundColor,
      height:
          height ??
          (MediaQuery.sizeOf(context).height * _defaultHeightFactor).clamp(_defaultMinHeight, _defaultMaxHeight),
    );
  }

  /// Linearly interpolates between two styles.
  ///
  /// Both [a] and [b] must already be resolved (non-null `color`/`height`) —
  /// call [resolve] first. When either side is `null`, the other side wins
  /// (used by callers that treat an absent edge as a zero-height style).
  static QuiEdgeFadeStyle? lerp(QuiEdgeFadeStyle? a, QuiEdgeFadeStyle? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;

    return QuiEdgeFadeStyle(color: Color.lerp(a.color, b.color, t), height: lerpDouble(a.height, b.height, t));
  }

  QuiEdgeFadeStyle copyWith({Color? color, double? height}) {
    return QuiEdgeFadeStyle(color: color ?? this.color, height: height ?? this.height);
  }

  @override
  bool operator ==(Object other) => other is QuiEdgeFadeStyle && other.color == color && other.height == height;

  @override
  int get hashCode => Object.hash(color, height);
}
