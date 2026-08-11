import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:flutter/foundation.dart';

@immutable
class AppStorageData {
  const AppStorageData({
    required this.authCredentials,
    required this.hasSeenSwipeFeedHint,
    required this.hasCompletedOnboarding,
  });

  final AuthCredentialsDto? authCredentials;
  final bool hasSeenSwipeFeedHint;
  final bool hasCompletedOnboarding;

  AppStorageData copyWith({
    AuthCredentialsDto? authCredentials,
    bool? hasSeenSwipeFeedHint,
    bool? hasCompletedOnboarding,
  }) {
    return AppStorageData(
      authCredentials: authCredentials ?? this.authCredentials,
      hasSeenSwipeFeedHint: hasSeenSwipeFeedHint ?? this.hasSeenSwipeFeedHint,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
