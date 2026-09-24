import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_state.g.dart';

@Riverpod(keepAlive: true)
class FeedState extends _$FeedState {
  bool _isFetchingNextPage = false;
  final List<FeedJobDto> _injectedJobs = [];

  @override
  Future<FeedData> build() {
    return _getFirstFeedJobs();
  }

  Future<void> getFeedJobs({bool fetchNextPage = false}) async {
    if (fetchNextPage) {
      await _getNextFeedJobs();
      return;
    }

    state = const AsyncLoading<FeedData>();
    state = await AsyncValue.guard(_getFirstFeedJobs);
  }

  void injectJob(JobDto job) {
    final injectedJob = FeedJobDto.fromJob(job);
    _injectedJobs
      ..removeWhere((existingJob) => existingJob.jobId == injectedJob.jobId)
      ..insert(0, injectedJob);

    final currentData = state.value;
    state = AsyncData<FeedData>(
      currentData == null
          ? FeedData(jobs: [injectedJob], hasMore: false)
          : currentData.copyWith(jobs: _withInjectedJobs(currentData.jobs)),
    );
  }

  List<FeedJobDto> _withInjectedJobs(List<FeedJobDto> jobs) {
    final injectedIds = _injectedJobs.map((job) => job.jobId).toSet();
    return [..._injectedJobs, ...jobs.where((job) => !injectedIds.contains(job.jobId))];
  }

  Future<FeedData> _getFirstFeedJobs() async {
    final feedRepository = ref.read(feedRepositoryProvider);
    try {
      final feedJobsEnvelope = await feedRepository.getFeedJobs();
      final pagination = feedJobsEnvelope.pagination;

      return FeedData(
        jobs: _withInjectedJobs(feedJobsEnvelope.data),
        hasMore: pagination?.hasMore ?? false,
        nextCursor: pagination?.nextCursor,
      );
    } catch (_) {
      if (_injectedJobs.isEmpty) rethrow;
      return FeedData(jobs: [..._injectedJobs], hasMore: false);
    }
  }

  Future<void> _getNextFeedJobs() async {
    final currentState = state.value;

    if (currentState == null || _isFetchingNextPage || !currentState.hasMore) {
      return;
    }

    _isFetchingNextPage = true;

    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      final feedJobsEnvelope = await feedRepository.getFeedJobs(cursor: currentState.nextCursor);
      final pagination = feedJobsEnvelope.pagination;

      state = AsyncData<FeedData>(
        currentState.copyWith(
          jobs: _withInjectedJobs([...currentState.jobs, ...feedJobsEnvelope.data]),
          hasMore: pagination?.hasMore ?? false,
          nextCursor: pagination?.nextCursor,
          paginationError: null,
        ),
      );
    } catch (error) {
      state = AsyncData<FeedData>(currentState.copyWith(paginationError: error));
    } finally {
      _isFetchingNextPage = false;
    }
  }
}
