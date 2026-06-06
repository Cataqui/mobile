import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dto_json_fixtures.dart';

void main() {
  group('FeedJobDto', () {
    test('when parsing a feed job, it should map the title', () {
      final job = FeedJobDto.fromJson(feedJobsJson.first);

      expect(job.title, 'Mock: ajudante para descarregar caminhão');
    });

    test('when parsing a feed job, it should map the location', () {
      final job = FeedJobDto.fromJson(feedJobsJson.first);

      expect(job.location.neighborhood, 'Centro');
    });
  });
}
