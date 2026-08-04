import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';

import 'poster_onboarding_view_test_helpers.dart';

void main() {
  goldenTest(
    'when the poster job scene is shown, it should match the moving job preview composition',
    fileName: 'poster_onboarding_job_scene',
    constraints: const BoxConstraints.tightFor(width: 390, height: 520),
    whilePerforming: (tester) async {
      await PosterOnboardingViewTestHelpers.prepareJobSceneGoldenCapture(tester: tester);

      return null;
    },
    builder: PosterOnboardingViewTestHelpers.jobSceneGoldenScenario,
  );
}
