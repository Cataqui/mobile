import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobLocationDto', () {
    test('when parsing a job location, it should map the street', () {
      final location = JobLocationDto.fixture().copyWith(street: 'Rua das Flores, 123');

      expect(location.street, 'Rua das Flores, 123');
    });

    test(
      'when parsing a job location without street, it should keep it null',
      () {
        final location = JobLocationDto.fromJson(const <String, Object?>{
          'neighborhood': 'Centro',
          'city': 'São Paulo',
          'state': 'SP',
          'country': 'BR',
          'latitude': -23.556391,
          'longitude': -46.844076,
          'area_radius': 2000,
        });

        expect(location.street, isNull);
      },
    );
  });
}
