import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobLocationDto', () {
    test('when parsing the public backend location, it should accept only the exposed location fields', () {
      final location = JobLocationDto.fromJson(const <String, Object?>{
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
        'country': 'BR',
        'latitude': -23.556391,
        'longitude': -46.844076,
        'areaRadius': 2000,
      });

      expect(location, JobLocationDto.fixture());
    });

    test('when serializing a job location, it should use camelCase keys', () {
      final json = JobLocationDto.fixture().toJson();

      expect(json.keys, isNot(contains('street')));
    });
  });
}
