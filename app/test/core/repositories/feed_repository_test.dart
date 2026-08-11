import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/feed_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

final _feedEnvelopeJson = <String, Object?>{
  'data': [FeedJobDto.fixture().toJson()],
  'requestId': '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/v1/feed',
  'pagination': ApiPaginationDto.fixture().toJson(),
};

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('FeedRepository', () {
    test('when requesting feed jobs, it should call the feed jobs endpoint', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(unauthenticatedDio: dio);

      await repository.getFeedJobs();

      verify(() => dio.get<Map<String, Object?>>('/feed', queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('when requesting the first feed page, it should omit removed query parameters', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(unauthenticatedDio: dio);

      await repository.getFeedJobs();

      verify(() => dio.get<Map<String, Object?>>(any(), queryParameters: <String, Object?>{})).called(1);
    });

    test('when requesting the first feed page, it should omit cursor', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(unauthenticatedDio: dio);

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
      final repository = FeedRepository(unauthenticatedDio: dio);

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
      final repository = FeedRepository(unauthenticatedDio: dio);

      final envelope = await repository.getFeedJobs();

      expect(envelope.data.single.jobId, FeedJobDto.fixture().jobId);
    });

    test('when receiving feed jobs, it should map pagination', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio);
      final repository = FeedRepository(unauthenticatedDio: dio);

      final envelope = await repository.getFeedJobs();

      expect(envelope.pagination?.nextCursor, ApiPaginationDto.fixture().nextCursor);
    });

    test('when receiving an empty feed, it should map an empty job list', () async {
      final dio = MockDio();
      _stubFeedJobsRequest(dio: dio, responseJson: <String, Object?>{..._feedEnvelopeJson, 'data': <Object?>[]});
      final repository = FeedRepository(unauthenticatedDio: dio);

      final envelope = await repository.getFeedJobs();

      expect(envelope.data, isEmpty);
    });
  });

  group('feedRepositoryProvider', () {
    test('when reading the provider, it should use the unauthenticated dio', () {
      final dio = MockDio();
      final container = ProviderContainer(overrides: [unauthenticatedCataquiApiV1DioProvider.overrideWithValue(dio)]);
      addTearDown(container.dispose);

      final repository = container.read(feedRepositoryProvider);

      expect(repository.unauthenticatedDio, same(dio));
    });
  });
}

void _stubFeedJobsRequest({required MockDio dio, Map<String, Object?>? responseJson}) {
  when(() => dio.get<Map<String, Object?>>(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
    (_) async => Response<Map<String, Object?>>(
      data: responseJson ?? _feedEnvelopeJson,
      requestOptions: RequestOptions(path: '/feed'),
    ),
  );
}
