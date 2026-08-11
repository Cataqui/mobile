import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when created with completed onboarding, it should expose the completion value', () {
    const data = AppStorageData(authCredentials: null, hasSeenSwipeFeedHint: false, hasCompletedOnboarding: true);

    expect(data.hasCompletedOnboarding, isTrue);
  });

  test('when copying with completed onboarding, it should update the completion value', () {
    const data = AppStorageData(authCredentials: null, hasSeenSwipeFeedHint: false, hasCompletedOnboarding: false);

    final updatedData = data.copyWith(hasCompletedOnboarding: true);

    expect(updatedData.hasCompletedOnboarding, isTrue);
  });

  test('when copying the swipe hint value, it should preserve onboarding completion', () {
    const data = AppStorageData(authCredentials: null, hasSeenSwipeFeedHint: false, hasCompletedOnboarding: true);

    final updatedData = data.copyWith(hasSeenSwipeFeedHint: true);

    expect(updatedData.hasCompletedOnboarding, isTrue);
  });
}
