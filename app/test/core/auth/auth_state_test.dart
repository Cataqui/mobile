import 'package:cataqui_app/core/auth/auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockFlutterSecureStorage secureStorage;
  late MockSharedPreferencesAsync sharedPreferences;
  late ProviderContainer container;

  setUp(() {
    secureStorage = MockFlutterSecureStorage();
    sharedPreferences = MockSharedPreferencesAsync();
    when(() => sharedPreferences.getBool(any())).thenAnswer((_) async => null);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(secureStorage),
        sharedPreferencesAsyncProvider.overrideWithValue(sharedPreferences),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthState', () {
    test('when first read, it should expose an unauthenticated session', () {
      final session = container.read(authStateProvider);

      expect(session, isNull);
    });

    test('when setting an authenticated session, it should expose the complete session', () async {
      final session = AuthSessionDto.fixture();

      await container.read(authStateProvider.notifier).setSession(session);

      expect(container.read(authStateProvider), session);
    });

    test('when the auth state has no active listeners, it should retain the authenticated session', () async {
      final subscription = container.listen(authStateProvider, (_, __) {}, fireImmediately: true);
      final session = AuthSessionDto.fixture();
      await container.read(authStateProvider.notifier).setSession(session);

      subscription.close();
      await container.pump();

      expect(container.read(authStateProvider), session);
    });

    test('when setting a session, it should securely save its refresh credentials as camelCase JSON', () async {
      final session = AuthSessionDto.fixture().copyWith(
        refreshToken: 'stored-refresh-token',
        refreshTokenExpiresAt: DateTime.parse('2027-09-12T18:30:00.000Z'),
      );

      await container.read(authStateProvider.notifier).setSession(session);

      verify(
        () => secureStorage.write(
          key: 'auth_credentials',
          value: '{"refreshToken":"stored-refresh-token","refreshTokenExpiresAt":"2027-09-12T18:30:00.000Z"}',
        ),
      ).called(1);
    });

    test('when secure persistence fails, it should keep the authenticated session in memory', () async {
      final session = AuthSessionDto.fixture();
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(StateError('secure storage unavailable'));

      await container.read(authStateProvider.notifier).setSession(session);

      expect(container.read(authStateProvider), session);
    });
  });
}
