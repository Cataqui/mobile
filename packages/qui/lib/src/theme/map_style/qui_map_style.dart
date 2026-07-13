library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
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
import 'package:qui/src/theme/qui_color_scheme/qui_color_scheme.dart';

part 'qui_map_style.freezed.dart';
part 'qui_map_style.g.dart';

const _openMapTilesSource = 'openmaptiles';
final _lightMapColorScheme = QuiColorScheme.light().map;

/// A typed representation of a MapLibre GL Style JSON document.
///
/// This is the root DTO for the full MapLibre style document. It models the
/// top-level fields of the [MapLibre Style Specification](https://maplibre.org/maplibre-style-spec/root/):
/// version, id, name, metadata, sources, and layers.
///
/// ## Usage
/// Build a style instance via the [QuiMapLibreStyle.light] factory and call
/// `toJson()` to produce the MapLibre-compatible JSON map. Pass the
/// serialized JSON string directly to `maplibre_gl`'s `styleString`:
///
/// ```dart
/// final style = QuiMapLibreStyle.light(
///   tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf',
///   fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf'),
/// );
/// final styleJson = jsonEncode(style.toJson());
/// MapLibreMap(styleString: styleJson);
/// ```
///
/// ## Architecture
/// This DTO hierarchy mirrors the MapLibre style structure:
/// - Root: [QuiMapLibreStyle] with metadata, sources, and layers
/// - Layers: [QuiMapLibreStyleLayer] (background, fill, line, symbol variants)
/// - Paint properties: type-specific paint DTOs
/// - Layout properties: [QuiMapLibreStyleSymbolLayout]
/// - Values: [QuiMapLibreStyleValue] (scalar or zoom-stop function)
/// - Filters: [QuiMapLibreStyleFilter] (equals, gte, lte, any operators)
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
abstract class QuiMapLibreStyle with _$QuiMapLibreStyle {
  /// Creates a full MapLibre style document.
  ///
  /// All fields are required. For a pre-built light theme, use [QuiMapLibreStyle.light].
  const factory QuiMapLibreStyle({
    required int version,
    required String id,
    required String name,
    required String glyphs,
    required QuiMapLibreStyleMetadata metadata,
    required Map<String, QuiMapLibreStyleSource> sources,
    @QuiMapLibreStyleLayerConverter() required List<QuiMapLibreStyleLayer> layers,
  }) = _QuiMapLibreStyle;

  /// Builds the QUI light map style with runtime-configurable tile and
  /// font sources.
  ///
  /// The resulting style is ready for serialization with `toJson()`, producing
  /// a MapLibre-compatible JSON map that `maplibre_gl`'s native engine can
  /// consume directly via the `styleString` parameter.
  ///
  /// ## Configuration
  /// [tileUrlTemplate] is injected into the `openmaptiles` source's `tiles`
  /// array. [tileMinZoom] and [tileMaxZoom] control the source zoom bounds.
  /// [fontConfig] provides the font stack and glyphs URL template used by
  /// text label layers. [colorScheme] overrides the default QUI light basemap
  /// colors when a consuming app has a custom semantic map scheme.
  ///
  /// ## Layer stack
  /// The returned style contains 26 layers in the standard rendering order:
  /// 1. Background (1 layer)
  /// 2. Base fill layers — landcover, landuse, business, recreation, park, water (6 layers)
  /// 3. Base line layers — waterway, building, boundary (3 layers)
  /// 4. Road layers — tunnel, road_minor, road_tertiary, road_secondary,
  ///    road_primary, road_trunk, road_motorway, bridge (8 layers)
  /// 5. Label layers — place_state_label, place_megacity_label,
  ///    place_city_label, place_town_label, place_region_label,
  ///    road_major_label, road_local_label, poi_label (8 layers)
  factory QuiMapLibreStyle.light({
    required String tileUrlTemplate,
    required ({String fontStack, String glyphUrlTemplate}) fontConfig,
    QuiMapColorScheme? colorScheme,
    int tileMinZoom = 1,
    int tileMaxZoom = 14,
  }) => _buildLightStyle(
    tileUrlTemplate: tileUrlTemplate,
    fontStack: fontConfig.fontStack,
    glyphUrlTemplate: fontConfig.glyphUrlTemplate,
    colorScheme: colorScheme ?? _lightMapColorScheme,
    tileMinZoom: tileMinZoom,
    tileMaxZoom: tileMaxZoom,
  );
}

QuiMapLibreStyle _buildLightStyle({
  required String tileUrlTemplate,
  required String fontStack,
  required String glyphUrlTemplate,
  required QuiMapColorScheme colorScheme,
  required int tileMinZoom,
  required int tileMaxZoom,
}) {
  return QuiMapLibreStyle(
    version: 8,
    id: 'qui-light',
    name: 'Qui Light',
    glyphs: glyphUrlTemplate,
    metadata: const QuiMapLibreStyleMetadata(mapboxAutocomposite: false, mapboxType: 'template', quiStyle: 'light'),
    sources: {
      _openMapTilesSource: QuiMapLibreStyleSource(
        type: 'vector',
        tiles: [tileUrlTemplate],
        minzoom: tileMinZoom,
        maxzoom: tileMaxZoom,
      ),
    },
    layers: _buildLightLayers(fontStack: fontStack, colorScheme: colorScheme),
  );
}

