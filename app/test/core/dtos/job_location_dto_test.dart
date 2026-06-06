import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dto_json_fixtures.dart';

void main() {
  group('JobLocationDto', () {
    test('when parsing a job location, it should map the street', () {
      final location = JobLocationDto.fromJson(
        detailedJobJson['location']! as Map<String, Object?>,
      );

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
        });

        expect(location.street, isNull);
      },
    );
  });
}
