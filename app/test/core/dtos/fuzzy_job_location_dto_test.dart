import 'package:cataqui_app/core/dtos/fuzzy_job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FuzzyJobLocationDto', () {
    test('when parsing the public backend location, it should accept only the exposed location fields', () {
      final location = FuzzyJobLocationDto.fromJson(const <String, Object?>{
        'latitude': -23.556391,
        'longitude': -46.844076,
        'areaRadius': 2000,
        'imageUrl': 'https://maps.cataqui.com/static/fixture',
      });

      expect(location, FuzzyJobLocationDto.fixture());
    });

    test('when serializing a job location, it should use camelCase keys', () {
      final json = FuzzyJobLocationDto.fixture().toJson();

      expect(json.keys, containsAll(<String>['latitude', 'longitude', 'areaRadius']));
      expect(json.keys, isNot(contains('neighborhood')));
    });
  });
}
