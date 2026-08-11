import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_storage_state.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
class AppStorageState extends _$AppStorageState {
  static const _authCredentialsKey = 'auth_credentials';
  static const _seenSwipeFeedHintKey = 'seen_swipe_feed_hint';
  static const _completedOnboardingKey = 'completed_onboarding';

  @override
  Future<AppStorageData> build() async {
    final prefs = ref.read(sharedPreferencesAsyncProvider);
    final hasSeenSwipeFeedHint = await prefs.getBool(_seenSwipeFeedHintKey) ?? false;
    final hasCompletedOnboarding = await prefs.getBool(_completedOnboardingKey) ?? false;

    return AppStorageData(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint, hasCompletedOnboarding: hasCompletedOnboarding);
  }

  Future<void> completeOnboarding() async {
    if (state.value!.hasCompletedOnboarding) return;

    final prefs = ref.read(sharedPreferencesAsyncProvider);
    await prefs.setBool(_completedOnboardingKey, true);

    state = AsyncData(state.value!.copyWith(hasCompletedOnboarding: true));
  }

  Future<void> saveAuthCredentials({required AuthCredentialsDto credentials}) async {
    await ref.read(secureStorageProvider).write(key: _authCredentialsKey, value: credentials.toSecureStorageValue());
  }

  Future<void> setSeenSwipeFeedHint({required bool value}) async {
    if (state.value!.hasSeenSwipeFeedHint == value) return;

    final prefs = ref.read(sharedPreferencesAsyncProvider);
    await prefs.setBool(_seenSwipeFeedHintKey, value);

    state = AsyncData(state.value!.copyWith(hasSeenSwipeFeedHint: value));
  }
}
