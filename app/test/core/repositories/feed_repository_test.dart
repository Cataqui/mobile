import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../dtos/dto_json_fixtures.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('FeedRepository', () {
    test('when requesting feed jobs, it should call the feed jobs endpoint', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(dio: dio);

      await repository.getFeedJobs();

      verify(
        () => dio.get<Map<String, Object?>>('/feed/jobs', queryParameters: any(named: 'queryParameters')),
      ).called(1);
    });

    test('when requesting feed jobs, it should send the latest sort mode', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(dio: dio);

      await repository.getFeedJobs();

      verify(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters', that: containsPair('sort', 'LATEST')),
        ),
      ).called(1);
    });

    test('when requesting the first feed page, it should omit cursor', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(dio: dio);

      await repository.getFeedJobs();

      verify(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters', that: isNot(containsPair('cursor', anything))),
        ),
      ).called(1);
    });

    test('when requesting the next feed page, it should send cursor', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(dio: dio);

      await repository.getFeedJobs(cursor: 'next-feed-cursor');

      verify(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters', that: containsPair('cursor', 'next-feed-cursor')),
        ),
      ).called(1);
    });

    test('when receiving feed jobs, it should map feed job dto data', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(dio: dio);

      final envelope = await repository.getFeedJobs();

      expect(envelope.data.single.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when receiving feed jobs, it should map pagination', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(dio: dio);

      final envelope = await repository.getFeedJobs();

      expect(envelope.pagination?.nextCursor, 'next-feed-cursor');
    });

    test('when receiving an empty feed, it should map an empty job list', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio, responseJson: <String, Object?>{...feedEnvelopeJson, 'data': <Object?>[]});
      final repository = FeedRepository(dio: dio);

      final envelope = await repository.getFeedJobs();

      expect(envelope.data, isEmpty);
    });
  });

  group('feedRepositoryProvider', () {
    test('when reading the provider, it should expose a feed repository', () {
      final container = ProviderContainer(overrides: [cataquiDioProvider.overrideWithValue(MockDio())]);
      addTearDown(container.dispose);

      final repository = container.read(feedRepositoryProvider);

      expect(repository, isA<FeedRepository>());
    });
  });
}

void _stubFeedJobsRequest({required MockDio dio, Map<String, Object?> responseJson = feedEnvelopeJson}) {
  when(() => dio.get<Map<String, Object?>>(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
    (_) async => Response<Map<String, Object?>>(
      data: responseJson,
      requestOptions: RequestOptions(path: '/feed/jobs'),
    ),
  );
}
