import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_state.g.dart';

@riverpod
class FeedState extends _$FeedState {
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

    if (currentState == null || currentState.isFetchingNextPage || !currentState.hasMore) {
      return;
    }

    state = AsyncData<FeedData>(currentState.copyWith(isFetchingNextPage: true, paginationError: null));

    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      final feedJobsEnvelope = await feedRepository.getFeedJobs(cursor: currentState.nextCursor);
      final pagination = feedJobsEnvelope.pagination;

      state = AsyncData<FeedData>(
        currentState.copyWith(
          jobs: <FeedJobDto>[...currentState.jobs, ...feedJobsEnvelope.data],
          hasMore: pagination?.hasMore ?? false,
          nextCursor: pagination?.nextCursor,
          isFetchingNextPage: false,
          paginationError: null,
        ),
      );
    } catch (error) {
      state = AsyncData<FeedData>(currentState.copyWith(isFetchingNextPage: false, paginationError: error));
    }
  }
}
