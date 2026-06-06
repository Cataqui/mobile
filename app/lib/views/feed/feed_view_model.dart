import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_view_model.g.dart';

@riverpod
class FeedViewModel extends _$FeedViewModel {
  @override
  Future<FeedViewState> build() {
    return _getFirstFeedJobs();
  }

  Future<void> getFeedJobs({bool fetchNextPage = false}) async {
    if (fetchNextPage) {
      await _getNextFeedJobs();
      return;
    }

    state = const AsyncLoading<FeedViewState>();
    state = await AsyncValue.guard(_getFirstFeedJobs);
  }

  Future<FeedViewState> _getFirstFeedJobs() async {
    final feedRepository = ref.read(feedRepositoryProvider);
    final feedJobsEnvelope = await feedRepository.getFeedJobs();
    final pagination = feedJobsEnvelope.pagination;

    return FeedViewState(
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

    state = AsyncData<FeedViewState>(currentState.copyWith(isFetchingNextPage: true, paginationError: null));

    try {
      final feedRepository = ref.read(feedRepositoryProvider);
      final feedJobsEnvelope = await feedRepository.getFeedJobs(cursor: currentState.nextCursor);
      final pagination = feedJobsEnvelope.pagination;

      state = AsyncData<FeedViewState>(
        currentState.copyWith(
          jobs: <FeedJobDto>[...currentState.jobs, ...feedJobsEnvelope.data],
          hasMore: pagination?.hasMore ?? false,
          nextCursor: pagination?.nextCursor,
          isFetchingNextPage: false,
          paginationError: null,
        ),
      );
    } catch (error) {
      state = AsyncData<FeedViewState>(currentState.copyWith(isFetchingNextPage: false, paginationError: error));
    }
  }
}
