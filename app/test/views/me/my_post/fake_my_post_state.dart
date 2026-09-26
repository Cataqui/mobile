import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeMyPostState extends MyPostState {
  FakeMyPostState(this.initialValue, {this.retryValue});

  final AsyncValue<UserJobDto> initialValue;
  final UserJobDto? retryValue;
  int retryCalls = 0;

  void complete(UserJobDto detail) => state = AsyncData(detail);

  @override
  Future<UserJobDto> build(String jobId) {
    state = initialValue;
    return Completer<UserJobDto>().future;
  }

  @override
  Future<void> retry() async {
    retryCalls += 1;
    if (retryValue case final detail?) state = AsyncData(detail);
  }
}
