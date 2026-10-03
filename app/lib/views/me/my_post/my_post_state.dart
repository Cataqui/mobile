import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_auth/authenticated_provider_retry.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_post_state.g.dart';

@Riverpod(retry: AuthenticatedProviderRetry.retry)
class MyPostState extends _$MyPostState {
  ({JobStatus status, DateTime updatedAt})? _latestStatus;

  @override
  Future<MyPostData> build(String jobId) {
    ref.watch(appAuthStateProvider.select((session) => session?.userId));
    _latestStatus = null;
    return _fetch();
  }

  Future<void> retry() async {
    final userId = ref.read(appAuthStateProvider)?.userId;
    state = const AsyncLoading<MyPostData>();
    final result = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
    if (userId != ref.read(appAuthStateProvider)?.userId) return;
    state = result;
  }

  Future<void> changeStatus({required JobStatus status}) async {
    final userId = ref.read(appAuthStateProvider)?.userId;
    final keepAliveLink = ref.keepAlive();
    try {
      final repository = ref.read(jobRepositoryProvider);
      final response = switch (status) {
        .active => await repository.activateJob(jobId: jobId),
        .archived => await repository.archiveJob(jobId: jobId),
        .unknown => throw UnsupportedError('Cannot set an unknown job status.'),
      };
      if (!ref.mounted) return;
      if (userId != ref.read(appAuthStateProvider)?.userId) return;
      _latestStatus = (status: response.data.status, updatedAt: response.data.updatedAt);
      ref.read(myPostsStateProvider.notifier).updateJobStatus(jobId: jobId, status: response.data.status);
      unawaited(ref.read(feedStateProvider.notifier).refreshAfterJobStatusChange(jobId: jobId));
      final currentData = state.asData?.value;
      if (currentData != null) state = AsyncData(_applyLatestStatus(currentData));
    } finally {
      keepAliveLink.close();
    }
  }

  MyPostData _applyLatestStatus(MyPostData data) {
    final latestStatus = _latestStatus;
    if (latestStatus == null) return data;
    if (data.detail.updatedAt.isAfter(latestStatus.updatedAt)) return data;
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
