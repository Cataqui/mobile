import 'package:flutter/foundation.dart';

@immutable
class AppStorageData {
  const AppStorageData({required this.hasSeenSwipeFeedHint, required this.hasCompletedOnboarding});

  final bool hasSeenSwipeFeedHint;
  final bool hasCompletedOnboarding;

  AppStorageData copyWith({bool? hasSeenSwipeFeedHint, bool? hasCompletedOnboarding}) {
    return AppStorageData(
      hasSeenSwipeFeedHint: hasSeenSwipeFeedHint ?? this.hasSeenSwipeFeedHint,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
