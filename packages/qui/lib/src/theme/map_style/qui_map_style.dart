library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qui/src/theme/map_style/qui_map_style_background_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_converters.dart';
import 'package:qui/src/theme/map_style/qui_map_style_fill_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_filter.dart';
import 'package:qui/src/theme/map_style/qui_map_style_layer.dart';
import 'package:qui/src/theme/map_style/qui_map_style_line_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_metadata.dart';
import 'package:qui/src/theme/map_style/qui_map_style_source.dart';
import 'package:qui/src/theme/map_style/qui_map_style_symbol_layout.dart';
import 'package:qui/src/theme/map_style/qui_map_style_symbol_paint.dart';
import 'package:qui/src/theme/map_style/qui_map_style_value.dart';

part 'qui_map_style.freezed.dart';
part 'qui_map_style.g.dart';

const _openMapTilesSource = 'openmaptiles';

/// A typed representation of a MapLibre GL Style JSON document.
///
/// This is the root DTO for the full MapLibre style document. It models the
/// top-level fields of the [MapLibre Style Specification](https://maplibre.org/maplibre-style-spec/root/):
/// version, id, name, metadata, sources, and layers.
///
/// ## Usage
/// Build a style instance via the [QuiMapStyle.light] factory and call
/// `toJson()` to produce the MapLibre-compatible JSON map for use with
/// `vector_tile_renderer.ThemeReader`:
///
/// ```dart
/// final style = QuiMapStyle.light(tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf');
/// final jsonMap = style.toJson();
/// final theme = ThemeReader().read(jsonMap);
/// ```
///
/// ## Architecture
/// This DTO hierarchy mirrors the MapLibre style structure:
/// - Root: [QuiMapStyle] with metadata, sources, and layers
/// - Layers: [QuiMapStyleLayer] (background, fill, line, symbol variants)
/// - Paint properties: type-specific paint DTOs
/// - Layout properties: [QuiMapStyleSymbolLayout]
/// - Values: [QuiMapStyleValue] (scalar or zoom-stop function)
/// - Filters: [QuiMapStyleFilter] (equals, gte, lte, any operators)
///
/// ## MapLibre JSON mapping
/// ```json
/// {
///   "version": 8,
///   "id": "qui-light",
///   "name": "Qui Light",
///   "metadata": { ... },
///   "sources": { "openmaptiles": { ... } },
///   "layers": [ ... ]
/// }
/// ```
@Freezed(toJson: true, fromJson: false)
abstract class QuiMapStyle with _$QuiMapStyle {
  /// Creates a full MapLibre style document.
  ///
  /// All fields are required. For a pre-built light theme, use [QuiMapStyle.light].
  const factory QuiMapStyle({
    required int version,
    required String id,
    required String name,
    required QuiMapStyleMetadata metadata,
    required Map<String, QuiMapStyleSource> sources,
    @QuiMapStyleLayerConverter() required List<QuiMapStyleLayer> layers,
  }) = _QuiMapStyle;

  /// Builds the Cataquí light map style with runtime-configurable tile source.
  ///
  /// The resulting style is ready for serialization with `toJson()`, producing
  /// a MapLibre-compatible JSON map that the `vector_tile_renderer` package's
  /// `ThemeReader` can consume.
  ///
  /// ## Configuration
  /// [tileUrlTemplate] is injected into the `openmaptiles` source's `tiles`
  /// array. [tileMinZoom] and [tileMaxZoom] control the source zoom bounds.
  ///
  /// ## Layer stack
  /// The returned style contains 24 layers in the standard rendering order:
  /// 1. Background (1 layer)
  /// 2. Base fill layers — landcover, landuse, park, water (4 layers)
  /// 3. Base line layers — waterway, building, boundary (3 layers)
  /// 4. Road layers — tunnel, road_minor, road_tertiary, road_secondary,
  ///    road_primary, road_trunk, road_motorway, bridge (8 layers)
  /// 5. Label layers — place_state_label, place_megacity_label,
  ///    place_city_label, place_town_label, place_region_label,
  ///    road_major_label, road_local_label, poi_label (8 layers)
  factory QuiMapStyle.light({required String tileUrlTemplate, int tileMinZoom = 1, int tileMaxZoom = 14}) =>
      _buildLightStyle(tileUrlTemplate: tileUrlTemplate, tileMinZoom: tileMinZoom, tileMaxZoom: tileMaxZoom);
}

