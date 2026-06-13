import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/src/theme/map_style/qui_map_style.dart';
import 'package:qui/src/theme/map_style/qui_map_style_layer.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vector_renderer;

void main() {
  // ── Permanent: Property-based tests ─────────────────────────────────────
  group('QuiMapStyle light theme properties', () {
    late QuiMapStyle style;

    setUpAll(() {
      style = QuiMapStyle.light(tileUrlTemplate: '{tileUrlTemplate}');
    });

    test('when creating the light style, it should be a MapLibre version 8 style', () {
      expect(style.version, 8);
    });

    test('when creating the light style, it should have the expected style id', () {
      expect(style.id, 'qui-light');
    });

    test('when creating the light style, it should have the expected style name', () {
      expect(style.name, 'Qui Light');
    });

    test('when parsing the light style with ThemeReader, it should not throw', () {
      expect(() => vector_renderer.ThemeReader().read(style.toJson()), returnsNormally);
    });

    test('when inspecting sources, it should define openmaptiles as vector', () {
      final source = style.sources['openmaptiles'];
      expect(source?.type, 'vector');
    });

    test('when inspecting sources, it should keep the tileUrlTemplate placeholder', () {
      final source = style.sources['openmaptiles'];
      expect(source?.tiles, ['{tileUrlTemplate}']);
    });

    test('when inspecting sources, it should define the default minimum tile zoom', () {
      final source = style.sources['openmaptiles'];
      expect(source?.minzoom, 1);
    });

    test('when inspecting sources, it should define the default maximum tile zoom', () {
      final source = style.sources['openmaptiles'];
      expect(source?.maxzoom, 14);
    });

    test('when inspecting layers, it should keep layer ids unique', () {
      final layerIds = style.layers.map((l) => l.toJson()['id'] as String).toList();
      expect(layerIds.toSet(), hasLength(layerIds.length));
    });

    test('when inspecting layers, it should include the required base layers', () {
      final layerIds = style.layers.map((l) => l.toJson()['id'] as String).toSet();
      expect(layerIds, containsAll(<String>['background', 'landcover', 'landuse', 'water', 'building']));
    });

    test('when inspecting layers, it should include the required road layers', () {
      final layerIds = style.layers.map((l) => l.toJson()['id'] as String).toSet();
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

    test('when inspecting layers, it should include the required label layers', () {
      final layerIds = style.layers.map((l) => l.toJson()['id'] as String).toSet();
      expect(
        layerIds,
        containsAll(<String>['place_city_label', 'place_region_label', 'road_major_label', 'road_local_label']),
      );
    });

    test('when inspecting sourced layers, it should use the openmaptiles source', () {
      final sourced = style.layers.where((l) => l.toJson()['type'] != 'background');
      expect(sourced.every((l) => l.toJson()['source'] == 'openmaptiles'), isTrue);
    });

    test('when inspecting background, it should use the approved light color', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'background');
      final paint = layer.toJson()['paint'] as Map<String, dynamic>;
      expect(paint['background-color'], '#ebedef');
    });

    test('when inspecting road widths at zoom 14, it should preserve road hierarchy', () {
      final expected = [0.45, 2.4, 3.3, 4.5, 5.8, 6.0];
      final roadIds = ['road_minor', 'road_tertiary', 'road_secondary', 'road_primary', 'road_trunk', 'road_motorway'];
      final widths = roadIds.map((id) => _lineWidthAtZoom14(style, id)).toList();
      expect(widths, expected);
    });

    test('when inspecting road widths at zoom 16, it should keep motorways widest', () {
      final motorwayWidth = _lineWidthAtZoom(style, 'road_motorway', 16);
      final minorWidth = _lineWidthAtZoom(style, 'road_minor', 16);
      expect(motorwayWidth > minorWidth, isTrue);
    });

    test('when inspecting normal streets, it should use approved visible white color', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'road_minor');
      final paint = layer.toJson()['paint'] as Map<String, dynamic>;
      expect(paint['line-color'], '#ffffff');
    });

    test('when inspecting normal streets, it should keep them narrower than important roads', () {
      final minor = _lineWidthAtZoom14(style, 'road_minor');
      final tertiary = _lineWidthAtZoom14(style, 'road_tertiary');
      expect(minor < tertiary, isTrue);
    });

    test('when inspecting region labels, it should start showing neighborhoods at zoom 11', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'place_region_label');
      expect(layer.toJson()['minzoom'], 11);
    });

    test('when inspecting region labels, it should fade neighborhoods out after zoom 16', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'place_region_label');
      expect(layer.toJson()['maxzoom'], 16);
    });

    test('when inspecting label sizes at zoom 14, it should make regions larger than major roads', () {
      final region = _textSizeAtZoom(style, 'place_region_label', 14);
      final major = _textSizeAtZoom(style, 'road_major_label', 14);
      expect(region > major, isTrue);
    });

    test('when inspecting region labels at zoom 14, it should use the approved larger size', () {
      expect(_textSizeAtZoom(style, 'place_region_label', 14), 15);
    });

    test('when inspecting major road labels at zoom 14, it should use the approved smaller size', () {
      expect(_textSizeAtZoom(style, 'road_major_label', 14), 10);
    });

    test('when inspecting city labels, it should use the approved darker color', () {
      expect(_textColor(style, 'place_city_label'), '#555657');
    });

    test('when inspecting megacity labels, it should use the approved darker color', () {
      expect(_textColor(style, 'place_megacity_label'), '#555657');
    });

    test('when inspecting region labels, it should use the approved middle color', () {
      expect(_textColor(style, 'place_region_label'), '#68696a');
    });

    test('when inspecting text colors, it should make regions darker than major roads', () {
      final regionLuma = _relativeLuminance(_textColor(style, 'place_region_label'));
      final majorLuma = _relativeLuminance(_textColor(style, 'road_major_label'));
      expect(regionLuma < majorLuma, isTrue);
    });

    test('when inspecting text colors, it should make cities darker than regions', () {
      final cityLuma = _relativeLuminance(_textColor(style, 'place_city_label'));
      final regionLuma = _relativeLuminance(_textColor(style, 'place_region_label'));
      expect(cityLuma < regionLuma, isTrue);
    });

    test('when inspecting major road labels, it should start showing them at zoom 13', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'road_major_label');
      expect(layer.toJson()['minzoom'], 13);
    });

    test('when inspecting local road labels, it should start showing them at zoom 15', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'road_local_label');
      expect(layer.toJson()['minzoom'], 15);
    });

    test('when inspecting city labels, it should show cities by zoom 10', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'place_city_label');
      expect(layer.toJson()['minzoom'], lessThanOrEqualTo(10));
    });
  });
}

