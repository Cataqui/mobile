import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
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
          .setAuthCredentials(credentials: AuthCredentialsDto.fromAuthSession(session));
    } on Object {
      // The active in-memory session remains usable when secure persistence is unavailable.
    }
  }

  Future<void> refreshSession() async {
    final appStorage = await ref.read(appStorageStateProvider.future);
    final credentials = appStorage.authCredentials;

    if (credentials == null || !credentials.refreshTokenExpiresAt.isAfter(clock.now())) return;

    final refreshedSession = await ref
        .read(authRepositoryProvider)
        .refreshSession(refreshToken: credentials.refreshToken);

    await setSession(AuthSessionDto.fromIssuedAuthSession(refreshedSession.data));
  }
}
