import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedJobDto', () {
    test('when parsing a feed job, it should map the title', () {
      final job = FeedJobDto.fixture().copyWith(title: 'Descarregar Caminhão');

      expect(job.title, 'Descarregar Caminhão');
    });

    test('when parsing a feed job, it should map the location', () {
      final job = FeedJobDto.fixture().copyWith(
        location: FeedJobLocationDto.fixture().copyWith(neighborhood: 'Pinheiros'),
      );

      expect(job.location.neighborhood, 'Pinheiros');
    });
  });

  group('formatCreatedAtAgo', () {
    test('when the difference is under 60 seconds, it should return agora', () {
      final createdAt = DateTime(2025, 6, 15, 12, 0, 0);
      final now = createdAt.add(const Duration(seconds: 30));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.now);
    });

    test('when the difference is 20 minutes, it should return 20min atrás', () {
      final createdAt = DateTime(2025, 6, 15, 12, 0, 0);
      final now = createdAt.add(const Duration(minutes: 20));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.minutes(count: 20));
    });

    test('when the difference is 20 hours, it should return 20h atrás', () {
      final createdAt = DateTime(2025, 6, 15, 0, 0, 0);
      final now = createdAt.add(const Duration(hours: 20));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.hours(count: 20));
    });

    test('when the difference is exactly 1 day, it should return 1 dia atrás', () {
      final createdAt = DateTime(2025, 6, 15);
      final now = createdAt.add(const Duration(days: 1));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.days(count: 1));
    });

    test('when the difference is 5 days, it should return 5 dias atrás', () {
      final createdAt = DateTime(2025, 6, 15);
      final now = createdAt.add(const Duration(days: 5));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.days(count: 5));
    });

    test('when the difference is 14 days, it should return 14 dias atrás', () {
      final createdAt = DateTime(2025, 6, 15);
      final now = createdAt.add(const Duration(days: 14));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.days(count: 14));
    });

    test('when the difference is exactly 30 days, it should return 1 mês atrás', () {
      final createdAt = DateTime(2025, 6, 15);
      final now = createdAt.add(const Duration(days: 30));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.months(count: 1));
    });

    test('when the difference is 90 days, it should return 3 meses atrás', () {
      final createdAt = DateTime(2025, 6, 15);
      final now = createdAt.add(const Duration(days: 90));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.months(count: 3));
    });

    test('when createdAt is in the future, it should return agora', () {
      final createdAt = DateTime(2025, 6, 15, 12, 0, 0);
      final now = createdAt.subtract(const Duration(minutes: 5));
      final job = FeedJobDto.fixture().copyWith(createdAt: createdAt);

      expect(job.formatCreatedAtAgo(i18n, now: now), i18n.feedJob.timeAgo.now);
    });
  });
}
