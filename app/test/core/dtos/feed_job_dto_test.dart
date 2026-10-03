import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedJobDto', () {
    test('when converting a posted job into a feed item, should preserve the location image URL', () {
      final fixture = PublicJobDto.fixture();
      final job = fixture.copyWith(location: fixture.location.copyWith(imageUrl: 'https://maps.test/static/posted'));
      expect(FeedJobDto.fromPublicJob(job).location.imageUrl, 'https://maps.test/static/posted');
    });

    test('when parsing a feed job, it should map the title', () {
      final job = FeedJobDto.fromJson({...FeedJobDto.fixture().toJson(), 'title': 'Descarregar Caminhão'});

      expect(job.title, 'Descarregar Caminhão');
    });

    test('when serializing a feed job, it should use camelCase keys', () {
      final json = FeedJobDto.fixture().toJson();

      expect(json.keys, containsAll(<String>['jobId', 'createdAt', 'descriptionSummary']));
    });
  });
}
