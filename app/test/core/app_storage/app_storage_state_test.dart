import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferencesAsync extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockSharedPreferencesAsync prefs;

  setUp(() {
    prefs = _MockSharedPreferencesAsync();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(overrides: [sharedPreferencesAsyncProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    return container;
  }

  test('when the swipe feed hint flag was never stored, it should load hasSeenSwipeFeedHint as false', () async {
    when(() => prefs.getBool(any())).thenAnswer((_) async => null);

    final container = buildContainer();
    final data = await container.read(appStorageStateProvider.future);

    expect(data.hasSeenSwipeFeedHint, isFalse);
  });

  test('when the swipe feed hint flag is stored as true, it should load hasSeenSwipeFeedHint as true', () async {
    when(() => prefs.getBool('seen_swipe_feed_hint')).thenAnswer((_) async => true);

    final container = buildContainer();
    final data = await container.read(appStorageStateProvider.future);

    expect(data.hasSeenSwipeFeedHint, isTrue);
  });

  test(
    'when setting the swipe feed hint flag to true, it should persist the value to SharedPreferencesAsync',
    () async {
      when(() => prefs.getBool(any())).thenAnswer((_) async => null);
      when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});

      final container = buildContainer();
      await container.read(appStorageStateProvider.future);

      await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

      verify(() => prefs.setBool('seen_swipe_feed_hint', true)).called(1);
    },
  );

  test('when setting the swipe feed hint flag to true, it should update the state to reflect the new value', () async {
    when(() => prefs.getBool(any())).thenAnswer((_) async => false);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});

    final container = buildContainer();
    await container.read(appStorageStateProvider.future);

    await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

    expect(container.read(appStorageStateProvider).value!.hasSeenSwipeFeedHint, isTrue);
  });

  test(
    'when setting the swipe feed hint flag to false, it should persist the value to SharedPreferencesAsync',
    () async {
      when(() => prefs.getBool(any())).thenAnswer((_) async => true);
      when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});

      final container = buildContainer();
      await container.read(appStorageStateProvider.future);

      await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: false);

      verify(() => prefs.setBool('seen_swipe_feed_hint', false)).called(1);
    },
  );

  test(
    'when setting the swipe feed hint flag to the same value as the current state, it should not persist and not notify watchers',
    () async {
      when(() => prefs.getBool(any())).thenAnswer((_) async => true);
      when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});

      final container = buildContainer();
      await container.read(appStorageStateProvider.future);

      var notificationCount = 0;
      container.listen(appStorageStateProvider, (_, __) {
        notificationCount++;
      });

      await container.read(appStorageStateProvider.notifier).setSeenSwipeFeedHint(value: true);

      verifyNever(() => prefs.setBool(any(), any()));
      expect(notificationCount, equals(0));
    },
  );
}
