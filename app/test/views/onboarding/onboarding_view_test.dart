import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'onboarding_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  group('OnboardingView', () {
    testWidgets('when the onboarding intro plays, it should use the shared motion widget', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(tester.widget(find.byKey(const ValueKey('onboarding_intro_headline_motion'))), isA<Motion>());
    });

    testWidgets('when the onboarding intro evolves, it should increase the haptic impact with each reveal', (
      tester,
    ) async {
      final feedbackTypes = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') feedbackTypes.add(call.arguments);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 3200));

      expect(feedbackTypes, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    });

    testWidgets('when reduced motion is enabled, it should keep the onboarding intro haptics silent', (tester) async {
      final feedbackTypes = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') feedbackTypes.add(call.arguments);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(feedbackTypes, isEmpty);
    });

    testWidgets('when the onboarding screen opens, it should show the localized product message', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(
        tester
            .widget<Text>(
              find.descendant(of: find.byKey(const ValueKey('onboarding_intro_headline')), matching: find.byType(Text)),
            )
            .data,
        i18n.onboarding.headline,
      );
    });

    testWidgets('when the onboarding screen opens, it should label the nearby jobs scene for accessibility', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(find.bySemanticsLabel(i18n.onboarding.sceneAccessibilityLabel), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('when the onboarding screen opens, it should show the animated nearby jobs scene', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(find.byKey(const ValueKey('onboarding_job_cards_carousel')), findsOneWidget);
    });

    testWidgets('when the intro begins, it should present the headline near the middle of the screen', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.getCenter(find.byKey(const ValueKey('onboarding_intro_headline'))).dy, closeTo(844 / 2, 24));
    });

    testWidgets('when the intro begins, it should keep the job scene invisible behind the headline', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byKey(const ValueKey('onboarding_intro_scene')),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value,
        0,
      );
    });

    testWidgets('when the job scene waits to appear, it should pause its card animation until the reveal', (
      tester,
    ) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(tester.widget<PauseAnimations>(find.byType(PauseAnimations)).duration, const Duration(milliseconds: 2048));
    });

    testWidgets('when the intro begins, it should keep the button panel invisible', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        tester
            .widget<FadeTransition>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('onboarding_intro_button_panel')),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value,
        0,
      );
    });

    testWidgets('when the headline finishes appearing, it should stay centered long enough to be read', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 1200));
      final centeredHeadlinePosition = tester.getCenter(find.byKey(const ValueKey('onboarding_intro_headline'))).dy;
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.getCenter(find.byKey(const ValueKey('onboarding_intro_headline'))).dy, centeredHeadlinePosition);
    });

    testWidgets('when the intro advances, it should move the headline from the middle to below the job scene', (
      tester,
    ) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 250));
      final initialHeadlineCenter = tester.getCenter(find.byKey(const ValueKey('onboarding_intro_headline'))).dy;
      await tester.pump(const Duration(milliseconds: 1350));
      await tester.pump(const Duration(milliseconds: 576));

      expect(
        tester.getCenter(find.byKey(const ValueKey('onboarding_intro_headline'))).dy,
        greaterThan(initialHeadlineCenter),
      );
    });

    testWidgets('when the intro reaches the scene reveal, it should show the job cards and floating props', (
      tester,
    ) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2048));
      await tester.pump(const Duration(milliseconds: 704));

      expect(
        tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byKey(const ValueKey('onboarding_intro_scene')),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value,
        1,
      );
    });

    testWidgets('when the intro completes, it should show the fixed button panel', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2624));
      await tester.pump(const Duration(milliseconds: 576));

      expect(
        tester
            .widget<FadeTransition>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('onboarding_intro_button_panel')),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value,
        1,
      );
    });

    testWidgets('when the intro is still playing, it should block pointer access to the actions', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('onboarding_intro_button_panel')),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isTrue,
      );
    });

    testWidgets('when the intro is still playing, it should hide the actions from accessibility', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        tester.widget<ExcludeSemantics>(find.byKey(const ValueKey('onboarding_actions_semantics_gate'))).excluding,
        isTrue,
      );
    });

    testWidgets('when the intro completes, it should allow pointer access to the actions', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2624));
      await tester.pump(const Duration(milliseconds: 576));
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('onboarding_intro_button_panel')),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring,
        isFalse,
      );
    });

    testWidgets('when the intro completes, it should expose the actions to accessibility', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2624));
      await tester.pump(const Duration(milliseconds: 576));
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        tester.widget<ExcludeSemantics>(find.byKey(const ValueKey('onboarding_actions_semantics_gate'))).excluding,
        isFalse,
      );
    });

    testWidgets('when reduced motion is enabled, it should expose the completed intro immediately', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(
        tester.widget<ExcludeSemantics>(find.byKey(const ValueKey('onboarding_actions_semantics_gate'))).excluding,
        isFalse,
      );
    });

    testWidgets('when reduced motion is enabled, it should place the headline below the job scene', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(
        tester.getCenter(find.byKey(const ValueKey('onboarding_intro_headline'))).dy,
        greaterThan(tester.getCenter(find.byKey(const ValueKey('onboarding_job_scene_size'))).dy),
      );
    });

    testWidgets('when the job cards render, the visible job props should use shared floating motion', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(
        [
          'onboarding_cooker_hat',
          'onboarding_hammer',
          'onboarding_ladder',
        ].map((key) => tester.widget(find.byKey(ValueKey(key)))),
        everyElement(isA<Motion>()),
      );
    });

    testWidgets('when the intro finishes, the floating job props should move vertically over time', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2624));
      await tester.pump(const Duration(milliseconds: 576));
      await tester.pump(const Duration(milliseconds: 1));
      final cookerHat = find.descendant(
        of: find.byKey(const ValueKey('onboarding_cooker_hat')),
        matching: find.byType(Image),
      );
      final initialVerticalOffset = tester.getTopLeft(cookerHat).dy;
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.getTopLeft(cookerHat).dy, isNot(initialVerticalOffset));
    });

    testWidgets('when reduced motion is enabled, the floating job props should remain still', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);
      final initialVerticalOffset = tester.getTopLeft(find.byKey(const ValueKey('onboarding_cooker_hat'))).dy;
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.getTopLeft(find.byKey(const ValueKey('onboarding_cooker_hat'))).dy, initialVerticalOffset);
    });

    testWidgets('when the onboarding screen opens, it should show localized labels for both actions', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(
        (
          viewJobs: tester.widget<MateoButton>(find.byKey(const ValueKey('onboarding_view_jobs_button'))).label,
          postJob: tester.widget<MateoButton>(find.byKey(const ValueKey('onboarding_post_job_button'))).label,
        ),
        (viewJobs: i18n.onboarding.actions.viewJobs, postJob: i18n.onboarding.actions.postJob),
      );
    });

    testWidgets('when the onboarding screen opens, it should make the post-work action available', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(tester.widget<MateoButton>(find.byKey(const ValueKey('onboarding_post_job_button'))).onPressed, isNotNull);
    });

    testWidgets('when the onboarding screen opens, it should keep the button panel 12 pixels from the phone edge', (
      tester,
    ) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(tester.getBottomLeft(find.byType(MateoButtonPanel)).dy, 844 - 12);
    });

    testWidgets('when the onboarding screen opens, it should not expose scrollable content', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester);

      expect(find.byType(Scrollable), findsNothing);
    });

    testWidgets('when the user swipes the onboarding content, it should keep the headline stationary', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, height: 568);
      final initialHeadlineTop = tester.getTopLeft(find.byKey(const ValueKey('onboarding_intro_headline'))).dy;
      await tester.drag(find.byType(OnboardingView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(const ValueKey('onboarding_intro_headline'))).dy, initialHeadlineTop);
    });

    testWidgets('when the screen is compact, it should keep the job scene at its minimum useful height', (
      tester,
    ) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, width: 320, height: 568);

      expect(tester.getSize(find.byKey(const ValueKey('onboarding_job_scene_size'))).height, 340);
    });

    testWidgets('when the screen is tall, it should cap the job scene at its maximum useful height', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, width: 430, height: 932);

      expect(tester.getSize(find.byKey(const ValueKey('onboarding_job_scene_size'))).height, 460);
    });

    testWidgets('when the screen opens on a compact phone, it should avoid layout overflow', (tester) async {
      await OnboardingViewTestHelpers.pumpView(tester: tester, width: 320, height: 568);

      expect(tester.takeException(), isNull);
    });
  });
}
