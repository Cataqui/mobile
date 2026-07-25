import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedJobDto', () {
    test('when parsing a feed job, it should map the title', () {
      final job = FeedJobDto.fromJson({...FeedJobDto.fixture().toJson(), 'title': 'Descarregar Caminhão'});

      expect(job.title, 'Descarregar Caminhão');
    });

    test('when parsing a feed job, it should map the location', () {
      final job = FeedJobDto.fromJson({
        ...FeedJobDto.fixture().toJson(),
        'location': FeedJobLocationDto.fixture().copyWith(neighborhood: 'Pinheiros').toJson(),
      });

      expect(job.location.neighborhood, 'Pinheiros');
    });
  });
}
