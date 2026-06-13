/// Paint properties for a MapLibre GL line layer.
///
/// Models the line layer paint properties. Line layers render stroked paths
/// from vector tile data (roads, boundaries, waterway centerlines).
///
/// ## MapLibre JSON mapping
/// {@template qui_line_paint_json}
/// ```json
/// {
///   "line-color": "#ffffff",
///   "line-width": { "stops": [[11, 0.15], [14, 0.45], [16, 1.4]] },
///   "line-opacity": 0.95
/// }
/// ```
/// {@endtemplate}
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qui/src/theme/map_style/qui_map_style_converters.dart';
import 'package:qui/src/theme/map_style/qui_map_style_value.dart';

part 'qui_map_style_line_paint.freezed.dart';
part 'qui_map_style_line_paint.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class QuiMapStyleLinePaint with _$QuiMapStyleLinePaint {
  const factory QuiMapStyleLinePaint({
    /// The line color as a hex string (e.g. `"#ffffff"`).
    ///
    /// Mapped to the `line-color` JSON key.
    @JsonKey(name: 'line-color') required String lineColor,

    /// The line width, which may be a constant scalar or a zoom-dependent stop
    /// function.
    ///
    /// Mapped to the `line-width` JSON key. Uses [QuiMapStyleValueConverter]
    /// to serialize as either a raw number or a stops object.
    /// See [QuiMapStyleValue] for value representations.
    @JsonKey(name: 'line-width')
    @QuiMapStyleValueConverter()
    required QuiMapStyleValue lineWidth,

    /// The line opacity from 0 (transparent) to 1 (opaque).
    ///
    /// Mapped to the `line-opacity` JSON key.
    @JsonKey(name: 'line-opacity') required double lineOpacity,
  }) = _QuiMapStyleLinePaint;
}
