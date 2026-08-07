import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedJobLocationDto', () {
    test('when map config is absent, it should parse the feed job location', () {
      final location = FeedJobLocationDto.fromJson(const <String, Object?>{
        'neighborhood': 'Centro',
        'latitude': -23.556391,
        'longitude': -46.844076,
        'areaRadius': 2000,
      });

      expect(location.neighborhood, 'Centro');
    });

    test('when serializing a feed job location, it should use camelCase keys', () {
      final json = FeedJobLocationDto.fixture().toJson();

      expect(json, containsPair('areaRadius', 2000));
    });
  });
}
