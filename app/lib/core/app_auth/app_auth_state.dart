import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_auth_state.g.dart';

@Riverpod(keepAlive: true)
class AppAuthState extends _$AppAuthState {
  Future<AuthSessionDto?>? _activeRefresh;

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

  Future<AuthSessionDto?> refreshSession() {
    final activeRefresh = _activeRefresh;
    if (activeRefresh != null) return activeRefresh;

    late final Future<AuthSessionDto?> refresh;

    refresh = _refreshSession().whenComplete(() {
      if (identical(_activeRefresh, refresh)) _activeRefresh = null;
    });

    _activeRefresh = refresh;

    return refresh;
  }

  Future<AuthSessionDto?> _refreshSession() async {
    final appStorage = await ref.read(appStorageStateProvider.future);
    final credentials = appStorage.authCredentials;

    if (credentials == null || !credentials.refreshTokenExpiresAt.isAfter(clock.now())) {
      return _authenticateInteractively();
    }

    try {
      final refreshedSession = await ref
          .read(authRepositoryProvider)
          .refreshSession(refreshToken: credentials.refreshToken);
      final session = AuthSessionDto.fromIssuedAuthSession(refreshedSession.data);

      await setSession(session);

      return session;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;

      return _authenticateInteractively();
    }
  }

  Future<AuthSessionDto?> _authenticateInteractively() async {
    state = null;
    await ref.read(appStorageStateProvider.notifier).clearAuthCredentials();

    final didLogin = await ref.read(loginSheetControllerProvider).show();
    if (!didLogin) return null;

    final session = state;

    if (session == null) {
      throw StateError('The login sheet completed successfully without setting an authenticated session.');
    }

    return session;
  }
}
