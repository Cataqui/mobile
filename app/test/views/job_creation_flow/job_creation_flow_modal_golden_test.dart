import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'job_creation_flow_modal_test_helpers.dart';

void main() {
  group('JobCreationFlowModal Golden Tests', () {
    goldenTest(
      'when the job creation sheet opens with no description, it should keep the continue action hidden',
      fileName: 'job_creation_flow_modal',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(JobCreationFlowModalTestHelpers.openButtonKey));
        await tester.pumpAndSettle();

        return null;
      },
      builder: JobCreationFlowModalTestHelpers.buildApp,
    );

    goldenTest(
      'when meaningful description text is entered, it should show the continue action',
      fileName: 'job_creation_flow_modal_typed',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(JobCreationFlowModalTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de ajuda');
        await tester.pumpAndSettle();

        return null;
      },
      builder: JobCreationFlowModalTestHelpers.buildApp,
    );

    goldenTest(
      'when meaningful description text starts with motion enabled, it should pop the continue action into view',
      fileName: 'job_creation_flow_modal_continue_mid_pop',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(JobCreationFlowModalTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de ajuda');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        return null;
      },
      builder: () => JobCreationFlowModalTestHelpers.buildApp(disableAnimations: false),
    );

    goldenTest(
      'when continuing with a short description, it should show the error toast above the sheet',
      fileName: 'job_creation_flow_modal_description_too_short_toast',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(JobCreationFlowModalTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de ajuda');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        return null;
      },
      builder: JobCreationFlowModalTestHelpers.buildApp,
    );
  });
}