Future<Map<String, Object?>> _loadOriginalJson() async {
  final styleText = await rootBundle.loadString('packages/qui/assets/maps/qui_light_map_style.json', cache: false);
  final decodedStyle = jsonDecode(styleText);
  if (decodedStyle is Map<String, Object?>) return decodedStyle;
  throw StateError('Expected style to decode as a JSON object.');
}

double _lineWidthAtZoom(QuiMapStyle style, String layerId, int zoom) {
  final paint = _layerJson(style, layerId)['paint'] as Map<String, dynamic>;
  final lineWidth = paint['line-width'];
  if (lineWidth is Map<String, dynamic>) {
    final stops = lineWidth['stops'] as List;
    for (final stop in stops) {
      final values = stop as List;
      if ((values[0] as num).toInt() == zoom) return (values[1] as num).toDouble();
    }
  }
  if (lineWidth is num) return lineWidth.toDouble();
  throw StateError('Expected line-width stop at zoom $zoom.');
}

double _lineWidthAtZoom14(QuiMapStyle style, String layerId) => _lineWidthAtZoom(style, layerId, 14);

double _textSizeAtZoom(QuiMapStyle style, String layerId, int zoom) {
  final layerJson = _layerJson(style, layerId);
  final layout = layerJson['layout'] as Map<String, dynamic>?;
  if (layout == null) throw StateError('Expected layout');
  final textSize = layout['text-size'];
  if (textSize is Map<String, dynamic>) {
    final stops = textSize['stops'] as List;
    for (final stop in stops) {
      final values = stop as List;
      if ((values[0] as num).toInt() == zoom) return (values[1] as num).toDouble();
    }
  }
  if (textSize is num) return textSize.toDouble();
  throw StateError('Expected text-size stop at zoom $zoom.');
}

String _textColor(QuiMapStyle style, String layerId) {
  final paint = _layerJson(style, layerId)['paint'] as Map<String, dynamic>;
  final textColor = paint['text-color'] as String?;
  if (textColor != null) return textColor;
  throw StateError('Expected text-color');
}

int _relativeLuminance(String hexColor) {
  final normalized = hexColor.replaceFirst('#', '');
  final red = int.parse(normalized.substring(0, 2), radix: 16);
  final green = int.parse(normalized.substring(2, 4), radix: 16);
  final blue = int.parse(normalized.substring(4, 6), radix: 16);
  return (red * 299) + (green * 587) + (blue * 114);
}

Map<String, dynamic> _layerJson(QuiMapStyle style, String id) {
  return style.layers.firstWhere((l) => l.toJson()['id'] == id).toJson();
}
