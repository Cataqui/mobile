import 'package:flutter_test/flutter_test.dart';
import 'package:qui/src/theme/map_style/qui_map_style.dart';
import 'package:qui/src/theme/map_style/qui_map_style_layer.dart';

void main() {
  // ── Permanent: Property-based tests ─────────────────────────────────────
  group('QuiMapLibreStyle light theme properties', () {
    late QuiMapLibreStyle style;

    setUpAll(() {
      style = QuiMapLibreStyle.light(
        tileUrlTemplate: '{tileUrlTemplate}',
        fontConfig: (
          fontStack: 'Inter Regular',
          glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf',
        ),
      );
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
      expect(
        layerIds,
        containsAll(<String>[
          'background',
          'landcover',
          'landuse',
          'landuse_business',
          'landuse_recreation',
          'water',
          'building',
        ]),
      );
    });

    test('when inspecting business landuse, it should use the approved orange color', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_business');
      final paint = layer.toJson()['paint'] as Map<String, dynamic>;
      expect(paint['fill-color'], '#F4B26A');
    });

    test('when inspecting business landuse, it should use a subtle overlay opacity', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_business');
      final paint = layer.toJson()['paint'] as Map<String, dynamic>;
      expect(paint['fill-opacity'], 0.65);
    });

    test('when inspecting business landuse, it should target the landuse source layer', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_business');
      expect(layer.toJson()['source-layer'], 'landuse');
    });

    test('when inspecting business landuse, it should include commercial area classes', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_business');
      expect(layer.toJson()['filter'], [
        'any',
        ['==', 'class', 'commercial'],
        ['==', 'class', 'retail'],
      ]);
    });

    test('when inspecting recreation landuse, it should use the approved park green color', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_recreation');
      final paint = layer.toJson()['paint'] as Map<String, dynamic>;
      expect(paint['fill-color'], '#D2F3BF');
    });

    test('when inspecting recreation landuse, it should use the approved park opacity', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_recreation');
      final paint = layer.toJson()['paint'] as Map<String, dynamic>;
      expect(paint['fill-opacity'], 0.8);
    });

    test('when inspecting recreation landuse, it should target the landuse source layer', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_recreation');
      expect(layer.toJson()['source-layer'], 'landuse');
    });

    test('when inspecting recreation landuse, it should include sports field classes', () {
      final layer = style.layers.firstWhere((l) => l.toJson()['id'] == 'landuse_recreation');
      expect(layer.toJson()['filter'], [
        'any',
        ['==', 'class', 'pitch'],
        ['==', 'class', 'playground'],
        ['==', 'class', 'track'],
        ['==', 'class', 'stadium'],
      ]);
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

    test('when inspecting city labels, it should use the configured glyph font stack', () {
      expect(_textFont(style, 'place_city_label'), ['Inter Regular']);
    });

    test('when creating the light style, it should set the glyphs URL from fontConfig', () {
      expect(style.glyphs, 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf');
    });
  });
}

double _lineWidthAtZoom(QuiMapLibreStyle style, String layerId, int zoom) {
  final paint = _layerJson(style, layerId)['paint'] as Map<String, dynamic>;
  final lineWidth = paint['line-width'];
  if (lineWidth is List) {
    // Expression: ["interpolate", ["linear"], ["zoom"], z1, v1, z2, v2, ...]
    for (var i = 3; i < lineWidth.length; i += 2) {
      if ((lineWidth[i] as num).toInt() == zoom) return (lineWidth[i + 1] as num).toDouble();
    }
  }
  if (lineWidth is num) return lineWidth.toDouble();
  throw StateError('Expected line-width value at zoom $zoom.');
}

double _lineWidthAtZoom14(QuiMapLibreStyle style, String layerId) => _lineWidthAtZoom(style, layerId, 14);

double _textSizeAtZoom(QuiMapLibreStyle style, String layerId, int zoom) {
  final layerJson = _layerJson(style, layerId);
  final layout = layerJson['layout'] as Map<String, dynamic>?;
  if (layout == null) throw StateError('Expected layout');
  final textSize = layout['text-size'];
  if (textSize is List) {
    // Expression: ["interpolate", ["linear"], ["zoom"], z1, v1, z2, v2, ...]
    for (var i = 3; i < textSize.length; i += 2) {
      if ((textSize[i] as num).toInt() == zoom) return (textSize[i + 1] as num).toDouble();
    }
  }
  if (textSize is num) return textSize.toDouble();
  throw StateError('Expected text-size value at zoom $zoom.');
}

String _textColor(QuiMapLibreStyle style, String layerId) {
  final paint = _layerJson(style, layerId)['paint'] as Map<String, dynamic>;
  final textColor = paint['text-color'] as String?;
  if (textColor != null) return textColor;
  throw StateError('Expected text-color');
}

List<dynamic> _textFont(QuiMapLibreStyle style, String layerId) {
  final layout = _layerJson(style, layerId)['layout'] as Map<String, dynamic>?;
  if (layout == null) throw StateError('Expected layout');
  final textFont = layout['text-font'] as List<dynamic>?;
  if (textFont != null) return textFont;
  throw StateError('Expected text-font');
}

int _relativeLuminance(String hexColor) {
  final normalized = hexColor.replaceFirst('#', '');
  final red = int.parse(normalized.substring(0, 2), radix: 16);
  final green = int.parse(normalized.substring(2, 4), radix: 16);
  final blue = int.parse(normalized.substring(4, 6), radix: 16);
  return (red * 299) + (green * 587) + (blue * 114);
}

Map<String, dynamic> _layerJson(QuiMapLibreStyle style, String id) {
  return style.layers.firstWhere((l) => l.toJson()['id'] == id).toJson();
}
