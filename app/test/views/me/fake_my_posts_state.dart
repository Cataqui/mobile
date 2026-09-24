import 'dart:async';

import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeMyPostsState extends MyPostsState {
  FakeMyPostsState(this.initialValue);

  final AsyncValue<MyPostsData?> initialValue;
  int loadNextPageCalls = 0;

  @override
  Future<MyPostsData?> build() {
    state = initialValue;
    return Completer<MyPostsData?>().future;
  }

  void showData(MyPostsData data) => state = AsyncData(data);

  @override
  Future<void> loadNextPage() async {
    loadNextPageCalls += 1;
    final data = state.value;
    if (data == null) return;
    state = AsyncData(data.copyWith(isLoadingMore: true));
  }
}