QuiMapStyle _buildLightStyle({required String tileUrlTemplate, required int tileMinZoom, required int tileMaxZoom}) {
  return QuiMapStyle(
    version: 8,
    id: 'qui-light',
    name: 'Qui Light',
    metadata: const QuiMapStyleMetadata(mapboxAutocomposite: false, mapboxType: 'template', quiStyle: 'light'),
    sources: {
      _openMapTilesSource: QuiMapStyleSource(
        type: 'vector',
        tiles: [tileUrlTemplate],
        minzoom: tileMinZoom,
        maxzoom: tileMaxZoom,
      ),
    },
    layers: _buildLightLayers(),
  );
}

List<QuiMapStyleLayer> _buildLightLayers() {
  return const [
    // ── Background ──────────────────────────────────────────────────────
    QuiMapStyleLayer.background(
      id: 'background',
      paint: QuiMapStyleBackgroundPaint(backgroundColor: '#ebedef'),
    ),

    // ── Fill layers ────────────────────────────────────────────────────
    QuiMapStyleLayer.fill(
      id: 'landcover',
      source: _openMapTilesSource,
      sourceLayer: 'landcover',
      paint: QuiMapStyleFillPaint(fillColor: '#d7d9db', fillOpacity: 0.8),
    ),
    QuiMapStyleLayer.fill(
      id: 'landuse',
      source: _openMapTilesSource,
      sourceLayer: 'landuse',
      paint: QuiMapStyleFillPaint(fillColor: '#d7d9db', fillOpacity: 0.9),
    ),
    QuiMapStyleLayer.fill(
      id: 'park',
      source: _openMapTilesSource,
      sourceLayer: 'park',
      paint: QuiMapStyleFillPaint(fillColor: '#d7d9db', fillOpacity: 0.8),
    ),
    QuiMapStyleLayer.fill(
      id: 'water',
      source: _openMapTilesSource,
      sourceLayer: 'water',
      paint: QuiMapStyleFillPaint(fillColor: '#dadbdc', fillOpacity: 1),
    ),

    // ── Line layers ────────────────────────────────────────────────────
    QuiMapStyleLayer.line(
      id: 'waterway',
      source: _openMapTilesSource,
      sourceLayer: 'waterway',
      paint: QuiMapStyleLinePaint(
        lineColor: '#dadbdc',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 10, value: 0.7),
          QuiMapStyleZoomStop(zoom: 16, value: 2.2),
        ]),
        lineOpacity: 0.9,
      ),
    ),
    QuiMapStyleLayer.fill(
      id: 'building',
      source: _openMapTilesSource,
      sourceLayer: 'building',
      minzoom: 13,
      paint: QuiMapStyleFillPaint(fillColor: '#e8e8e8', fillOutlineColor: '#d9d9d9', fillOpacity: 0.45),
    ),
    QuiMapStyleLayer.line(
      id: 'boundary',
      source: _openMapTilesSource,
      sourceLayer: 'boundary',
      paint: QuiMapStyleLinePaint(lineColor: '#b3b3b3', lineWidth: QuiMapStyleValue.scalar(0.7), lineOpacity: 0.65),
    ),
    QuiMapStyleLayer.line(
      id: 'tunnel',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'brunnel', value: 'tunnel'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#dedede',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 10, value: 0.3),
          QuiMapStyleZoomStop(zoom: 14, value: 2),
          QuiMapStyleZoomStop(zoom: 16, value: 6),
        ]),
        lineOpacity: 0.45,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'road_minor',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.any(
        filters: [
          QuiMapStyleFilter.equals(key: 'class', value: 'minor'),
          QuiMapStyleFilter.equals(key: 'class', value: 'service'),
          QuiMapStyleFilter.equals(key: 'class', value: 'track'),
          QuiMapStyleFilter.equals(key: 'class', value: 'path'),
        ],
      ),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 11, value: 0.15),
          QuiMapStyleZoomStop(zoom: 14, value: 0.45),
          QuiMapStyleZoomStop(zoom: 16, value: 1.4),
        ]),
        lineOpacity: 0.95,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'road_tertiary',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'tertiary'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 8, value: 0.25),
          QuiMapStyleZoomStop(zoom: 12, value: 0.9),
          QuiMapStyleZoomStop(zoom: 14, value: 2.4),
          QuiMapStyleZoomStop(zoom: 16, value: 5.2),
        ]),
        lineOpacity: 0.82,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'road_secondary',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'secondary'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 8, value: 0.35),
          QuiMapStyleZoomStop(zoom: 12, value: 1.2),
          QuiMapStyleZoomStop(zoom: 14, value: 3.3),
          QuiMapStyleZoomStop(zoom: 16, value: 7),
        ]),
        lineOpacity: 0.86,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'road_primary',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'primary'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 8, value: 0.45),
          QuiMapStyleZoomStop(zoom: 12, value: 1.7),
          QuiMapStyleZoomStop(zoom: 14, value: 4.5),
          QuiMapStyleZoomStop(zoom: 16, value: 9),
        ]),
        lineOpacity: 0.9,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'road_trunk',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'trunk'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 7, value: 0.55),
          QuiMapStyleZoomStop(zoom: 12, value: 2.2),
          QuiMapStyleZoomStop(zoom: 14, value: 5.8),
          QuiMapStyleZoomStop(zoom: 16, value: 11.5),
        ]),
        lineOpacity: 0.92,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'road_motorway',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'motorway'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 5, value: 0.6),
          QuiMapStyleZoomStop(zoom: 10, value: 1.5),
          QuiMapStyleZoomStop(zoom: 14, value: 6),
          QuiMapStyleZoomStop(zoom: 16, value: 13.5),
        ]),
        lineOpacity: 0.95,
      ),
    ),
    QuiMapStyleLayer.line(
      id: 'bridge',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: QuiMapStyleFilter.equals(key: 'brunnel', value: 'bridge'),
      paint: QuiMapStyleLinePaint(
        lineColor: '#ffffff',
        lineWidth: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 10, value: 0.5),
          QuiMapStyleZoomStop(zoom: 14, value: 3),
          QuiMapStyleZoomStop(zoom: 16, value: 12),
        ]),
        lineOpacity: 0.9,
      ),
    ),

    // ── Symbol layers ──────────────────────────────────────────────────
    QuiMapStyleLayer.symbol(
      id: 'place_state_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 3,
      maxzoom: 9,
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'state'),
      layout: QuiMapStyleSymbolLayout(
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 3, value: 7),
          QuiMapStyleZoomStop(zoom: 4, value: 9),
          QuiMapStyleZoomStop(zoom: 5, value: 12),
          QuiMapStyleZoomStop(zoom: 8, value: 18),
        ]),
        textMaxWidth: 5,
        textTransform: 'uppercase',
        textLetterSpacing: 0.15,
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#7b7c7d', textHaloColor: '#ffffff', textHaloWidth: 1, textOpacity: 0.5),
    ),
    QuiMapStyleLayer.symbol(
      id: 'place_megacity_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 4,
      maxzoom: 11,
      filter: QuiMapStyleFilter.greaterThanOrEqual(key: 'capital', value: 2),
      layout: QuiMapStyleSymbolLayout(
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 4, value: 7),
          QuiMapStyleZoomStop(zoom: 5, value: 11),
          QuiMapStyleZoomStop(zoom: 8, value: 15.5),
          QuiMapStyleZoomStop(zoom: 10, value: 18),
          QuiMapStyleZoomStop(zoom: 11, value: 22),
        ]),
        textMaxWidth: 14,
        textAnchor: 'bottom',
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#555657', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
    QuiMapStyleLayer.symbol(
      id: 'place_city_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 5,
      maxzoom: 11,
      filter: QuiMapStyleFilter.any(
        filters: [
          QuiMapStyleFilter.equals(key: 'class', value: 'city'),
          QuiMapStyleFilter.lessThanOrEqual(key: 'rank', value: 4),
        ],
      ),
      layout: QuiMapStyleSymbolLayout(
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 5, value: 10),
          QuiMapStyleZoomStop(zoom: 8, value: 14),
          QuiMapStyleZoomStop(zoom: 10, value: 18),
          QuiMapStyleZoomStop(zoom: 11, value: 20),
        ]),
        textMaxWidth: 10,
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#555657', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
    QuiMapStyleLayer.symbol(
      id: 'place_town_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 8,
      filter: QuiMapStyleFilter.equals(key: 'class', value: 'town'),
      layout: QuiMapStyleSymbolLayout(
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 8, value: 11),
          QuiMapStyleZoomStop(zoom: 10, value: 13),
          QuiMapStyleZoomStop(zoom: 14, value: 18),
        ]),
        textMaxWidth: 8,
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#b3b4b5', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
    QuiMapStyleLayer.symbol(
      id: 'place_region_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 11,
      maxzoom: 16,
      filter: QuiMapStyleFilter.any(
        filters: [
          QuiMapStyleFilter.equals(key: 'class', value: 'suburb'),
          QuiMapStyleFilter.equals(key: 'class', value: 'neighbourhood'),
          QuiMapStyleFilter.equals(key: 'class', value: 'neighborhood'),
          QuiMapStyleFilter.equals(key: 'class', value: 'quarter'),
          QuiMapStyleFilter.equals(key: 'class', value: 'hamlet'),
          QuiMapStyleFilter.equals(key: 'class', value: 'village'),
        ],
      ),
      layout: QuiMapStyleSymbolLayout(
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 11, value: 11),
          QuiMapStyleZoomStop(zoom: 12, value: 13),
          QuiMapStyleZoomStop(zoom: 14, value: 15),
        ]),
        textMaxWidth: 11,
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#68696a', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
    QuiMapStyleLayer.symbol(
      id: 'road_major_label',
      source: _openMapTilesSource,
      sourceLayer: 'transportation_name',
      minzoom: 13,
      maxzoom: 18,
      filter: QuiMapStyleFilter.any(
        filters: [
          QuiMapStyleFilter.equals(key: 'class', value: 'motorway'),
          QuiMapStyleFilter.equals(key: 'class', value: 'trunk'),
          QuiMapStyleFilter.equals(key: 'class', value: 'primary'),
          QuiMapStyleFilter.equals(key: 'class', value: 'secondary'),
          QuiMapStyleFilter.equals(key: 'class', value: 'tertiary'),
        ],
      ),
      layout: QuiMapStyleSymbolLayout(
        symbolPlacement: 'line',
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 13, value: 8),
          QuiMapStyleZoomStop(zoom: 14, value: 10),
          QuiMapStyleZoomStop(zoom: 16, value: 12),
        ]),
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#7b7c7d', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
    QuiMapStyleLayer.symbol(
      id: 'road_local_label',
      source: _openMapTilesSource,
      sourceLayer: 'transportation_name',
      minzoom: 15,
      filter: QuiMapStyleFilter.any(
        filters: [
          QuiMapStyleFilter.equals(key: 'class', value: 'minor'),
          QuiMapStyleFilter.equals(key: 'class', value: 'service'),
          QuiMapStyleFilter.equals(key: 'class', value: 'track'),
          QuiMapStyleFilter.equals(key: 'class', value: 'path'),
        ],
      ),
      layout: QuiMapStyleSymbolLayout(
        symbolPlacement: 'line',
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.stops([
          QuiMapStyleZoomStop(zoom: 15, value: 8),
          QuiMapStyleZoomStop(zoom: 18, value: 11),
        ]),
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#9c9d9e', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
    QuiMapStyleLayer.symbol(
      id: 'poi_label',
      source: _openMapTilesSource,
      sourceLayer: 'poi',
      minzoom: 15,
      layout: QuiMapStyleSymbolLayout(
        textField: '{name}',
        textFont: ['Inter'],
        textSize: QuiMapStyleValue.scalar(13),
        textMaxWidth: 7,
      ),
      paint: QuiMapStyleSymbolPaint(textColor: '#9c9d9e', textHaloColor: '#ffffff', textHaloWidth: 1),
    ),
  ];
}
