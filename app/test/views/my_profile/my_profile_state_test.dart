import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/authentication_dismissed_dio_exception.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/my_profile/my_profile_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockSharedPreferencesAsync prefs;
  late MockFlutterSecureStorage secureStorage;
  late MockUserRepository userRepository;
  late ProviderContainer container;

  setUp(() async {
    prefs = MockSharedPreferencesAsync();
    secureStorage = MockFlutterSecureStorage();
    userRepository = MockUserRepository();
    when(() => prefs.getBool(any())).thenAnswer((_) async => false);
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(userRepository.getMyProfile).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(data: UserProfileDto.fixture().copyWith(displayIdentifier: 'Ana Teste')),
    );
    container = ProviderContainer(
      overrides: [
        sharedPreferencesAsyncProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(secureStorage),
        userRepositoryProvider.overrideWithValue(userRepository),
      ],
    );
    await container.read(appStorageStateProvider.future);
  });

  tearDown(() => container.dispose());

  test('when signed out, it should have no profile and make no profile request', () async {
    expect(await container.read(myProfileStateProvider.future), isNull);
    verifyNever(userRepository.getMyProfile);
  });

  test('when the user logs in, it should fetch and keep their profile', () async {
    expect(await container.read(myProfileStateProvider.future), isNull);

    await container.read(appAuthStateProvider.notifier).setSession(AuthSessionDto.fixture());
    await container.pump();

    expect((await container.read(myProfileStateProvider.future))?.displayIdentifier, 'Ana Teste');
    verify(userRepository.getMyProfile).called(1);
  });

  test('when a profile request fails temporarily, it should retry and load the profile', () async {
    container.listen(myProfileStateProvider, (_, _) {});
    var requestCount = 0;
    when(userRepository.getMyProfile).thenAnswer((_) async {
      requestCount += 1;
      if (requestCount == 1) {
        final options = RequestOptions(path: '/users/me');
        throw DioException(
          requestOptions: options,
          response: Response<Object?>(requestOptions: options, statusCode: 503),
          type: .badResponse,
        );
      }
      return ApiEnvelopeDto.fixture(data: UserProfileDto.fixture());
    });
    await container.read(myProfileStateProvider.future);

    await container.read(appAuthStateProvider.notifier).setSession(AuthSessionDto.fixture());

    expect(await container.read(myProfileStateProvider.future).timeout(const Duration(seconds: 3)), isNotNull);
    expect(requestCount, 2);
  });

  test('when a profile request is unauthorized, it should not retry', () async {
    final options = RequestOptions(path: '/users/me');
    when(userRepository.getMyProfile).thenThrow(
      DioException(
        requestOptions: options,
        response: Response<Object?>(requestOptions: options, statusCode: 401),
        type: .badResponse,
      ),
    );
    await container.read(myProfileStateProvider.future);

    await container.read(appAuthStateProvider.notifier).setSession(AuthSessionDto.fixture());

    await expectLater(container.read(myProfileStateProvider.future), throwsA(isA<DioException>()));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    verify(userRepository.getMyProfile).called(1);
  });

  test('when authentication is dismissed, it should not retry the profile request', () async {
    when(
      userRepository.getMyProfile,
    ).thenThrow(AuthenticationDismissedDioException(requestOptions: RequestOptions(path: '/users/me')));
    await container.read(myProfileStateProvider.future);

    await container.read(appAuthStateProvider.notifier).setSession(AuthSessionDto.fixture());

    await expectLater(
      container.read(myProfileStateProvider.future),
      throwsA(isA<AuthenticationDismissedDioException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    verify(userRepository.getMyProfile).called(1);
  });

  test('when authentication clears, it should clear the profile', () async {
    await container.read(myProfileStateProvider.future);
    await container.read(appAuthStateProvider.notifier).setSession(AuthSessionDto.fixture());
    await container.pump();
    await container.read(myProfileStateProvider.future);
    expect(container.read(myProfileStateProvider).value, isNotNull);

    container.invalidate(appAuthStateProvider);
    await container.pump();

    expect(await container.read(myProfileStateProvider.future), isNull);
    verify(userRepository.getMyProfile).called(1);
  });

  test('when the user changes, it should fetch their profile without refetching on token renewal', () async {
    var fetchCount = 0;
    when(userRepository.getMyProfile).thenAnswer((_) async {
      fetchCount += 1;
      return ApiEnvelopeDto.fixture(data: UserProfileDto.fixture().copyWith(displayIdentifier: 'Profile $fetchCount'));
    });
    await container.read(myProfileStateProvider.future);
    final firstSession = AuthSessionDto.fixture();

    await container.read(appAuthStateProvider.notifier).setSession(firstSession);
    await container.pump();
    await container.read(myProfileStateProvider.future);
    expect(container.read(myProfileStateProvider).value?.displayIdentifier, 'Profile 1');

    await container.read(appAuthStateProvider.notifier).setSession(firstSession.copyWith(accessToken: 'renewed-token'));
    await container.pump();
    expect(fetchCount, 1);

    await container.read(appAuthStateProvider.notifier).setSession(firstSession.copyWith(userId: 'second-user'));
    await container.pump();
    await container.read(myProfileStateProvider.future);
    expect(container.read(myProfileStateProvider).value?.displayIdentifier, 'Profile 2');
    expect(fetchCount, 2);
  });
}
