import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockFlutterSecureStorage secureStorage;
  late MockLoginSheetController loginSheetController;
  late MockSharedPreferencesAsync sharedPreferences;
  late ProviderContainer container;

  setUp(() async {
    authRepository = MockAuthRepository();
    secureStorage = MockFlutterSecureStorage();
    loginSheetController = MockLoginSheetController();
    sharedPreferences = MockSharedPreferencesAsync();
    when(() => sharedPreferences.getBool(any())).thenAnswer((_) async => null);
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(loginSheetController.show).thenAnswer((_) async => false);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        loginSheetControllerProvider.overrideWithValue(loginSheetController),
        secureStorageProvider.overrideWithValue(secureStorage),
        sharedPreferencesAsyncProvider.overrideWithValue(sharedPreferences),
      ],
    );
    await container.read(appStorageStateProvider.future);
  });

  tearDown(() => container.dispose());

  group('AppAuthState', () {
    test('when first read, it should expose an unauthenticated session', () {
      final session = container.read(appAuthStateProvider);

      expect(session, isNull);
    });

    test('when setting an authenticated session, it should expose the complete session', () async {
      final session = AuthSessionDto.fixture();

      await container.read(appAuthStateProvider.notifier).setSession(session);

      expect(container.read(appAuthStateProvider), session);
    });

    test('when the auth state has no active listeners, it should retain the authenticated session', () async {
      final subscription = container.listen(appAuthStateProvider, (_, __) {}, fireImmediately: true);
      final session = AuthSessionDto.fixture();
      await container.read(appAuthStateProvider.notifier).setSession(session);

      subscription.close();
      await container.pump();

      expect(container.read(appAuthStateProvider), session);
    });

    test('when secure persistence fails, it should keep the authenticated session in memory', () async {
      final session = AuthSessionDto.fixture();
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(StateError('secure storage unavailable'));

      await container.read(appAuthStateProvider.notifier).setSession(session);

      expect(container.read(appAuthStateProvider), session);
    });

    test(
      'when the current session is valid, getting an authenticated session should return it without refreshing',
      () async {
        final currentTime = DateTime.utc(2026, 8, 10, 15);
        final currentSession = AuthSessionDto.fixture().copyWith(
          accessTokenExpiresAt: currentTime.add(const Duration(minutes: 10)),
        );
        await container.read(appAuthStateProvider.notifier).setSession(currentSession);
        var refreshRequestCount = 0;
        var loginRequestCount = 0;
        when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {
          refreshRequestCount += 1;
          return ApiEnvelopeDto.fixture(
            data: NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto,
          );
        });
        when(loginSheetController.show).thenAnswer((_) async {
          loginRequestCount += 1;
          return false;
        });

        final result = await withClock(
          Clock.fixed(currentTime),
          () => container.read(appAuthStateProvider.notifier).getOrAuthenticateSession(),
        );

        expect(
          (result: result, refreshRequestCount: refreshRequestCount, loginRequestCount: loginRequestCount),
          (result: currentSession, refreshRequestCount: 0, loginRequestCount: 0),
        );
      },
    );

    test('when valid credentials are saved, getting an authenticated session should restore and persist it', () async {
      final storedCredentials = AuthCredentialsDto.fixture().copyWith(
        refreshToken: 'saved-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15, 15),
      );
      await container.read(appStorageStateProvider.notifier).setAuthCredentials(credentials: storedCredentials);
      final issuedSession = IssuedAuthSessionDto(
        accessToken: 'refreshed-access-token-12345678901234567890',
        tokenType: 'Bearer',
        expiresAt: DateTime.utc(2026, 8, 11, 15, 15),
        refreshToken: 'rotated-refresh-token',
        refreshExpiresAt: DateTime.utc(2026, 9, 10, 15, 15),
        userId: '4963fef0-b62a-4760-9f99-675fdc42a896',
      );
      String? requestedRefreshToken;
      when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((
        invocation,
      ) async {
        requestedRefreshToken = invocation.namedArguments[#refreshToken]! as String;
        return ApiEnvelopeDto.fixture(data: issuedSession);
      });

      final result = await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () {
        return container.read(appAuthStateProvider.notifier).getOrAuthenticateSession();
      });
      final expectedSession = AuthSessionDto.fromIssuedAuthSession(issuedSession);

      expect(
        (
          requestedRefreshToken: requestedRefreshToken,
          result: result,
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
        ),
        (
          requestedRefreshToken: 'saved-refresh-token',
          result: expectedSession,
          session: expectedSession,
          credentials: AuthCredentialsDto.fromAuthSession(expectedSession),
        ),
      );
    });

    test('when no credentials are saved, refreshing should request login and return null when dismissed', () async {
      final currentSession = AuthSessionDto.fixture();
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(StateError('secure storage unavailable'));
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      var refreshRequestCount = 0;
      var loginRequestCount = 0;
      when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {
        refreshRequestCount += 1;
        return ApiEnvelopeDto.fixture(data: NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto);
      });
      when(loginSheetController.show).thenAnswer((_) async {
        loginRequestCount += 1;
        return false;
      });

      final result = await container.read(appAuthStateProvider.notifier).refreshSession();

      expect(
        (
          result: result,
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
          refreshRequestCount: refreshRequestCount,
          loginRequestCount: loginRequestCount,
        ),
        (result: null, session: null, credentials: null, refreshRequestCount: 0, loginRequestCount: 1),
      );
    });

    test('when saved credentials expire at the current time, refreshing should clear them and request login', () async {
      final currentTime = DateTime.utc(2026, 8, 11, 15);
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'expired-refresh-token',
        refreshTokenExpiresAt: currentTime,
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      var refreshRequestCount = 0;
      var loginRequestCount = 0;
      when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {
        refreshRequestCount += 1;
        return ApiEnvelopeDto.fixture(data: NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto);
      });
      when(loginSheetController.show).thenAnswer((_) async {
        loginRequestCount += 1;
        return false;
      });

      final result = await withClock(Clock.fixed(currentTime), () {
        return container.read(appAuthStateProvider.notifier).refreshSession();
      });

      expect(
        (
          result: result,
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
          refreshRequestCount: refreshRequestCount,
          loginRequestCount: loginRequestCount,
        ),
        (result: null, session: null, credentials: null, refreshRequestCount: 0, loginRequestCount: 1),
      );
    });

    test('when refresh is rejected as unauthorized, it should clear authentication and request login', () async {
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'rejected-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      final unauthorizedError = DioException(
        requestOptions: RequestOptions(path: '/auth/sessions/refresh'),
        response: Response<void>(requestOptions: RequestOptions(path: '/auth/sessions/refresh'), statusCode: 401),
      );
      var loginRequestCount = 0;
      when(() => authRepository.refreshSession(refreshToken: 'rejected-refresh-token')).thenThrow(unauthorizedError);
      when(loginSheetController.show).thenAnswer((_) async {
        loginRequestCount += 1;
        return false;
      });

      final result = await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () {
        return container.read(appAuthStateProvider.notifier).refreshSession();
      });

      expect(
        (
          result: result,
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
          loginRequestCount: loginRequestCount,
        ),
        (result: null, session: null, credentials: null, loginRequestCount: 1),
      );
    });

    test('when login succeeds after credentials are unusable, refreshing should return the new session', () async {
      final authenticatedSession = AuthSessionDto.fixture().copyWith(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
      );
      when(loginSheetController.show).thenAnswer((_) async {
        await container.read(appAuthStateProvider.notifier).setSession(authenticatedSession);
        return true;
      });

      final result = await container.read(appAuthStateProvider.notifier).refreshSession();

      expect(
        (
          result: result,
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
        ),
        (
          result: authenticatedSession,
          session: authenticatedSession,
          credentials: AuthCredentialsDto.fromAuthSession(authenticatedSession),
        ),
      );
    });

    test('when refresh is forbidden, it should rethrow the error without requesting login', () async {
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'saved-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      final forbiddenError = DioException(
        requestOptions: RequestOptions(path: '/auth/sessions/refresh'),
        response: Response<void>(requestOptions: RequestOptions(path: '/auth/sessions/refresh'), statusCode: 403),
      );
      when(() => authRepository.refreshSession(refreshToken: 'saved-refresh-token')).thenThrow(forbiddenError);
      var loginRequestCount = 0;
      when(loginSheetController.show).thenAnswer((_) async {
        loginRequestCount += 1;
        return false;
      });
      Object? thrownError;

      try {
        await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () {
          return container.read(appAuthStateProvider.notifier).refreshSession();
        });
      } catch (error) {
        thrownError = error;
      }

      expect(
        (
          error: thrownError,
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
          loginRequestCount: loginRequestCount,
        ),
        (
          error: forbiddenError,
          session: currentSession,
          credentials: AuthCredentialsDto.fromAuthSession(currentSession),
          loginRequestCount: 0,
        ),
      );
    });

    test('when refresh fails outside authentication, it should rethrow and preserve the current session', () async {
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'saved-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      final refreshError = StateError('refresh failed');
      when(() => authRepository.refreshSession(refreshToken: 'saved-refresh-token')).thenThrow(refreshError);
      Object? thrownError;

      try {
        await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () {
          return container.read(appAuthStateProvider.notifier).refreshSession();
        });
      } catch (error) {
        thrownError = error;
      }

      expect(
        (error: thrownError, session: container.read(appAuthStateProvider)),
        (error: refreshError, session: currentSession),
      );
    });

    test(
      'when background refresh has no credentials, it should preserve the session without requesting login',
      () async {
        final currentSession = AuthSessionDto.fixture().copyWith(accessToken: 'still-valid-access-token');
        await container.read(appAuthStateProvider.notifier).setSession(currentSession);
        await container.read(appStorageStateProvider.notifier).clearAuthCredentials();
        var refreshRequestCount = 0;
        var loginRequestCount = 0;
        when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {
          refreshRequestCount += 1;
          return ApiEnvelopeDto.fixture(
            data: NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto,
          );
        });
        when(loginSheetController.show).thenAnswer((_) async {
          loginRequestCount += 1;
          return false;
        });

        await container.read(appAuthStateProvider.notifier).refreshSessionInBackground();

        expect(
          (
            session: container.read(appAuthStateProvider),
            refreshRequestCount: refreshRequestCount,
            loginRequestCount: loginRequestCount,
          ),
          (session: currentSession, refreshRequestCount: 0, loginRequestCount: 0),
        );
      },
    );

    test('when background refresh is unauthorized, it should clear authentication without requesting login', () async {
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'rejected-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      final unauthorizedError = DioException(
        requestOptions: RequestOptions(path: '/auth/sessions/refresh'),
        response: Response<void>(requestOptions: RequestOptions(path: '/auth/sessions/refresh'), statusCode: 401),
      );
      var loginRequestCount = 0;
      when(() => authRepository.refreshSession(refreshToken: 'rejected-refresh-token')).thenThrow(unauthorizedError);
      when(loginSheetController.show).thenAnswer((_) async {
        loginRequestCount += 1;
        return false;
      });

      await withClock(
        Clock.fixed(DateTime.utc(2026, 8, 11, 15)),
        () => container.read(appAuthStateProvider.notifier).refreshSessionInBackground(),
      );

      expect(
        (
          session: container.read(appAuthStateProvider),
          credentials: container.read(appStorageStateProvider).value!.authCredentials,
          loginRequestCount: loginRequestCount,
        ),
        (session: null, credentials: null, loginRequestCount: 0),
      );
    });

    test('when background refresh fails outside authentication, it should preserve the current session', () async {
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'saved-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      when(
        () => authRepository.refreshSession(refreshToken: 'saved-refresh-token'),
      ).thenThrow(StateError('refresh unavailable'));
      var loginRequestCount = 0;
      when(loginSheetController.show).thenAnswer((_) async {
        loginRequestCount += 1;
        return false;
      });

      await withClock(
        Clock.fixed(DateTime.utc(2026, 8, 11, 15)),
        () => container.read(appAuthStateProvider.notifier).refreshSessionInBackground(),
      );

      expect(
        (session: container.read(appAuthStateProvider), loginRequestCount: loginRequestCount),
        (session: currentSession, loginRequestCount: 0),
      );
    });

    test(
      'when foreground login is active, background refresh should wait for the same authentication result',
      () async {
        final loginResult = Completer<bool>();
        var loginRequestCount = 0;
        when(loginSheetController.show).thenAnswer((_) {
          loginRequestCount += 1;
          return loginResult.future;
        });

        final foregroundRefresh = container.read(appAuthStateProvider.notifier).refreshSession();
        await Future<void>.delayed(Duration.zero);
        var backgroundCompleted = false;
        final backgroundRefresh = container
            .read(appAuthStateProvider.notifier)
            .refreshSessionInBackground()
            .whenComplete(() {
              backgroundCompleted = true;
            });
        await Future<void>.delayed(Duration.zero);
        final backgroundCompletedBeforeLogin = backgroundCompleted;
        loginResult.complete(false);
        final foregroundResult = await foregroundRefresh;
        await backgroundRefresh;

        expect(
          (
            backgroundCompletedBeforeLogin: backgroundCompletedBeforeLogin,
            backgroundCompletedAfterLogin: backgroundCompleted,
            foregroundResult: foregroundResult,
            loginRequestCount: loginRequestCount,
          ),
          (
            backgroundCompletedBeforeLogin: false,
            backgroundCompletedAfterLogin: true,
            foregroundResult: null,
            loginRequestCount: 1,
          ),
        );
      },
    );

    test(
      'when foreground refresh joins a background request rejected as unauthorized, it should request login once',
      () async {
        final currentSession = AuthSessionDto.fixture().copyWith(
          refreshToken: 'rejected-refresh-token',
          refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
        );
        final authenticatedSession = AuthSessionDto.fixture().copyWith(
          accessToken: 'interactive-access-token',
          refreshToken: 'interactive-refresh-token',
        );
        await container.read(appAuthStateProvider.notifier).setSession(currentSession);
        final refreshResponse = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
        var refreshRequestCount = 0;
        var loginRequestCount = 0;
        when(() => authRepository.refreshSession(refreshToken: 'rejected-refresh-token')).thenAnswer((_) {
          refreshRequestCount += 1;
          return refreshResponse.future;
        });
        when(loginSheetController.show).thenAnswer((_) async {
          loginRequestCount += 1;
          await container.read(appAuthStateProvider.notifier).setSession(authenticatedSession);
          return true;
        });

        late Future<void> backgroundRefresh;
        late Future<AuthSessionDto?> foregroundRefresh;
        await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () async {
          backgroundRefresh = container.read(appAuthStateProvider.notifier).refreshSessionInBackground();
          await Future<void>.delayed(Duration.zero);
          foregroundRefresh = container.read(appAuthStateProvider.notifier).refreshSession();
          refreshResponse.completeError(
            DioException(
              requestOptions: RequestOptions(path: '/auth/sessions/refresh'),
              response: Response<void>(requestOptions: RequestOptions(path: '/auth/sessions/refresh'), statusCode: 401),
            ),
          );
        });
        final result = await foregroundRefresh;
        await backgroundRefresh;

        expect(
          (result: result, refreshRequestCount: refreshRequestCount, loginRequestCount: loginRequestCount),
          (result: authenticatedSession, refreshRequestCount: 1, loginRequestCount: 1),
        );
      },
    );

    test('when refresh is already active, concurrent callers should share one request and session', () async {
      final storedCredentials = AuthCredentialsDto.fixture().copyWith(
        refreshToken: 'saved-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15),
      );
      await container.read(appStorageStateProvider.notifier).setAuthCredentials(credentials: storedCredentials);
      final issuedSession = NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto;
      final responseCompleter = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
      var refreshRequestCount = 0;
      when(() => authRepository.refreshSession(refreshToken: 'saved-refresh-token')).thenAnswer((_) {
        refreshRequestCount += 1;
        return responseCompleter.future;
      });

      late Future<AuthSessionDto?> firstRefresh;
      late Future<AuthSessionDto?> secondRefresh;
      await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () async {
        firstRefresh = container.read(appAuthStateProvider.notifier).refreshSession();
        secondRefresh = container.read(appAuthStateProvider.notifier).refreshSession();
        await Future<void>.delayed(Duration.zero);
        responseCompleter.complete(ApiEnvelopeDto.fixture(data: issuedSession));
      });
      final results = await Future.wait([firstRefresh, secondRefresh]);
      final expectedSession = AuthSessionDto.fromIssuedAuthSession(issuedSession);

      expect(
        (
          sameFuture: identical(firstRefresh, secondRefresh),
          refreshRequestCount: refreshRequestCount,
          firstResult: results.first,
          secondResult: results.last,
        ),
        (sameFuture: true, refreshRequestCount: 1, firstResult: expectedSession, secondResult: expectedSession),
      );
    });
  });
}
