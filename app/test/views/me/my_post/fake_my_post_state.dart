import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeMyPostState extends MyPostState {
  FakeMyPostState(this.initialValue, {this.retryValue});

  final AsyncValue<UserJobDto> initialValue;
  final UserJobDto? retryValue;
  int retryCalls = 0;

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
}
