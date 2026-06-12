import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vector_renderer;

void main() {
  group('QuiLocationRadiusMap style asset', () {
    test('when loaded, it should be a MapLibre version 8 style', () async {
      final style = await _loadStyle();

      expect(style['version'], 8);
    });

    test('when loaded, it should have the expected style id', () async {
      final style = await _loadStyle();

      expect(style['id'], 'qui-light');
    });

    test('when loaded, it should have the expected style name', () async {
      final style = await _loadStyle();

      expect(style['name'], 'Qui Light');
    });

    test('when loaded, it should not contain Mapbox proprietary URLs', () async {
      final style = await _loadStyle();

      expect(_containsText(style, 'mapbox://'), isFalse);
    });

    test('when loaded, it should parse with vector_tile_renderer ThemeReader', () async {
      final style = await _loadStyle();

      expect(() => vector_renderer.ThemeReader().read(style), returnsNormally);
    });

    test('when inspecting sources, it should define openmaptiles as vector', () async {
      final style = await _loadStyle();

      expect(_source(style)['type'], 'vector');
    });

    test('when inspecting sources, it should keep tileUrlTemplate as a runtime placeholder', () async {
      final style = await _loadStyle();

      expect(_source(style)['tiles'], ['{tileUrlTemplate}']);
    });

    test('when inspecting sources, it should define the default minimum tile zoom', () async {
      final style = await _loadStyle();

      expect(_source(style)['minzoom'], 1);
    });

    test('when inspecting sources, it should define the default maximum tile zoom', () async {
      final style = await _loadStyle();

      expect(_source(style)['maxzoom'], 14);
    });

    test('when inspecting layers, it should keep layer ids unique', () async {
      final style = await _loadStyle();
      final layerIds = _layers(style).map((layer) => layer['id']).toList();

      expect(layerIds.toSet(), hasLength(layerIds.length));
    });

    test('when inspecting layers, it should include the required base layers', () async {
      final style = await _loadStyle();
      final layerIds = _layers(style).map((layer) => layer['id']).toSet();

      expect(layerIds, containsAll(<String>['background', 'landcover', 'landuse', 'water', 'building']));
    });

    test('when inspecting layers, it should include the required road layers', () async {
      final style = await _loadStyle();
      final layerIds = _layers(style).map((layer) => layer['id']).toSet();

      expect(
        layerIds,
        containsAll(<String>[
          'road_minor',
          'road_tertiary',
          'road_secondary',
          'road_primary',
          'road_trunk',
          'road_motorway',
        ]),
      );
    });

    test('when inspecting layers, it should include the required label layers', () async {
      final style = await _loadStyle();
      final layerIds = _layers(style).map((layer) => layer['id']).toSet();

      expect(
        layerIds,
        containsAll(<String>['place_city_label', 'place_region_label', 'road_major_label', 'road_local_label']),
      );
    });

    test('when inspecting sourced layers, it should use the openmaptiles source', () async {
      final style = await _loadStyle();
      final sourcedLayers = _layers(style).where((layer) => layer['type'] != 'background');

      expect(sourcedLayers.every((layer) => layer['source'] == 'openmaptiles'), isTrue);
    });

    test('when inspecting background, it should use the approved light color', () async {
      final style = await _loadStyle();

      expect(_paint(_layer(style, 'background'))['background-color'], '#ebedef');
    });

    test('when inspecting road widths at zoom 14, it should preserve road hierarchy', () async {
      final style = await _loadStyle();

      expect(_roadWidthsAtZoom(style, 14), [0.45, 2.4, 3.3, 4.5, 5.8, 6]);
    });

    test('when inspecting road widths at zoom 16, it should keep motorways widest', () async {
      final style = await _loadStyle();

      expect(
        _lineWidthAtZoom(_layer(style, 'road_motorway'), 16) > _lineWidthAtZoom(_layer(style, 'road_minor'), 16),
        isTrue,
      );
    });

    test('when inspecting region labels, it should start showing neighborhoods at zoom 11', () async {
      final style = await _loadStyle();

      expect(_layer(style, 'place_region_label')['minzoom'], 11);
    });

    test('when inspecting region labels, it should fade neighborhoods out after zoom 16', () async {
      final style = await _loadStyle();

      expect(_layer(style, 'place_region_label')['maxzoom'], 16);
    });

    test('when inspecting major road labels, it should start showing them at zoom 13', () async {
      final style = await _loadStyle();

      expect(_layer(style, 'road_major_label')['minzoom'], 13);
    });

    test('when inspecting local road labels, it should start showing them at zoom 15', () async {
      final style = await _loadStyle();

      expect(_layer(style, 'road_local_label')['minzoom'], 15);
    });

    test('when inspecting city labels, it should show cities by zoom 10', () async {
      final style = await _loadStyle();

      expect(_layer(style, 'place_city_label')['minzoom'], lessThanOrEqualTo(10));
    });
  });
}

Future<Map<String, Object?>> _loadStyle() async {
  final styleText = await rootBundle.loadString('packages/qui/assets/maps/qui_light_map_style.json', cache: false);
  final decodedStyle = jsonDecode(styleText);

  if (decodedStyle is Map<String, Object?>) return decodedStyle;

  throw StateError('Expected style to decode as a JSON object.');
}

Map<String, Object?> _source(Map<String, Object?> style) {
  final sources = style['sources'];
  if (sources is Map<String, Object?>) {
    final source = sources['openmaptiles'];
    if (source is Map<String, Object?>) return source;
  }

  throw StateError('Expected openmaptiles source.');
}

List<Map<String, Object?>> _layers(Map<String, Object?> style) {
  final layers = style['layers'];
  if (layers is List<Object?>) {
    return layers.map(_mapFromJson).toList();
  }

  throw StateError('Expected layers list.');
}

Map<String, Object?> _layer(Map<String, Object?> style, String id) {
  return _layers(style).singleWhere((layer) => layer['id'] == id);
}

Map<String, Object?> _paint(Map<String, Object?> layer) {
  final paint = layer['paint'];
  if (paint is Map<String, Object?>) return paint;

  throw StateError('Expected layer paint.');
}

List<double> _roadWidthsAtZoom(Map<String, Object?> style, int zoom) {
  return <String>[
    'road_minor',
    'road_tertiary',
    'road_secondary',
    'road_primary',
    'road_trunk',
    'road_motorway',
  ].map((layerId) => _lineWidthAtZoom(_layer(style, layerId), zoom)).toList();
}

double _lineWidthAtZoom(Map<String, Object?> layer, int zoom) {
  final lineWidth = _paint(layer)['line-width'];
  if (lineWidth is Map<String, Object?>) {
    final stops = lineWidth['stops'];
    if (stops is List<Object?>) {
      for (final stop in stops) {
        final values = _listFromJson(stop);
        if (values.first == zoom) return (values.last! as num).toDouble();
      }
    }
  }

  throw StateError('Expected line-width stop at zoom $zoom.');
}

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;

  throw StateError('Expected JSON map.');
}

List<Object?> _listFromJson(Object? value) {
  if (value is List<Object?>) return value;

  throw StateError('Expected JSON list.');
}

bool _containsText(Object? value, String text) {
  if (value is String) return value.contains(text);
  if (value is List<Object?>) return value.any((item) => _containsText(item, text));
  if (value is Map<String, Object?>) return value.values.any((item) => _containsText(item, text));

  return false;
}
