import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockFeedRepository repository;

  setUp(() {
    repository = MockFeedRepository();
    _FeedStateTestHelpers.stubFeedJobs(repository: repository);
  });

  group('FeedState', () {
    test('when first loaded, it should expose feed jobs', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);

      final feedState = await container.read(feedStateProvider.future);

      expect(feedState.jobs.single.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when bootstrap starts the fetch before the view mounts, it should fetch only once', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository)..read(feedStateProvider);

      await pumpEventQueue();

      await container.read(feedStateProvider.future);

      verify(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).called(1);
    });

    test('when first loaded with no jobs, it should expose full-screen empty state', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        firstEnvelope: _FeedStateTestHelpers.feedEnvelope(jobs: <FeedJobDto>[]),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);

      final feedState = await container.read(feedStateProvider.future);

      expect(feedState.isEmpty, isTrue);
    });

    test('when first loaded, it should expose pagination cursor', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);

      final feedState = await container.read(feedStateProvider.future);

      expect(feedState.nextCursor, 'next-feed-cursor');
    });

    test('when fetching the next page, it should append jobs', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        secondEnvelope: _FeedStateTestHelpers.feedEnvelope(
          jobs: <FeedJobDto>[_FeedStateTestHelpers.feedJob(jobId: 'second-job')],
          hasMore: false,
        ),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.jobs.map((job) => job.jobId), <String>[
        'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
        'second-job',
      ]);
    });

    test('when fetching the next page, it should send the current cursor', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        secondEnvelope: _FeedStateTestHelpers.feedEnvelope(
          jobs: <FeedJobDto>[_FeedStateTestHelpers.feedJob(jobId: 'second-job')],
          hasMore: false,
        ),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      verify(() => repository.getFeedJobs(cursor: 'next-feed-cursor')).called(1);
    });

    test('when fetching the next page, it should publish only the completed pagination result', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        secondEnvelope: _FeedStateTestHelpers.feedEnvelope(
          jobs: <FeedJobDto>[_FeedStateTestHelpers.feedJob(jobId: 'second-job')],
          hasMore: false,
        ),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      var providerEmissions = 0;
      final subscription = container.listen(feedStateProvider, (previous, next) => providerEmissions += 1);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);
      subscription.close();

      expect(providerEmissions, 1);
    });

    test('when next-page fetch returns no jobs, it should expose pagination empty state', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        secondEnvelope: _FeedStateTestHelpers.feedEnvelope(jobs: <FeedJobDto>[], hasMore: false),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.isPaginationEmpty, isTrue);
    });

    test('when next-page fetch fails, it should keep existing jobs', () async {
      _FeedStateTestHelpers.stubFeedJobs(repository: repository, secondError: StateError('next page failed'));
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.jobs.single.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when next-page fetch fails, it should store pagination error', () async {
      _FeedStateTestHelpers.stubFeedJobs(repository: repository, secondError: StateError('next page failed'));
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.paginationError, isA<StateError>());
    });

    test('when initial fetch fails, it should expose provider-level AsyncError', () async {
      _FeedStateTestHelpers.stubFeedJobs(repository: repository, firstError: StateError('first page failed'));
      final container = _FeedStateTestHelpers.createContainer(repository: repository);

      await expectLater(container.read(feedStateProvider.future), throwsA(isA<StateError>()));
    });

    test('when no more pages exist, it should skip the repository call', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        firstEnvelope: _FeedStateTestHelpers.feedEnvelope(hasMore: false, nextCursor: null),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      verify(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).called(1);
    });

    test('injected jobs appear first with their response fields and stay first after refresh', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      final createdJob = PublicJobDto.fixture().copyWith(
        jobId: 'new-post',
        title: 'Novo trampo',
        descriptionSummary: 'Resumo novo',
        payment: 'Outro pagamento',
        createdAt: DateTime.utc(2026, 9, 23),
      );

      container.read(feedStateProvider.notifier).injectJob(createdJob);
      var feedData = container.read(feedStateProvider).value!;
      expect(feedData.jobs.map((job) => job.jobId), ['new-post', 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502']);
      expect(feedData.jobs.first.title, 'Novo trampo');
      expect(feedData.jobs.first.descriptionSummary, 'Resumo novo');
      expect(feedData.jobs.first.payment, 'Outro pagamento');
      expect(feedData.jobs.first.location.latitude, createdJob.location.latitude);

      await container.read(feedStateProvider.notifier).getFeedJobs();
      feedData = container.read(feedStateProvider).value!;
      expect(feedData.jobs.map((job) => job.jobId).first, 'new-post');

      container.read(feedStateProvider.notifier).injectJob(PublicJobDto.fixture().copyWith(jobId: 'another-job'));
      feedData = container.read(feedStateProvider).value!;
      expect(feedData.jobs.map((job) => job.jobId), [
        'another-job',
        'new-post',
        'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
      ]);
    });

    test('pagination does not duplicate an injected job returned by the feed', () async {
      _FeedStateTestHelpers.stubFeedJobs(
        repository: repository,
        secondEnvelope: _FeedStateTestHelpers.feedEnvelope(
          jobs: [_FeedStateTestHelpers.feedJob(jobId: 'new-post')],
          hasMore: false,
        ),
      );
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      container.read(feedStateProvider.notifier).injectJob(PublicJobDto.fixture().copyWith(jobId: 'new-post'));
      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value!.jobs.where((job) => job.jobId == 'new-post').length, 1);
    });

    test('a failed pending page keeps a newly published job in the feed', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      final pendingPage = Completer<ApiEnvelopeDto<List<FeedJobDto>>>();
      when(() => repository.getFeedJobs(cursor: 'next-feed-cursor')).thenAnswer((_) => pendingPage.future);
      final pageRequest = container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      container.read(feedStateProvider.notifier).injectJob(PublicJobDto.fixture().copyWith(jobId: 'new-post'));
      pendingPage.completeError(StateError('offline'));
      await pageRequest;

      expect(container.read(feedStateProvider).requireValue.jobs.first.jobId, 'new-post');
      expect(container.read(feedStateProvider).requireValue.paginationError, isA<StateError>());
    });

    test('a pending page cannot overwrite a refreshed feed', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      final pendingPage = Completer<ApiEnvelopeDto<List<FeedJobDto>>>();
      when(() => repository.getFeedJobs(cursor: 'next-feed-cursor')).thenAnswer((_) => pendingPage.future);
      final pageRequest = container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);
      when(() => repository.getFeedJobs()).thenAnswer(
        (_) async => _FeedStateTestHelpers.feedEnvelope(
          jobs: [_FeedStateTestHelpers.feedJob(jobId: 'refreshed-job')],
          hasMore: false,
          nextCursor: null,
        ),
      );

      await container.read(feedStateProvider.notifier).getFeedJobs();
      pendingPage.complete(
        _FeedStateTestHelpers.feedEnvelope(jobs: [_FeedStateTestHelpers.feedJob(jobId: 'stale-job')], hasMore: false),
      );
      await pageRequest;

      expect(container.read(feedStateProvider).requireValue.jobs.map((job) => job.jobId), ['refreshed-job']);
    });

    test('a pending page failure cannot replace a refreshed feed with stale jobs', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      final pendingPage = Completer<ApiEnvelopeDto<List<FeedJobDto>>>();
      when(() => repository.getFeedJobs(cursor: 'next-feed-cursor')).thenAnswer((_) => pendingPage.future);
      final pageRequest = container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);
      when(() => repository.getFeedJobs()).thenAnswer(
        (_) async => _FeedStateTestHelpers.feedEnvelope(
          jobs: [_FeedStateTestHelpers.feedJob(jobId: 'refreshed-job')],
          hasMore: false,
          nextCursor: null,
        ),
      );

      await container.read(feedStateProvider.notifier).getFeedJobs();
      pendingPage.completeError(StateError('stale page failed'));
      await pageRequest;

      expect(container.read(feedStateProvider).requireValue.jobs.map((job) => job.jobId), ['refreshed-job']);
      expect(container.read(feedStateProvider).requireValue.paginationError, isNull);
    });

    test('the injected job remains visible when a feed refresh fails', () async {
      final container = _FeedStateTestHelpers.createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      container.read(feedStateProvider.notifier).injectJob(PublicJobDto.fixture().copyWith(jobId: 'new-post'));
      when(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).thenThrow(StateError('offline'));

      await container.read(feedStateProvider.notifier).getFeedJobs();

      expect(container.read(feedStateProvider).value!.jobs.first.jobId, 'new-post');
    });
  });
}

