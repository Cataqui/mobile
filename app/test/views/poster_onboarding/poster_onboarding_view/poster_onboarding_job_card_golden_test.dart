import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';

import 'poster_onboarding_view_test_helpers.dart';

void main() {
  goldenTest(
    'when a poster job card is shown, it should match the approved map and interest composition',
    fileName: 'poster_onboarding_job_card',
    constraints: const BoxConstraints.tightFor(width: 340, height: 460),
    whilePerforming: (tester) async {
      await PosterOnboardingViewTestHelpers.prepareJobCardGoldenCapture(tester: tester);

      return null;
    },
    builder: PosterOnboardingViewTestHelpers.jobCardGoldenScenario,
  );
}
