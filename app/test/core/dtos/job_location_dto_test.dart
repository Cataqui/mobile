import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:cataqui_app/core/dtos/map_config_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobLocationDto', () {
    test('when parsing a job location, it should map the street', () {
      final location = JobLocationDto.fixture().copyWith(street: 'Rua das Flores, 123');

      expect(location.street, 'Rua das Flores, 123');
    });

    test('when parsing a job location without street, it should keep it null', () {
      final location = JobLocationDto.fromJson(const <String, Object?>{
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
        'country': 'BR',
        'latitude': -23.556391,
        'longitude': -46.844076,
        'area_radius': 2000,
        'map_config': <String, Object?>{
          'query_params': 'style=streets&lang=pt-BR',
          'expires_at': '2026-06-17T12:00:00.000Z',
          'map_version': '1.0.0',
          'tiles_url_template': 'https://tiles.cataqui.dev/v1/{z}/{x}/{y}.png',
          'glyph_url_template': 'https://tiles.cataqui.dev/v1/glyphs/{fontstack}/{range}.pbf',
          'fontstack': 'inter',
          'tile_min_zoom': 0,
          'tile_max_zoom': 16,
        },
      });

      expect(location.street, isNull);
    });

    test('when parsing a job location, it should map the map config version', () {
      final location = JobLocationDto.fixture().copyWith(
        mapConfig: MapConfigDto.fixture().copyWith(mapVersion: '2.3.1'),
      );

      expect(location.mapConfig.mapVersion, '2.3.1');
    });
  });
}
