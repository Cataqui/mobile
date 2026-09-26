import 'package:cataqui_app/core/app_auth/authenticated_provider_retry.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_post_state.g.dart';

@Riverpod(retry: AuthenticatedProviderRetry.retry)
class MyPostState extends _$MyPostState {
  @override
  Future<MyPostData> build(String jobId) => _fetch();

  Future<void> retry() async {
    state = const AsyncLoading<MyPostData>();
    state = await AsyncValue.guard(_fetch);
  }

  Future<MyPostData> _fetch() async {
    final envelope = await ref.read(userRepositoryProvider).getMyPostedJob(jobId: jobId);
    return MyPostData.prepare(envelope.data);
  }
}
