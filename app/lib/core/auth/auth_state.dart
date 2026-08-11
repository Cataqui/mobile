import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state.g.dart';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  AuthSessionDto? build() => null;

  // setSession is an authentication command rather than a property-style setter.
  // ignore: use_setters_to_change_properties
  Future<void> setSession(AuthSessionDto session) async {
    state = session;

    try {
      await ref
          .read(appStorageStateProvider.notifier)
          .saveAuthCredentials(credentials: AuthCredentialsDto.fromAuthSession(session));
    } on Object {
      // The active in-memory session remains usable when secure persistence is unavailable.
    }
  }
}
