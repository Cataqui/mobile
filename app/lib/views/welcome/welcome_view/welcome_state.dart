import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/onboarding_local_progress_dto/onboarding_local_progress_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'welcome_state.g.dart';

@riverpod
class WelcomeState extends _$WelcomeState {
  @override
  WelcomeData build() => const WelcomeData();

  Future<void> fetchConnectedUserMetadata() async {
    if (state.metadata.isLoading) return;

    final accountId = ref.read(appAuthStateProvider)?.accountId;
    if (accountId == null) return;
    final appStorageState = ref.read(appStorageStateProvider.notifier);

    state = state.copyWith(metadata: const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      final envelope = await ref.read(meRepositoryProvider).getMetadata();
      if (!ref.mounted) return envelope.data;

      final progress =
          ref.read(appStorageStateProvider).requireValue.onboardingLocalData[accountId] ??
          const OnboardingLocalProgressDto();

      await appStorageState.setLocalOnboardingProgress(
        accountId: accountId,
        progress: progress.copyWith(serverConfirmedCompleted: envelope.data.onboardingCompleted),
      );
      return envelope.data;
    });

    if (!ref.mounted || ref.read(appAuthStateProvider)?.accountId != accountId) return;

    state = state.copyWith(metadata: result);
  }
}
