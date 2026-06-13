/// Paint properties for a MapLibre GL fill layer.
///
/// Models the fill layer paint properties. Fill layers render filled polygons
/// from vector tile data.
///
/// ## MapLibre JSON mapping
/// {@template qui_fill_paint_json}
/// ```json
/// {
///   "fill-color": "#d7d9db",
///   "fill-opacity": 0.8,
///   "fill-outline-color": "#d9d9d9"
/// }
/// ```
/// {@endtemplate}
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'qui_map_style_fill_paint.freezed.dart';
part 'qui_map_style_fill_paint.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class QuiMapLibreStyleFillPaint with _$QuiMapLibreStyleFillPaint {
  const factory QuiMapLibreStyleFillPaint({
    /// The fill color as a hex string (e.g. `"#d7d9db"`).
    ///
    /// Mapped to the `fill-color` JSON key.
    @JsonKey(name: 'fill-color') required String fillColor,

    /// The fill opacity from 0 (transparent) to 1 (opaque).
    ///
    /// Mapped to the `fill-opacity` JSON key.
    @JsonKey(name: 'fill-opacity') required double fillOpacity,

    /// Optional outline color for fill polygons.
    ///
    /// Mapped to the `fill-outline-color` JSON key. When null, the outline
    /// uses the same color as the fill. Only rendered for polygons; ignored
    /// for point or line data.
    @JsonKey(name: 'fill-outline-color') String? fillOutlineColor,
  }) = _QuiMapLibreStyleFillPaint;
}
