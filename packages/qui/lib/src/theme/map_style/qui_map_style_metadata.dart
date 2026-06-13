/// Metadata embedded in a MapLibre GL Style JSON document.
///
/// These fields are informational and do not affect rendering. They follow
/// MapLibre GL's metadata convention, which allows arbitrary key-value pairs.
/// This DTO models the specific keys used by the Cataquí light theme.
///
/// The `mapbox:*` keys are inherited from the Mapbox Style Specification and
/// remain stable in MapLibre. The `qui:*` key is Cataquí-specific.
///
/// ## MapLibre JSON mapping
/// {@template qui_metadata_json}
/// ```json
/// {
///   "mapbox:autocomposite": false,
///   "mapbox:type": "template",
///   "qui:style": "light"
/// }
/// ```
/// {@endtemplate}
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'qui_map_style_metadata.freezed.dart';
part 'qui_map_style_metadata.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class QuiMapLibreStyleMetadata with _$QuiMapLibreStyleMetadata {
  const factory QuiMapLibreStyleMetadata({
    /// Whether Mapbox GL can auto-composite raster tiles.
    ///
    /// Mapped to the `mapbox:autocomposite` JSON key. Set to `false` for
    /// vector tile sources where compositing is handled by the renderer.
    @JsonKey(name: 'mapbox:autocomposite') required bool mapboxAutocomposite,

    /// The style type identifier.
    ///
    /// Mapped to the `mapbox:type` JSON key. `"template"` indicates this is a
    /// base style designed to be extended or modified at consumption time.
    @JsonKey(name: 'mapbox:type') required String mapboxType,

    /// Cataquí-specific style variant.
    ///
    /// Mapped to the `qui:style` JSON key. Identifies the theme variant for
    /// debugging and asset auditing (e.g. `"light"`, `"dark"`).
    @JsonKey(name: 'qui:style') required String quiStyle,
  }) = _QuiMapLibreStyleMetadata;
}
