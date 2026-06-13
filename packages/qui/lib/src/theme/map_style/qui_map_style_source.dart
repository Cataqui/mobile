/// A vector tile source in a MapLibre GL Style JSON document.
///
/// Corresponds to a single entry in the [sources](https://maplibre.org/maplibre-style-spec/sources/)
/// map. This DTO models vector tile sources with explicit tile URL templates
/// and zoom bounds.
///
/// ## MapLibre JSON mapping
/// {@template qui_source_json}
/// ```json
/// {
///   "type": "vector",
///   "tiles": ["https://example.com/{z}/{x}/{y}.pbf"],
///   "minzoom": 1,
///   "maxzoom": 14
/// }
/// ```
/// {@endtemplate}
///
/// The `tiles` field contains URL templates with `{x}`, `{y}`, `{z}` (and
/// optionally `{tileUrlTemplate}`) placeholders that the tile provider
/// substitutes at runtime.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qui/src/theme/map_style/qui_map_style.dart' show QuiMapLibreStyle;

part 'qui_map_style_source.freezed.dart';
part 'qui_map_style_source.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class QuiMapLibreStyleSource with _$QuiMapLibreStyleSource {
  const factory QuiMapLibreStyleSource({
    /// The source type. Must be `"vector"` for vector tile sources.
    required String type,

    /// List of tile URL templates.
    ///
    /// Each template may contain `{x}`, `{y}`, `{z}` placeholders for tile
    /// coordinates, and a custom placeholder like `{tileUrlTemplate}` that
    /// is resolved at runtime via [QuiMapLibreStyle.light].
    required List<String> tiles,

    /// Minimum zoom level for which tiles are available.
    required int minzoom,

    /// Maximum zoom level for which tiles are available.
    required int maxzoom,
  }) = _QuiMapLibreStyleSource;
}
