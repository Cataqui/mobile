import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'welcome_view_test_helpers.dart';

void main() {
  group('WelcomeView Golden Tests', () {
    goldenTest(
      'when welcome opens, it should match the approved reference composition',
      fileName: 'welcome_view',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await WelcomeViewTestHelpers.prepareGoldenCapture(tester: tester);
        return null;
      },
      builder: WelcomeViewTestHelpers.goldenScenario,
    );

    goldenTest(
      'when welcome opens on a compact phone, it should preserve the complete composition',
      fileName: 'welcome_view_compact',
      constraints: const BoxConstraints.tightFor(width: 360, height: 640),
      whilePerforming: (tester) async {
        await WelcomeViewTestHelpers.prepareGoldenCapture(tester: tester);
        return null;
      },
      builder: () => WelcomeViewTestHelpers.goldenScenario(
        width: 360,
        height: 640,
        padding: const EdgeInsets.only(top: 24, bottom: 24),
      ),
    );
  });
}
