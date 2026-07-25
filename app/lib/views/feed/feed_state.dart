import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_state.g.dart';

@Riverpod(keepAlive: true)
class FeedState extends _$FeedState {
  bool _isFetchingNextPage = false;

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

  Future<FeedData> _getFirstFeedJobs() async {
    final feedRepository = ref.read(feedRepositoryProvider);
    final feedJobsEnvelope = await feedRepository.getFeedJobs();
    final pagination = feedJobsEnvelope.pagination;

    return FeedData(
      jobs: feedJobsEnvelope.data,
      hasMore: pagination?.hasMore ?? false,
      nextCursor: pagination?.nextCursor,
    );
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
          jobs: <FeedJobDto>[...currentState.jobs, ...feedJobsEnvelope.data],
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
