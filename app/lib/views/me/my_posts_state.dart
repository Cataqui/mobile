import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_auth/authenticated_provider_retry.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_posts_state.g.dart';

@Riverpod(retry: AuthenticatedProviderRetry.retry)
class MyPostsState extends _$MyPostsState {
  @override
  Future<MyPostsData?> build() async {
    final userId = ref.watch(appAuthStateProvider.select((session) => session?.userId));
    if (userId == null) return null;

    final envelope = await ref.read(userRepositoryProvider).getMyPostedJobs();
    return MyPostsData(
      userId: userId,
      jobs: envelope.data,
      hasMore: envelope.pagination?.hasMore ?? false,
      nextCursor: envelope.pagination?.nextCursor,
    );
  }

  Future<void> loadNextPage() async {
    final currentData = state.value;
    if (currentData == null || !currentData.hasMore || currentData.isLoadingMore) return;
    if (currentData.userId != ref.read(appAuthStateProvider)?.userId) return;

    state = AsyncData(currentData.copyWith(isLoadingMore: true, paginationError: null));

    try {
      final envelope = await ref.read(userRepositoryProvider).getMyPostedJobs(cursor: currentData.nextCursor);
      if (currentData.userId != ref.read(appAuthStateProvider)?.userId) return;
      final latestData = state.value ?? currentData;
      state = AsyncData(
        latestData.copyWith(
          jobs: [...latestData.jobs, ...envelope.data],
          hasMore: envelope.pagination?.hasMore ?? false,
          nextCursor: envelope.pagination?.nextCursor,
          isLoadingMore: false,
          paginationError: null,
        ),
      );
    } catch (error) {
      if (currentData.userId != ref.read(appAuthStateProvider)?.userId) return;
      state = AsyncData((state.value ?? currentData).copyWith(isLoadingMore: false, paginationError: error));
    }
  }

  void updateJobStatus({required String jobId, required JobStatus status}) {
    final currentData = state.value;
    if (currentData == null || currentData.userId != ref.read(appAuthStateProvider)?.userId) return;

    state = AsyncData(
      currentData.copyWith(
        jobs: [
          for (final job in currentData.jobs)
            if (job.jobId == jobId) job.copyWith(status: status) else job,
        ],
      ),
    );
  }
}
