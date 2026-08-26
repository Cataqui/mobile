import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedJobLocationDto', () {
    test('when serializing a feed job location, it should use camelCase keys', () {
      final json = FeedJobLocationDto.fixture().toJson();

      expect(json, containsPair('areaRadius', 2000));
    });
  });
}
