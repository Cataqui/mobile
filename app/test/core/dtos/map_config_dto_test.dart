import 'package:cataqui_app/core/dtos/map_config_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapConfigDto', () {
    test('when parsing a map config, it should map the query params', () {
      final mapConfig = MapConfigDto.fixture().copyWith(queryParams: 'style=dark&lang=en-US');

      expect(mapConfig.queryParams, 'style=dark&lang=en-US');
    });

    test('when parsing a map config, it should map the expires at timestamp', () {
      final mapConfig = MapConfigDto.fixture().copyWith(expiresAt: DateTime.parse('2026-12-31T23:59:59.000Z'));

      expect(mapConfig.expiresAt, DateTime.parse('2026-12-31T23:59:59.000Z'));
    });

    test('when parsing a map config, it should map the map version', () {
      final mapConfig = MapConfigDto.fixture().copyWith(mapVersion: '2.3.1');

      expect(mapConfig.mapVersion, '2.3.1');
    });

    test('when parsing a map config, it should map the tiles url template', () {
      final mapConfig = MapConfigDto.fixture().copyWith(
        tilesUrlTemplate: 'https://tiles.example.com/v2/{z}/{x}/{y}.png',
      );

      expect(
        mapConfig.tilesUrlTemplate,
        'https://tiles.example.com/v2/{z}/{x}/{y}.png',
      );
    });

    test('when parsing a map config, it should map the glyph url template', () {
      final mapConfig = MapConfigDto.fixture().copyWith(
        glyphUrlTemplate: 'https://tiles.example.com/v2/glyphs/{fontstack}/{range}.pbf',
      );

      expect(
        mapConfig.glyphUrlTemplate,
        'https://tiles.example.com/v2/glyphs/{fontstack}/{range}.pbf',
      );
    });

    test('when parsing a map config, it should map the tile min zoom', () {
      final mapConfig = MapConfigDto.fixture().copyWith(tileMinZoom: 1);

      expect(mapConfig.tileMinZoom, 1);
    });

    test('when parsing a map config, it should map the tile max zoom', () {
      final mapConfig = MapConfigDto.fixture().copyWith(tileMaxZoom: 20);

      expect(mapConfig.tileMaxZoom, 20);
    });

    test(
      'when tile_min_zoom is missing from JSON, it should default to 0',
      () {
        final mapConfig = MapConfigDto.fromJson(const <String, Object?>{
          'query_params': 'style=streets&lang=pt-BR',
          'expires_at': '2026-06-17T12:00:00.000Z',
          'map_version': '1.0.0',
          'tiles_url_template': 'https://tiles.cataqui.dev/v1/{z}/{x}/{y}.png',
          'glyph_url_template': 'https://tiles.cataqui.dev/v1/glyphs/{fontstack}/{range}.pbf',
          'tile_max_zoom': 14,
        });

        expect(mapConfig.tileMinZoom, 0);
      },
    );

    test(
      'when tile_max_zoom is missing from JSON, it should default to 14',
      () {
        final mapConfig = MapConfigDto.fromJson(const <String, Object?>{
          'query_params': 'style=streets&lang=pt-BR',
          'expires_at': '2026-06-17T12:00:00.000Z',
          'map_version': '1.0.0',
          'tiles_url_template': 'https://tiles.cataqui.dev/v1/{z}/{x}/{y}.png',
          'glyph_url_template': 'https://tiles.cataqui.dev/v1/glyphs/{fontstack}/{range}.pbf',
          'tile_min_zoom': 0,
        });

        expect(mapConfig.tileMaxZoom, 14);
      },
    );
  });
}
