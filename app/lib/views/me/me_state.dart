import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_auth/authenticated_provider_retry.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'me_state.g.dart';

@Riverpod(keepAlive: true, retry: AuthenticatedProviderRetry.retry)
class MeState extends _$MeState {
  @override
  Future<UserProfileDto?> build() async {
    final userId = ref.watch(appAuthStateProvider.select((session) => session?.userId));
    if (userId == null) return null;

    final envelope = await ref.read(userRepositoryProvider).getMyProfile();
    return envelope.data;
  }
}
