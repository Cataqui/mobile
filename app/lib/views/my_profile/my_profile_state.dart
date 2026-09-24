import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_profile_state.g.dart';

@Riverpod(keepAlive: true, retry: MyProfileState._retry)
class MyProfileState extends _$MyProfileState {
  static Duration? _retry(int retryCount, Object error) {
    if (error is AuthenticationDismissedDioException) return null;
    if (error is DioException && error.response?.statusCode == 401) return null;
    return ProviderContainer.defaultRetry(retryCount, error);
  }

  @override
  Future<UserProfileDto?> build() async {
    final userId = ref.watch(appAuthStateProvider.select((session) => session?.userId));
    if (userId == null) return null;

    final envelope = await ref.read(userRepositoryProvider).getMyProfile();
    return envelope.data;
  }
}
