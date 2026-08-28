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
  Future<AuthSessionDto?>? _activeCredentialRefresh;
  Future<AuthSessionDto?>? _activeForegroundAuthentication;

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

  Future<AuthSessionDto?> getOrAuthenticateSession() {
    final currentSession = state;

    if (currentSession != null && currentSession.accessTokenExpiresAt.isAfter(clock.now())) {
      return Future<AuthSessionDto?>.value(currentSession);
    }

    return refreshSession();
  }

  Future<AuthSessionDto?> refreshSession() {
    final activeForegroundAuthentication = _activeForegroundAuthentication;
    if (activeForegroundAuthentication != null) return activeForegroundAuthentication;

    late final Future<AuthSessionDto?> foregroundAuthentication;

    foregroundAuthentication = _refreshThenAuthenticateInteractively().whenComplete(() {
      if (identical(_activeForegroundAuthentication, foregroundAuthentication)) {
        _activeForegroundAuthentication = null;
      }
    });

    _activeForegroundAuthentication = foregroundAuthentication;

    return foregroundAuthentication;
  }

  Future<void> refreshSessionInBackground() async {
    try {
      final activeForegroundAuthentication = _activeForegroundAuthentication;

      if (activeForegroundAuthentication != null) {
        await activeForegroundAuthentication;
        return;
      }

      await _refreshCredentials();
    } on Object {
      // Proactive refresh failures must not interrupt a completed authenticated request.
    }
  }

  Future<AuthSessionDto?> _refreshCredentials() {
    final activeCredentialRefresh = _activeCredentialRefresh;
    if (activeCredentialRefresh != null) return activeCredentialRefresh;

    late final Future<AuthSessionDto?> credentialRefresh;

    credentialRefresh = _performCredentialRefresh().whenComplete(() {
      if (identical(_activeCredentialRefresh, credentialRefresh)) {
        _activeCredentialRefresh = null;
      }
    });

    _activeCredentialRefresh = credentialRefresh;

    return credentialRefresh;
  }

  Future<AuthSessionDto?> _refreshThenAuthenticateInteractively() async {
    final session = await _refreshCredentials();
    if (session != null) return session;

    await _clearAuthenticationIfNeeded();

    final didLogin = await ref.read(loginSheetControllerProvider).show();
    if (!didLogin) return null;

    final authenticatedSession = state;

    if (authenticatedSession == null) {
      throw StateError('The login sheet completed successfully without setting an authenticated session.');
    }

    return authenticatedSession;
  }

  Future<AuthSessionDto?> _performCredentialRefresh() async {
    final appStorage = await ref.read(appStorageStateProvider.future);
    final credentials = appStorage.authCredentials;

    if (credentials == null || !credentials.refreshTokenExpiresAt.isAfter(clock.now())) return null;

    try {
      final refreshedSession = await ref
          .read(authRepositoryProvider)
          .refreshSession(refreshToken: credentials.refreshToken);
      final session = AuthSessionDto.fromIssuedAuthSession(refreshedSession.data);

      await setSession(session);

      return session;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;

      await _clearAuthentication();

      return null;
    }
  }

  Future<void> _clearAuthenticationIfNeeded() async {
    final storedCredentials = ref.read(appStorageStateProvider).requireValue.authCredentials;
    if (state == null && storedCredentials == null) return;

    await _clearAuthentication();
  }

  Future<void> _clearAuthentication() async {
    state = null;
    await ref.read(appStorageStateProvider.notifier).clearAuthCredentials();
  }
}
