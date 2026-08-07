import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobLocationDto', () {
    test('when parsing a job location, it should map the street', () {
      final location = JobLocationDto.fromJson({...JobLocationDto.fixture().toJson(), 'street': 'Rua das Flores, 123'});

      expect(location.street, 'Rua das Flores, 123');
    });

    test('when map config and street are absent, it should parse the job location with a null street', () {
      final location = JobLocationDto.fromJson(const <String, Object?>{
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
        'country': 'BR',
        'latitude': -23.556391,
        'longitude': -46.844076,
        'areaRadius': 2000,
      });

      expect(location.street, isNull);
    });

    test('when serializing a job location, it should use camelCase keys', () {
      final json = JobLocationDto.fixture().toJson();

      expect(json, containsPair('areaRadius', 2000));
    });
  });
}
