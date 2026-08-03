import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_view_test_helpers.dart';

void main() {
  group('OnboardingView Golden Tests', () {
    goldenTest(
      'when the onboarding screen opens, it should match the approved production design',
      fileName: 'onboarding_view',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await OnboardingViewTestHelpers.prepareGoldenCapture(tester: tester);

        return null;
      },
      builder: OnboardingViewTestHelpers.goldenScenario,
    );
  });
}
