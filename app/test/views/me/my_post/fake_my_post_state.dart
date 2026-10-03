import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeMyPostState extends MyPostState {
  FakeMyPostState(this.initialValue, {this.retryValue, this.onChangeStatus});

  final AsyncValue<UserJobDto> initialValue;
  final UserJobDto? retryValue;
  final Future<void> Function(JobStatus)? onChangeStatus;
  int retryCalls = 0;
  int changeStatusCalls = 0;

  void complete(UserJobDto detail) => state = AsyncData(MyPostData.fromDetail(detail));

  @override
  Future<MyPostData> build(String jobId) {
    state = initialValue.whenData(MyPostData.fromDetail);
    return Completer<MyPostData>().future;
  }

  @override
  Future<void> retry() async {
    retryCalls += 1;
    if (retryValue case final detail?) state = AsyncData(MyPostData.fromDetail(detail));
  }

  @override
  Future<void> changeStatus({required JobStatus status}) async {
    changeStatusCalls += 1;
    await onChangeStatus?.call(status);
    final data = state.requireValue;
    state = AsyncData(
      MyPostData(
        detail: data.detail.copyWith(status: status),
        contactLabel: data.contactLabel,
      ),
    );
  }
}