List<QuiMapLibreStyleLayer> _buildLightLayers({required String fontStack, required QuiMapColorScheme colorScheme}) {
  return [
    // ── Background ──────────────────────────────────────────────────────
    QuiMapLibreStyleLayer.background(
      id: 'background',
      paint: QuiMapLibreStyleBackgroundPaint(backgroundColor: colorScheme.background.toHex()),
    ),

    // ── Fill layers ────────────────────────────────────────────────────
    QuiMapLibreStyleLayer.fill(
      id: 'landcover',
      source: _openMapTilesSource,
      sourceLayer: 'landcover',
      paint: QuiMapLibreStyleFillPaint(fillColor: colorScheme.landcover.toHex(), fillOpacity: 0.8),
    ),
    QuiMapLibreStyleLayer.fill(
      id: 'landuse',
      source: _openMapTilesSource,
      sourceLayer: 'landuse',
      paint: QuiMapLibreStyleFillPaint(fillColor: colorScheme.landuse.toHex(), fillOpacity: 0.9),
    ),
    QuiMapLibreStyleLayer.fill(
      id: 'landuse_business',
      source: _openMapTilesSource,
      sourceLayer: 'landuse',
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'commercial'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'retail'),
        ],
      ),
      paint: QuiMapLibreStyleFillPaint(fillColor: colorScheme.landuseBusiness.toHex(), fillOpacity: 0.55),
    ),
    QuiMapLibreStyleLayer.fill(
      id: 'landuse_recreation',
      source: _openMapTilesSource,
      sourceLayer: 'landuse',
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'pitch'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'playground'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'track'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'stadium'),
        ],
      ),
      paint: QuiMapLibreStyleFillPaint(fillColor: colorScheme.landuseRecreation.toHex(), fillOpacity: 0.8),
    ),
    QuiMapLibreStyleLayer.fill(
      id: 'park',
      source: _openMapTilesSource,
      sourceLayer: 'park',
      paint: QuiMapLibreStyleFillPaint(fillColor: colorScheme.park.toHex(), fillOpacity: 0.8),
    ),
    QuiMapLibreStyleLayer.fill(
      id: 'water',
      source: _openMapTilesSource,
      sourceLayer: 'water',
      paint: QuiMapLibreStyleFillPaint(fillColor: colorScheme.water.toHex(), fillOpacity: 1),
    ),

    // ── Line layers ────────────────────────────────────────────────────
    QuiMapLibreStyleLayer.line(
      id: 'waterway',
      source: _openMapTilesSource,
      sourceLayer: 'waterway',
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.waterway.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 10, value: 0.7),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 2.2),
        ]),
        lineOpacity: 0.9,
      ),
    ),
    QuiMapLibreStyleLayer.fill(
      id: 'building',
      source: _openMapTilesSource,
      sourceLayer: 'building',
      minzoom: 13,
      paint: QuiMapLibreStyleFillPaint(
        fillColor: colorScheme.building.toHex(),
        fillOutlineColor: colorScheme.buildingOutline.toHex(),
        fillOpacity: 1,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'boundary',
      source: _openMapTilesSource,
      sourceLayer: 'boundary',
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.boundary.toHex(),
        lineWidth: const QuiMapLibreStyleValue.scalar(0.7),
        lineOpacity: 0.65,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'tunnel',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'brunnel', value: 'tunnel'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.tunnel.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 10, value: 0.3),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 2),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 6),
        ]),
        lineOpacity: 0.45,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'road_minor',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'minor'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'service'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'track'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'path'),
        ],
      ),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 11, value: 0.15),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 0.45),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 1.4),
        ]),
        lineOpacity: 0.95,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'road_tertiary',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'tertiary'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 8, value: 0.25),
          QuiMapLibreStyleZoomStop(zoom: 12, value: 0.9),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 2.4),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 5.2),
        ]),
        lineOpacity: 0.82,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'road_secondary',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'secondary'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 8, value: 0.35),
          QuiMapLibreStyleZoomStop(zoom: 12, value: 1.2),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 3.3),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 7),
        ]),
        lineOpacity: 0.86,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'road_primary',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'primary'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 8, value: 0.45),
          QuiMapLibreStyleZoomStop(zoom: 12, value: 1.7),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 4.5),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 9),
        ]),
        lineOpacity: 0.9,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'road_trunk',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'trunk'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 7, value: 0.55),
          QuiMapLibreStyleZoomStop(zoom: 12, value: 2.2),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 5.8),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 11.5),
        ]),
        lineOpacity: 0.92,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'road_motorway',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'motorway'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 5, value: 0.6),
          QuiMapLibreStyleZoomStop(zoom: 10, value: 1.5),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 6),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 13.5),
        ]),
        lineOpacity: 0.95,
      ),
    ),
    QuiMapLibreStyleLayer.line(
      id: 'bridge',
      source: _openMapTilesSource,
      sourceLayer: 'transportation',
      filter: const QuiMapLibreStyleFilter.equals(key: 'brunnel', value: 'bridge'),
      paint: QuiMapLibreStyleLinePaint(
        lineColor: colorScheme.road.toHex(),
        lineWidth: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 10, value: 0.5),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 3),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 12),
        ]),
        lineOpacity: 0.9,
      ),
    ),

    // ── Symbol layers ──────────────────────────────────────────────────
    QuiMapLibreStyleLayer.symbol(
      id: 'place_state_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 3,
      maxzoom: 9,
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'state'),
      layout: QuiMapLibreStyleSymbolLayout(
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 3, value: 7),
          QuiMapLibreStyleZoomStop(zoom: 4, value: 9),
          QuiMapLibreStyleZoomStop(zoom: 5, value: 12),
          QuiMapLibreStyleZoomStop(zoom: 8, value: 18),
        ]),
        textMaxWidth: 5,
        textTransform: 'uppercase',
        textLetterSpacing: 0.15,
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.administrativeLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
        textOpacity: 0.5,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'place_megacity_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 4,
      maxzoom: 11,
      filter: const QuiMapLibreStyleFilter.greaterThanOrEqual(key: 'capital', value: 2),
      layout: QuiMapLibreStyleSymbolLayout(
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 4, value: 7),
          QuiMapLibreStyleZoomStop(zoom: 5, value: 11),
          QuiMapLibreStyleZoomStop(zoom: 8, value: 15.5),
          QuiMapLibreStyleZoomStop(zoom: 10, value: 18),
          QuiMapLibreStyleZoomStop(zoom: 11, value: 22),
        ]),
        textMaxWidth: 14,
        textAnchor: 'bottom',
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.cityLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'place_city_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 5,
      maxzoom: 11,
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'city'),
          QuiMapLibreStyleFilter.lessThanOrEqual(key: 'rank', value: 4),
        ],
      ),
      layout: QuiMapLibreStyleSymbolLayout(
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 5, value: 10),
          QuiMapLibreStyleZoomStop(zoom: 8, value: 14),
          QuiMapLibreStyleZoomStop(zoom: 10, value: 18),
          QuiMapLibreStyleZoomStop(zoom: 11, value: 20),
        ]),
        textMaxWidth: 10,
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.cityLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'place_town_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 8,
      filter: const QuiMapLibreStyleFilter.equals(key: 'class', value: 'town'),
      layout: QuiMapLibreStyleSymbolLayout(
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 8, value: 11),
          QuiMapLibreStyleZoomStop(zoom: 10, value: 13),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 18),
        ]),
        textMaxWidth: 8,
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.townLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'place_region_label',
      source: _openMapTilesSource,
      sourceLayer: 'place',
      minzoom: 11,
      maxzoom: 16,
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'suburb'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'neighbourhood'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'neighborhood'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'quarter'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'hamlet'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'village'),
        ],
      ),
      layout: QuiMapLibreStyleSymbolLayout(
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 11, value: 11),
          QuiMapLibreStyleZoomStop(zoom: 12, value: 13),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 15),
        ]),
        textMaxWidth: 11,
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.neighborhoodLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'road_major_label',
      source: _openMapTilesSource,
      sourceLayer: 'transportation_name',
      minzoom: 13,
      maxzoom: 18,
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'motorway'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'trunk'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'primary'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'secondary'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'tertiary'),
        ],
      ),
      layout: QuiMapLibreStyleSymbolLayout(
        symbolPlacement: 'line',
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 13, value: 8),
          QuiMapLibreStyleZoomStop(zoom: 14, value: 10),
          QuiMapLibreStyleZoomStop(zoom: 16, value: 12),
        ]),
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.roadMajorLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'road_local_label',
      source: _openMapTilesSource,
      sourceLayer: 'transportation_name',
      minzoom: 15,
      filter: const QuiMapLibreStyleFilter.any(
        filters: [
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'minor'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'service'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'track'),
          QuiMapLibreStyleFilter.equals(key: 'class', value: 'path'),
        ],
      ),
      layout: QuiMapLibreStyleSymbolLayout(
        symbolPlacement: 'line',
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.stops([
          QuiMapLibreStyleZoomStop(zoom: 15, value: 8),
          QuiMapLibreStyleZoomStop(zoom: 18, value: 11),
        ]),
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.roadLocalLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
    QuiMapLibreStyleLayer.symbol(
      id: 'poi_label',
      source: _openMapTilesSource,
      sourceLayer: 'poi',
      minzoom: 15,
      layout: QuiMapLibreStyleSymbolLayout(
        textField: '{name}',
        textFont: [fontStack],
        textSize: const QuiMapLibreStyleValue.scalar(13),
        textMaxWidth: 7,
      ),
      paint: QuiMapLibreStyleSymbolPaint(
        textColor: colorScheme.pointOfInterestLabel.toHex(),
        textHaloColor: colorScheme.labelHalo.toHex(),
        textHaloWidth: 1,
      ),
    ),
  ];
}
