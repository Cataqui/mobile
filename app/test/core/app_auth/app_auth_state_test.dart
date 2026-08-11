import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockFlutterSecureStorage secureStorage;
  late MockSharedPreferencesAsync sharedPreferences;
  late ProviderContainer container;

  setUp(() async {
    authRepository = MockAuthRepository();
    secureStorage = MockFlutterSecureStorage();
    sharedPreferences = MockSharedPreferencesAsync();
    when(() => sharedPreferences.getBool(any())).thenAnswer((_) async => null);
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
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
      'when valid credentials are saved, it should publish and persist the complete rotated session on refresh',
      () async {
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

        await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () async {
          await container.read(appAuthStateProvider.notifier).refreshSession();
        });

        expect(
          (
            requestedRefreshToken: requestedRefreshToken,
            session: container.read(appAuthStateProvider),
            credentials: container.read(appStorageStateProvider).value!.authCredentials,
          ),
          (
            requestedRefreshToken: 'saved-refresh-token',
            session: AuthSessionDto.fromIssuedAuthSession(issuedSession),
            credentials: AuthCredentialsDto.fromAuthSession(AuthSessionDto.fromIssuedAuthSession(issuedSession)),
          ),
        );
      },
    );

    test('when no credentials are saved, it should preserve the current session without a refresh request', () async {
      final currentSession = AuthSessionDto.fixture();
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(StateError('secure storage unavailable'));
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      var requestCount = 0;
      when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {
        requestCount += 1;
        return ApiEnvelopeDto.fixture(data: AuthIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto);
      });

      await container.read(appAuthStateProvider.notifier).refreshSession();

      expect(
        (session: container.read(appAuthStateProvider), requestCount: requestCount),
        (session: currentSession, requestCount: 0),
      );
    });

    test(
      'when saved credentials expire at the current time, it should preserve the session without a refresh request',
      () async {
        final currentTime = DateTime.utc(2026, 8, 11, 15);
        final currentSession = AuthSessionDto.fixture().copyWith(
          refreshToken: 'expired-refresh-token',
          refreshTokenExpiresAt: currentTime,
        );
        await container.read(appAuthStateProvider.notifier).setSession(currentSession);
        var requestCount = 0;
        when(() => authRepository.refreshSession(refreshToken: any(named: 'refreshToken'))).thenAnswer((_) async {
          requestCount += 1;
          return ApiEnvelopeDto.fixture(
            data: AuthIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto,
          );
        });

        await withClock(Clock.fixed(currentTime), () async {
          await container.read(appAuthStateProvider.notifier).refreshSession();
        });

        expect(
          (session: container.read(appAuthStateProvider), requestCount: requestCount),
          (session: currentSession, requestCount: 0),
        );
      },
    );

    test('when the refresh request fails, it should rethrow the error and preserve the current session', () async {
      final currentSession = AuthSessionDto.fixture().copyWith(
        refreshToken: 'saved-refresh-token',
        refreshTokenExpiresAt: DateTime.utc(2026, 9, 10, 15, 15),
      );
      await container.read(appAuthStateProvider.notifier).setSession(currentSession);
      final refreshError = StateError('refresh failed');
      when(() => authRepository.refreshSession(refreshToken: 'saved-refresh-token')).thenThrow(refreshError);
      Object? thrownError;

      try {
        await withClock(Clock.fixed(DateTime.utc(2026, 8, 11, 15)), () async {
          await container.read(appAuthStateProvider.notifier).refreshSession();
        });
      } catch (error) {
        thrownError = error;
      }

      expect(
        (error: thrownError, session: container.read(appAuthStateProvider)),
        (error: refreshError, session: currentSession),
      );
    });
  });
}
