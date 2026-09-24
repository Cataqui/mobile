import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  group('FeedState', () {
    test('when first loaded, it should expose feed jobs', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository);
      final container = _createContainer(repository: repository);

      final feedState = await container.read(feedStateProvider.future);

      expect(feedState.jobs.single.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when bootstrap starts the fetch before the view mounts, it should fetch only once', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository);
      final container = _createContainer(repository: repository)..read(feedStateProvider);

      await pumpEventQueue();

      await container.read(feedStateProvider.future);

      verify(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).called(1);
    });

    test('when first loaded with no jobs, it should expose full-screen empty state', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(
        repository: repository,
        firstEnvelope: _feedEnvelope(jobs: <FeedJobDto>[]),
      );
      final container = _createContainer(repository: repository);

      final feedState = await container.read(feedStateProvider.future);

      expect(feedState.isEmpty, isTrue);
    });

    test('when first loaded, it should expose pagination cursor', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository);
      final container = _createContainer(repository: repository);

      final feedState = await container.read(feedStateProvider.future);

      expect(feedState.nextCursor, 'next-feed-cursor');
    });

    test('when fetching the next page, it should append jobs', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(
        repository: repository,
        secondEnvelope: _feedEnvelope(jobs: <FeedJobDto>[_feedJob(jobId: 'second-job')], hasMore: false),
      );
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.jobs.map((job) => job.jobId), <String>[
        'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
        'second-job',
      ]);
    });

    test('when fetching the next page, it should send the current cursor', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(
        repository: repository,
        secondEnvelope: _feedEnvelope(jobs: <FeedJobDto>[_feedJob(jobId: 'second-job')], hasMore: false),
      );
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      verify(() => repository.getFeedJobs(cursor: 'next-feed-cursor')).called(1);
    });

    test('when fetching the next page, it should publish only the completed pagination result', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(
        repository: repository,
        secondEnvelope: _feedEnvelope(jobs: <FeedJobDto>[_feedJob(jobId: 'second-job')], hasMore: false),
      );
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      var providerEmissions = 0;
      final subscription = container.listen(feedStateProvider, (previous, next) => providerEmissions += 1);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);
      subscription.close();

      expect(providerEmissions, 1);
    });

    test('when next-page fetch returns no jobs, it should expose pagination empty state', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(
        repository: repository,
        secondEnvelope: _feedEnvelope(jobs: <FeedJobDto>[], hasMore: false),
      );
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.isPaginationEmpty, isTrue);
    });

    test('when next-page fetch fails, it should keep existing jobs', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository, secondError: StateError('next page failed'));
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.jobs.single.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when next-page fetch fails, it should store pagination error', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository, secondError: StateError('next page failed'));
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value?.paginationError, isA<StateError>());
    });

    test('when initial fetch fails, it should expose provider-level AsyncError', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository, firstError: StateError('first page failed'));
      final container = _createContainer(repository: repository);

      await expectLater(container.read(feedStateProvider.future), throwsA(isA<StateError>()));
    });

    test('when no more pages exist, it should skip the repository call', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository, firstEnvelope: _feedEnvelope(hasMore: false, nextCursor: null));
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      verify(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).called(1);
    });

    test('injected jobs appear first with their response fields and stay first after refresh', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository);
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      final createdJob = JobDto.fixture().copyWith(
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

      container.read(feedStateProvider.notifier).injectJob(JobDto.fixture().copyWith(jobId: 'another-job'));
      feedData = container.read(feedStateProvider).value!;
      expect(feedData.jobs.map((job) => job.jobId), [
        'another-job',
        'new-post',
        'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
      ]);
    });

    test('pagination does not duplicate an injected job returned by the feed', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(
        repository: repository,
        secondEnvelope: _feedEnvelope(jobs: [_feedJob(jobId: 'new-post')], hasMore: false),
      );
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);

      container.read(feedStateProvider.notifier).injectJob(JobDto.fixture().copyWith(jobId: 'new-post'));
      await container.read(feedStateProvider.notifier).getFeedJobs(fetchNextPage: true);

      expect(container.read(feedStateProvider).value!.jobs.where((job) => job.jobId == 'new-post').length, 1);
    });

    test('the injected job remains visible when a feed refresh fails', () async {
      final repository = MockFeedRepository();
      _stubFeedJobs(repository: repository);
      final container = _createContainer(repository: repository);
      await container.read(feedStateProvider.future);
      container.read(feedStateProvider.notifier).injectJob(JobDto.fixture().copyWith(jobId: 'new-post'));
      when(() => repository.getFeedJobs(cursor: any(named: 'cursor'))).thenThrow(StateError('offline'));

      await container.read(feedStateProvider.notifier).getFeedJobs();

      expect(container.read(feedStateProvider).value!.jobs.first.jobId, 'new-post');
    });
  });
}

ProviderContainer _createContainer({required MockFeedRepository repository}) {
  final container = ProviderContainer(overrides: [feedRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  return container;
}

void _stubFeedJobs({
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

    return firstEnvelope ?? _feedEnvelope();
  });
}

ApiEnvelopeDto<List<FeedJobDto>> _feedEnvelope({
  List<FeedJobDto>? jobs,
  bool hasMore = true,
  String? nextCursor = 'next-feed-cursor',
}) {
  return ApiEnvelopeDto<List<FeedJobDto>>(
    data: jobs ?? <FeedJobDto>[_feedJob()],
    requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
    timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
    endpoint: '/v1/feed',
    pagination: ApiPaginationDto(hasMore: hasMore, nextCursor: nextCursor),
  );
}

FeedJobDto _feedJob({String jobId = 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502'}) {
  return FeedJobDto.fixture().copyWith(jobId: jobId);
}
