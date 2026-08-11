import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late MockSharedPreferencesAsync prefs;
  late MockFlutterSecureStorage secureStorage;

  setUp(() {
    prefs = MockSharedPreferencesAsync();
    secureStorage = MockFlutterSecureStorage();
    when(() => prefs.getBool(any())).thenAnswer((_) async => null);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesAsyncProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('when the swipe feed hint flag was never stored, it should load it as false', () async {
    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(data.hasSeenSwipeFeedHint, isFalse);
  });

  test('when the swipe feed hint flag is stored as true, it should load it as true', () async {
    when(() => prefs.getBool('seen_swipe_feed_hint')).thenAnswer((_) async => true);

    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(data.hasSeenSwipeFeedHint, isTrue);
  });

  test('when setting the swipe feed hint flag to true, it should persist the value', () async {
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

    verify(() => prefs.setBool('seen_swipe_feed_hint', true)).called(1);
  });

  test('when setting the swipe feed hint flag to true, it should update the in-memory value', () async {
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

    expect(container.read(appStorageStateProvider).value!.hasSeenSwipeFeedHint, isTrue);
  });

  test('when setting the swipe feed hint flag to false, it should persist the value', () async {
    when(() => prefs.getBool('seen_swipe_feed_hint')).thenAnswer((_) async => true);
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: false);

    verify(() => prefs.setBool('seen_swipe_feed_hint', false)).called(1);
  });

  test('when setting the swipe feed hint flag to its current value, it should not persist again', () async {
    when(() => prefs.getBool('seen_swipe_feed_hint')).thenAnswer((_) async => true);
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

    verifyNever(() => prefs.setBool(any(), any()));
  });

  test('when setting the swipe feed hint flag to its current value, it should not notify watchers', () async {
    when(() => prefs.getBool('seen_swipe_feed_hint')).thenAnswer((_) async => true);
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);
    var notificationCount = 0;
    container.listen(appStorageStateProvider, (_, __) => notificationCount++);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

    expect(notificationCount, 0);
  });

  test('when onboarding completion was never stored, it should load it as false', () async {
    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(data.hasCompletedOnboarding, isFalse);
  });

  test('when onboarding completion is stored as true, it should load it as true', () async {
    when(() => prefs.getBool('completed_onboarding')).thenAnswer((_) async => true);

    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(data.hasCompletedOnboarding, isTrue);
  });

  test('when authentication credentials were never stored, it should load them as null', () async {
    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(data.authCredentials, isNull);
  });

  test('when authentication credentials are stored, it should load the complete credentials', () async {
    when(() => secureStorage.read(key: 'auth_credentials')).thenAnswer(
      (_) async => '{"refreshToken":"stored-refresh-token","refreshTokenExpiresAt":"2027-09-12T18:30:00.000Z"}',
    );
    final expectedCredentials = AuthCredentialsDto.fixture().copyWith(
      refreshToken: 'stored-refresh-token',
      refreshTokenExpiresAt: DateTime.parse('2027-09-12T18:30:00.000Z'),
    );

    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(data.authCredentials, expectedCredentials);
  });

  test('when stored authentication credentials are malformed, it should clear them and load null', () async {
    var didDeleteCredentials = false;
    when(() => secureStorage.read(key: 'auth_credentials')).thenAnswer((_) async => '{malformed-json');
    when(() => secureStorage.delete(key: 'auth_credentials')).thenAnswer((_) async {
      didDeleteCredentials = true;
    });

    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(
      (authCredentials: data.authCredentials, didDeleteCredentials: didDeleteCredentials),
      (authCredentials: null, didDeleteCredentials: true),
    );
  });

  test('when secure credentials cannot be read or cleared, it should still load them as null', () async {
    var didAttemptToDeleteCredentials = false;
    when(() => secureStorage.read(key: 'auth_credentials')).thenThrow(StateError('secure storage unavailable'));
    when(() => secureStorage.delete(key: 'auth_credentials')).thenAnswer((_) async {
      didAttemptToDeleteCredentials = true;
      throw StateError('secure storage unavailable');
    });

    final data = await buildContainer().read(appStorageStateProvider.future);

    expect(
      (authCredentials: data.authCredentials, didAttemptToDeleteCredentials: didAttemptToDeleteCredentials),
      (authCredentials: null, didAttemptToDeleteCredentials: true),
    );
  });

  test('when storage flags change after credentials load, it should preserve the credentials', () async {
    when(() => secureStorage.read(key: 'auth_credentials')).thenAnswer(
      (_) async => '{"refreshToken":"stored-refresh-token","refreshTokenExpiresAt":"2027-09-12T18:30:00.000Z"}',
    );
    final container = buildContainer();
    final loadedData = await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

    expect(container.read(appStorageStateProvider).value!.authCredentials, loadedData.authCredentials);
  });

  test('when completing onboarding, it should persist the completion flag', () async {
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).completeOnboarding();

    verify(() => prefs.setBool('completed_onboarding', true)).called(1);
  });

  test('when completing onboarding, it should update the in-memory completion flag', () async {
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).completeOnboarding();

    expect(container.read(appStorageStateProvider).value!.hasCompletedOnboarding, isTrue);
  });

  test('when completing onboarding after it is already complete, it should not persist again', () async {
    when(() => prefs.getBool('completed_onboarding')).thenAnswer((_) async => true);
    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).completeOnboarding();

    verifyNever(() => prefs.setBool(any(), any()));
  });
}
