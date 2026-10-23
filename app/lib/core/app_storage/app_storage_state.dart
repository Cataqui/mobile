import 'dart:convert';

import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/onboarding_local_progress_dto/onboarding_local_progress_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_storage_state.g.dart';

@Riverpod(keepAlive: true, retry: AppStorageState._noRetry)
class AppStorageState extends _$AppStorageState {
  static const _authCredentialsKey = 'auth_credentials';
  static const _onboardingDataKey = 'onboarding_data';
  static const _seenSwipeFeedHintKey = 'seen_swipe_feed_hint';

  static Duration? _noRetry(int retryCount, Object error) => null;

  @override
  Future<AppStorageData> build() async {
    final prefs = ref.read(sharedPreferencesAsyncProvider);
    final hasSeenSwipeFeedHint = await prefs.getBool(_seenSwipeFeedHintKey) ?? false;
    final authCredentials = await _readAuthCredentials();

    return AppStorageData(
      authCredentials: authCredentials,
      hasSeenSwipeFeedHint: hasSeenSwipeFeedHint,
      onboardingLocalData: await _readOnboardingLocalData(),
    );
  }

  Future<void> clearAuthCredentials() async {
    try {
      await ref.read(secureStorageProvider).delete(key: _authCredentialsKey);
    } catch (_) {
      // Invalid credentials must stop authenticating this run even when secure storage cannot be cleaned up.
    }

    state = AsyncData(state.value!.copyWith(authCredentials: null));
  }

  Future<void> setAuthCredentials({required AuthCredentialsDto credentials}) async {
    await ref.read(secureStorageProvider).write(key: _authCredentialsKey, value: credentials.toSecureStorageValue());
    state = AsyncData(state.value!.copyWith(authCredentials: credentials));
  }

  Future<void> setLocalOnboardingProgress({
    required String accountId,
    required OnboardingLocalProgressDto progress,
  }) async {
    final currentData = state.requireValue;

    state = AsyncData(
      currentData.copyWith(onboardingLocalData: {...currentData.onboardingLocalData, accountId: progress}),
    );

    try {
      await ref
          .read(sharedPreferencesAsyncProvider)
          .setString(
            _onboardingDataKey,
            jsonEncode({
              for (final entry in state.requireValue.onboardingLocalData.entries) entry.key: entry.value.toJson(),
            }),
          );
    } on Object {
      // Successful metadata remains usable even when the device cannot persist its cache.
    }
  }

  Future<void> setSeenSwipeFeedHint({required bool value}) async {
    if (state.value!.hasSeenSwipeFeedHint == value) return;

    final prefs = ref.read(sharedPreferencesAsyncProvider);
    await prefs.setBool(_seenSwipeFeedHintKey, value);

    state = AsyncData(state.value!.copyWith(hasSeenSwipeFeedHint: value));
  }

  Future<Map<String, OnboardingLocalProgressDto>> _readOnboardingLocalData() async {
    try {
      final storedValue = await ref.read(sharedPreferencesAsyncProvider).getString(_onboardingDataKey);
      if (storedValue == null) return {};

      final Object? decodedValue = jsonDecode(storedValue);
      if (decodedValue is! Map<String, Object?>) return {};

      final onboardingLocalData = <String, OnboardingLocalProgressDto>{};
      for (final entry in decodedValue.entries) {
        final value = entry.value;
        if (value is! Map<String, Object?>) continue;

        try {
          onboardingLocalData[entry.key] = OnboardingLocalProgressDto.fromJson(value);
        } on Object {
          // Preserve other accounts when one entry is malformed.
        }
      }
      return onboardingLocalData;
    } on Object {
      return {};
    }
  }

  Future<AuthCredentialsDto?> _readAuthCredentials() async {
    final secureStorage = ref.read(secureStorageProvider);

    try {
      final storedCredentials = await secureStorage.read(key: _authCredentialsKey);
      if (storedCredentials == null) return null;

      return AuthCredentialsDto.fromSecureStorageValue(storedCredentials);
    } catch (_) {
      try {
        await secureStorage.delete(key: _authCredentialsKey);
      } catch (_) {
        // Credential cleanup is best effort so secure storage cannot block app startup.
      }

      return null;
    }
  }
}
