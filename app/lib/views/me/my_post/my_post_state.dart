import 'package:cataqui_app/core/app_auth/authenticated_provider_retry.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_post_state.g.dart';

@Riverpod(retry: AuthenticatedProviderRetry.retry)
class MyPostState extends _$MyPostState {
  ({JobStatus status, DateTime updatedAt})? _latestStatus;

  @override
  Future<MyPostData> build(String jobId) => _fetch();

  Future<void> retry() async {
    state = const AsyncLoading<MyPostData>();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> changeStatus({required JobStatus status}) async {
    final repository = ref.read(jobRepositoryProvider);
    final response = switch (status) {
      JobStatus.active => await repository.activateJob(jobId: jobId),
      JobStatus.archived => await repository.archiveJob(jobId: jobId),
      JobStatus.unknown => throw UnsupportedError('Cannot set an unknown job status.'),
    };
    _latestStatus = (status: response.data.status, updatedAt: response.data.updatedAt);
    ref.read(myPostsStateProvider.notifier).updateJobStatus(jobId: jobId, status: response.data.status);
    final currentData = state.asData?.value;
    if (currentData != null) state = AsyncData(_applyLatestStatus(currentData));
  }

  MyPostData _applyLatestStatus(MyPostData data) {
    final latestStatus = _latestStatus;
    if (latestStatus == null) return data;
    return MyPostData(
      detail: data.detail.copyWith(status: latestStatus.status, updatedAt: latestStatus.updatedAt),
      contactLabel: data.contactLabel,
    );
  }

  Future<MyPostData> _fetch() async {
    final envelope = await ref.read(userRepositoryProvider).getMyPostedJob(jobId: jobId);
    return _applyLatestStatus(await MyPostData.prepare(envelope.data));
  }
}