abstract final class _FeedStateTestHelpers {
  static ProviderContainer createContainer({required MockFeedRepository repository}) {
    final container = ProviderContainer(overrides: [feedRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    return container;
  }

  static void stubFeedJobs({
    required MockFeedRepository repository,
    ApiEnvelopeDto<List<FeedJobDto>>? firstEnvelope,
    ApiEnvelopeDto<List<FeedJobDto>>? secondEnvelope,
    Error? firstError,
    Error? secondError,
  }) {
    var callCount = 0;

    when(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).thenAnswer((_) async {
      callCount += 1;

      if (callCount == 1 && firstError != null) {
        throw firstError;
      }

      if (callCount > 1 && secondError != null) {
        throw secondError;
      }

      if (callCount > 1 && secondEnvelope != null) {
        return secondEnvelope;
      }

      return firstEnvelope ?? feedEnvelope();
    });
  }

  static ApiEnvelopeDto<List<FeedJobDto>> feedEnvelope({
    List<FeedJobDto>? jobs,
    bool hasMore = true,
    String? nextCursor = 'next-feed-cursor',
  }) {
    return ApiEnvelopeDto<List<FeedJobDto>>(
      data: jobs ?? <FeedJobDto>[feedJob()],
      requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
      timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
      endpoint: '/v1/feed',
      pagination: ApiPaginationDto(hasMore: hasMore, nextCursor: nextCursor),
    );
  }

  static FeedJobDto feedJob({String jobId = 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502'}) {
    return FeedJobDto.fixture().copyWith(jobId: jobId);
  }
}
