import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'poster_onboarding_view_test_helpers.dart';

void main() {
  group('PosterOnboardingView Golden Tests', () {
    goldenTest(
      'when poster onboarding opens on a standard phone, it should match the approved composition',
      fileName: 'poster_onboarding_view',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await PosterOnboardingViewTestHelpers.prepareGoldenCapture(tester: tester);

        return null;
      },
      builder: PosterOnboardingViewTestHelpers.goldenScenario,
    );

    goldenTest(
      'when poster onboarding opens with large text on a compact phone, it should keep readable content',
      fileName: 'poster_onboarding_view_large_text',
      constraints: const BoxConstraints.tightFor(width: 320, height: 568),
      whilePerforming: (tester) async {
        await PosterOnboardingViewTestHelpers.prepareGoldenCapture(tester: tester);

        return null;
      },
      builder: () => PosterOnboardingViewTestHelpers.goldenScenario(width: 320, height: 568, textScaler: 1.5),
    );

    goldenTest(
      'when poster onboarding opens on a wide phone, it should extend the marquee to both screen edges',
      fileName: 'poster_onboarding_view_wide',
      constraints: const BoxConstraints.tightFor(width: 440, height: 956),
      whilePerforming: (tester) async {
        await PosterOnboardingViewTestHelpers.prepareGoldenCapture(tester: tester);

        return null;
      },
      builder: () => PosterOnboardingViewTestHelpers.goldenScenario(width: 440, height: 956),
    );
  });
}
