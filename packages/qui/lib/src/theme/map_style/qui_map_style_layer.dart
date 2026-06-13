/// A typed representation of a MapLibre GL layer.
///
/// Layers define how vector tile data is rendered on the map. Each layer
/// references a source and source layer, and has a type-specific set of
/// paint and layout properties. This sealed class models the four layer
/// types used by the Cataquí light theme.
///
/// ## Layer types
/// | Variant | MapLibre type | Description |
/// |---|---|---|
/// | `background` | `background` | Solid fill behind all layers |
/// | `fill` | `fill` | Filled polygons (landcover, landuse, water, buildings) |
/// | `line` | `line` | Stroked paths (roads, boundaries, waterways) |
/// | `symbol` | `symbol` | Text labels (place names, road labels, POIs) |
///
/// ## MapLibre JSON mapping
/// Each variant produces a layer object with `id`, `type`, and type-specific
/// properties:
///
/// ```json
/// {
///   "id": "road_primary",
///   "type": "line",
///   "source": "openmaptiles",
///   "source-layer": "transportation",
///   "minzoom": 5,
///   "maxzoom": 16,
///   "filter": ["==", "class", "primary"],
///   "paint": { "line-color": "#ffffff", ... }
/// }
/// ```
///
/// See the MapLibre style spec for details on each layer type.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qui/src/theme/map_style/qui_map_style_background_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_fill_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_filter.dart';
import 'package:qui/src/theme/map_style/qui_map_style_line_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_symbol_layout.dart';
import 'package:qui/src/theme/map_style/qui_map_style_symbol_paint.dart';

part 'qui_map_style_layer.freezed.dart';

@Freezed(toJson: false, fromJson: false)
sealed class QuiMapLibreStyleLayer with _$QuiMapLibreStyleLayer {
  /// Creates a `background` layer that fills the entire map canvas.
  ///
  /// Background layers do not reference a source or source layer — they
  /// cover the full viewport. Typically the first layer in the layer stack.
  const factory QuiMapLibreStyleLayer.background({
    required String id,
    required QuiMapLibreStyleBackgroundPaint paint,
  }) = QuiMapBackgroundLayer;

  /// Creates a `fill` layer that renders filled polygons.
  ///
  /// Used for landcover, landuse, water bodies, parks, and building footprints.
  const factory QuiMapLibreStyleLayer.fill({
    required String id,
    required QuiMapLibreStyleFillPaint paint,
    String? source,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    QuiMapLibreStyleFilter? filter,
  }) = QuiMapFillLayer;

  /// Creates a `line` layer that renders stroked paths.
  ///
  /// Used for roads, boundaries, waterways, tunnels, and bridges.
  const factory QuiMapLibreStyleLayer.line({
    required String id,
    required QuiMapLibreStyleLinePaint paint,
    String? source,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    QuiMapLibreStyleFilter? filter,
  }) = QuiMapLineLayer;

  /// Creates a `symbol` layer that renders text labels.
  ///
  /// Used for place names (cities, towns, regions), road labels, and POI labels.
  const factory QuiMapLibreStyleLayer.symbol({
    required String id,
    required QuiMapLibreStyleSymbolPaint paint,
    String? source,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    QuiMapLibreStyleFilter? filter,
    QuiMapLibreStyleSymbolLayout? layout,
  }) = QuiMapSymbolLayer;
}

/// JSON serialization extension for [QuiMapLibreStyleLayer].
extension QuiMapLibreStyleLayerJson on QuiMapLibreStyleLayer {
  /// Serializes this layer to a MapLibre-compatible JSON map.
  ///
  /// Includes only non-null optional fields (source, sourceLayer, minzoom,
  /// maxzoom, filter, layout) to produce compact JSON output.
  Map<String, dynamic> toJson() => switch (this) {
        QuiMapBackgroundLayer(:final id, :final paint) => {
          'id': id,
          'type': 'background',
          'paint': paint.toJson(),
        },
        QuiMapFillLayer(
          :final id,
          :final source,
          :final sourceLayer,
          :final minzoom,
          :final maxzoom,
          :final filter,
          :final paint,
        ) =>
          {
            'id': id,
            'type': 'fill',
            if (source != null) 'source': source,
            if (sourceLayer != null) 'source-layer': sourceLayer,
            if (minzoom != null) 'minzoom': minzoom,
            if (maxzoom != null) 'maxzoom': maxzoom,
            if (filter != null) 'filter': filter.toJson(),
            'paint': paint.toJson(),
          },
        QuiMapLineLayer(
          :final id,
          :final source,
          :final sourceLayer,
          :final minzoom,
          :final maxzoom,
          :final filter,
          :final paint,
        ) =>
          {
            'id': id,
            'type': 'line',
            if (source != null) 'source': source,
            if (sourceLayer != null) 'source-layer': sourceLayer,
            if (minzoom != null) 'minzoom': minzoom,
            if (maxzoom != null) 'maxzoom': maxzoom,
            if (filter != null) 'filter': filter.toJson(),
            'paint': paint.toJson(),
          },
        QuiMapSymbolLayer(
          :final id,
          :final source,
          :final sourceLayer,
          :final minzoom,
          :final maxzoom,
          :final filter,
          :final layout,
          :final paint,
        ) =>
          {
            'id': id,
            'type': 'symbol',
            if (source != null) 'source': source,
            if (sourceLayer != null) 'source-layer': sourceLayer,
            if (minzoom != null) 'minzoom': minzoom,
            if (maxzoom != null) 'maxzoom': maxzoom,
            if (filter != null) 'filter': filter.toJson(),
            if (layout != null) 'layout': layout.toJson(),
            'paint': paint.toJson(),
          },
      };
}
