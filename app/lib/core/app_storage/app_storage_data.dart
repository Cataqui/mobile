import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/onboarding_local_progress_dto/onboarding_local_progress_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_storage_data.freezed.dart';

@freezed
abstract class AppStorageData with _$AppStorageData {
  const factory AppStorageData({
    required AuthCredentialsDto? authCredentials,
    required bool hasSeenSwipeFeedHint,
    @Default(<String, OnboardingLocalProgressDto>{}) Map<String, OnboardingLocalProgressDto> onboardingLocalData,
  }) = _AppStorageData;
}
