import 'dart:ui' show Tristate;

import 'package:cataqui_app/i18n/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'welcome_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  group('WelcomeView content', () {
    testWidgets('when welcome opens, it should show the complete localized product message', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);

      expect(
        (
          headline: find.text(i18n.welcome.headline).evaluate().length,
          subtitle: find.textContaining(i18n.welcome.subtitle).evaluate().length,
          start: find.text(i18n.welcome.startButton).evaluate().length,
          termsPrefix: find.textContaining(i18n.welcome.terms.prefix).evaluate().length,
          termsLink: find.textContaining(i18n.welcome.terms.link).evaluate().length,
        ),
        (headline: 1, subtitle: 1, start: 1, termsPrefix: 1, termsLink: 1),
      );
    });

    testWidgets('when welcome opens, it should render the first custom card with every field', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);

      expect(
        (
          card: find.byKey(const ValueKey('welcome_job_0')).evaluate().length,
          postedTime: find.text(i18n.welcome.jobs.job1.postedTime).evaluate().length,
          title: find.text(i18n.welcome.jobs.job1.title).evaluate().length,
          amount: find.text(i18n.welcome.jobs.job1.amount).evaluate().length,
          description: find.text(i18n.welcome.jobs.job1.description).evaluate().length,
        ),
        (card: 1, postedTime: 1, title: 1, amount: 1, description: 1),
      );
    });

    testWidgets('when welcome rotates, it should show all five localized jobs and then wrap', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final observedJobs = <({String amount, String description, String postedTime, String title})>[];

      for (var index = 0; index < 5; index += 1) {
        observedJobs.add((
          postedTime: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_posted_time'))).data!,
          title: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data!,
          amount: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_amount'))).data!,
          description: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_description'))).data!,
        ));
        await WelcomeViewTestHelpers.advanceToNextReducedMotionJob(tester);
      }
      final expectedJobs = [
        (
          postedTime: i18n.welcome.jobs.job1.postedTime,
          title: i18n.welcome.jobs.job1.title,
          amount: i18n.welcome.jobs.job1.amount,
          description: i18n.welcome.jobs.job1.description,
        ),
        (
          postedTime: i18n.welcome.jobs.job2.postedTime,
          title: i18n.welcome.jobs.job2.title,
          amount: i18n.welcome.jobs.job2.amount,
          description: i18n.welcome.jobs.job2.description,
        ),
        (
          postedTime: i18n.welcome.jobs.job3.postedTime,
          title: i18n.welcome.jobs.job3.title,
          amount: i18n.welcome.jobs.job3.amount,
          description: i18n.welcome.jobs.job3.description,
        ),
        (
          postedTime: i18n.welcome.jobs.job4.postedTime,
          title: i18n.welcome.jobs.job4.title,
          amount: i18n.welcome.jobs.job4.amount,
          description: i18n.welcome.jobs.job4.description,
        ),
        (
          postedTime: i18n.welcome.jobs.job5.postedTime,
          title: i18n.welcome.jobs.job5.title,
          amount: i18n.welcome.jobs.job5.amount,
          description: i18n.welcome.jobs.job5.description,
        ),
      ];

      expect(
        (
          jobsMatch:
              observedJobs.length == expectedJobs.length &&
              List<bool>.generate(
                observedJobs.length,
                (index) => observedJobs[index] == expectedJobs[index],
              ).every((matches) => matches),
          wrappedTitle: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data,
        ),
        (jobsMatch: true, wrappedTitle: i18n.welcome.jobs.job1.title),
      );
    });

    testWidgets('when welcome opens, every artwork slot should use the same stable surface size', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);

      expect(
        WelcomeViewTestHelpers.artworkSlots
            .map((slot) => tester.getSize(find.byKey(ValueKey('welcome_artwork_circle_$slot'))))
            .toList(),
        List.filled(5, const Size.square(60)),
      );
    });

    testWidgets('when the scene paints, every artwork should remain behind the card', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final stack = tester.widget<Stack>(
        find.descendant(of: find.byKey(const ValueKey('welcome_scene_size')), matching: find.byType(Stack)),
      );

      expect(
        stack.children.map((child) {
          final boundary = (child as Positioned).child as RepaintBoundary;
          return boundary.child!.key;
        }).toList(),
        [
          for (final slot in WelcomeViewTestHelpers.artworkSlots) ValueKey('welcome_artwork_$slot'),
          const ValueKey('welcome_card_float'),
        ],
      );
    });
  });

  group('WelcomeView scene choreography', () {
    testWidgets('when welcome opens, artworks should wait until their configured entrance delay', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      final initialState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      final cardRect = tester.getRect(find.byKey(const ValueKey('welcome_job_0')));
      final allArtworkCentersStartBehindCard = WelcomeViewTestHelpers.artworkSlots.every(
        (slot) => cardRect.contains(tester.getCenter(find.byKey(ValueKey('welcome_artwork_circle_$slot')))),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 149));
      final beforeDelayState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await tester.pump(const Duration(milliseconds: 1));
      final atDelayState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      final sceneOpacityAtReveal = WelcomeViewTestHelpers.motionState(tester, 'welcome_scene_entrance').opacity;
      await tester.pump(const Duration(milliseconds: 16));
      final afterDelayState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');

      expect(
        (
          initialScale: initialState.scale,
          initialOpacity: initialState.opacity,
          startsAtCard: initialState.translation != Offset.zero,
          allArtworkCentersStartBehindCard: allArtworkCentersStartBehindCard,
          unchangedBeforeDelay: beforeDelayState == initialState,
          unchangedAtDelayBoundary: atDelayState == initialState,
          sceneIsFadingAtReveal: sceneOpacityAtReveal > 0 && sceneOpacityAtReveal < 1,
          revealStartedAfterDelay: afterDelayState.scale > initialState.scale,
        ),
        (
          initialScale: 0.65,
          initialOpacity: 1.0,
          startsAtCard: true,
          allArtworkCentersStartBehindCard: true,
          unchangedBeforeDelay: true,
          unchangedAtDelayBoundary: true,
          sceneIsFadingAtReveal: true,
          revealStartedAfterDelay: true,
        ),
      );
    });

    testWidgets('when the first reveal starts, artworks should reach their positions in exactly 600ms', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 1750));
      await tester.pump(const Duration(milliseconds: 599));
      final beforeCompletion = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await tester.pump(const Duration(milliseconds: 1));
      final atCompletion = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');

      expect(
        (
          incompleteScale: beforeCompletion.scale < 1,
          incompleteTravel: beforeCompletion.translation != Offset.zero,
          finalScale: atCompletion.scale,
          finalTravel: atCompletion.translation,
          opacity: atCompletion.opacity,
        ),
        (incompleteScale: true, incompleteTravel: true, finalScale: 1.0, finalTravel: Offset.zero, opacity: 1.0),
      );
    });

    testWidgets('when the first reveal starts, its return should begin at the 2650ms transition offset', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await tester.pump(const Duration(milliseconds: 2049));
      final beforeReturn = WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_top').effects!;
      final beforeReturnState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await tester.pump(const Duration(milliseconds: 1));
      final atReturn = WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_top').effects!;
      final atReturnState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');

      expect(
        (
          jobBefore: find.byKey(const ValueKey('welcome_job_0')).evaluate().length,
          effectsBefore: beforeReturn.map((effect) => effect.runtimeType).join(','),
          curveBefore: beforeReturn.map((effect) => effect.curve).toSet().single,
          stateBefore: beforeReturnState,
          jobAtBoundary: find.byKey(const ValueKey('welcome_job_0')).evaluate().length,
          effectsAtBoundary: atReturn.map((effect) => effect.runtimeType).join(','),
          curveAtBoundary: atReturn.map((effect) => effect.curve).toSet().single,
          durationAtBoundary: atReturn.map((effect) => effect.duration).toSet().single,
          delayAtBoundary: atReturn.map((effect) => effect.delay).toSet().single,
          stateAtBoundary: atReturnState,
        ),
        (
          jobBefore: 1,
          effectsBefore: 'ScaleInMotionEffect,MoveMotionEffect',
          curveBefore: Curves.easeOutQuint,
          stateBefore: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
          jobAtBoundary: 1,
          effectsAtBoundary: 'ScaleOutMotionEffect,MoveMotionEffect',
          curveAtBoundary: Curves.easeInBack,
          durationAtBoundary: const Duration(milliseconds: 350),
          delayAtBoundary: Duration.zero,
          stateAtBoundary: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
        ),
      );
    });

    testWidgets('when return completes, the next card and artworks should switch together at exactly 350ms', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      final initialArtworkState = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.beginNextReturn(tester);
      await tester.pump(const Duration(milliseconds: 349));
      final oldJobBeforeCompletion = find.byKey(const ValueKey('welcome_job_0')).evaluate().length;
      final beforeCompletion = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await tester.pump(const Duration(milliseconds: 1));
      final oldJobAtCompletionFrame = find.byKey(const ValueKey('welcome_job_0')).evaluate().length;
      await tester.pump();
      final nextArtworkKeysMounted = WelcomeViewTestHelpers.artworkSlots.every(
        (slot) => find.byKey(ValueKey('welcome_artwork_content_1_$slot')).evaluate().length == 1,
      );

      expect(
        (
          oldJobBeforeCompletion: oldJobBeforeCompletion,
          returnNearlyHidden: beforeCompletion.scale < 0.7,
          oldJobAtCompletionFrame: oldJobAtCompletionFrame,
          nextJobAfterRebuild: find.byKey(const ValueKey('welcome_job_1')).evaluate().length,
          nextArtworkKeysMounted: nextArtworkKeysMounted,
          artworkRevealMatchesInitial:
              WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top') == initialArtworkState,
          cardRevealStart: WelcomeViewTestHelpers.motionState(tester, 'welcome_card_transition'),
        ),
        (
          oldJobBeforeCompletion: 1,
          returnNearlyHidden: true,
          oldJobAtCompletionFrame: 1,
          nextJobAfterRebuild: 1,
          nextArtworkKeysMounted: true,
          artworkRevealMatchesInitial: true,
          cardRevealStart: (opacity: 1.0, scale: 0.9, translation: Offset.zero),
        ),
      );
    });

    testWidgets('when motion is enabled, completed card switches should stay exactly three seconds apart', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.beginNextReturn(tester);
      await WelcomeViewTestHelpers.finishNextReturn(tester);
      final firstSwitch = find.byKey(const ValueKey('welcome_job_1')).evaluate().length;
      await WelcomeViewTestHelpers.finishNextReveal(tester);
      await tester.pump(const Duration(milliseconds: 2049));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 349));
      final jobBeforeThreeSeconds = find.byKey(const ValueKey('welcome_job_1')).evaluate().length;
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(
        (
          firstSwitch: firstSwitch,
          jobBeforeThreeSeconds: jobBeforeThreeSeconds,
          jobAtThreeSeconds: find.byKey(const ValueKey('welcome_job_2')).evaluate().length,
        ),
        (firstSwitch: 1, jobBeforeThreeSeconds: 1, jobAtThreeSeconds: 1),
      );
    });

    testWidgets('when a job changes, its card and artworks should scale in both directions without fading', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.beginNextReturn(tester);
      await tester.pump(const Duration(milliseconds: 175));
      final artworkDuringReturn = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      final cardDuringReturn = WelcomeViewTestHelpers.motionState(tester, 'welcome_card_transition');
      await tester.pump(const Duration(milliseconds: 175));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final artworkDuringReveal = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      final cardDuringReveal = WelcomeViewTestHelpers.motionState(tester, 'welcome_card_transition');
      await tester.pump(const Duration(milliseconds: 300));
      final artworkAfterReveal = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      final cardAfterReveal = WelcomeViewTestHelpers.motionState(tester, 'welcome_card_transition');

      expect(
        (
          artworkReturnScaled: artworkDuringReturn.scale != 1,
          cardReturnScaled: cardDuringReturn.scale != 1,
          returnOpacity: (artworkDuringReturn.opacity, cardDuringReturn.opacity),
          artworkRevealScaled: artworkDuringReveal.scale > 0.65 && artworkDuringReveal.scale < 1,
          cardRevealScaled: cardDuringReveal.scale > 0.9 && cardDuringReveal.scale < 1,
          revealOpacity: (artworkDuringReveal.opacity, cardDuringReveal.opacity),
          artworkFinal: artworkAfterReveal,
          cardFinal: cardAfterReveal,
        ),
        (
          artworkReturnScaled: true,
          cardReturnScaled: true,
          returnOpacity: (1.0, 1.0),
          artworkRevealScaled: true,
          cardRevealScaled: true,
          revealOpacity: (1.0, 1.0),
          artworkFinal: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
          cardFinal: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
        ),
      );
    });

    testWidgets('when a job changes, every travel effect should share the synchronized curves and durations', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      final revealEffects = WelcomeViewTestHelpers.artworkSlots
          .map((slot) => WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_$slot').effects!)
          .toList();
      final revealCardEffect = WelcomeViewTestHelpers.motion(tester, 'welcome_card_transition').effect!;
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.beginNextReturn(tester);
      final returnEffects = WelcomeViewTestHelpers.artworkSlots
          .map((slot) => WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_$slot').effects!)
          .toList();
      final returnCardEffect = WelcomeViewTestHelpers.motion(tester, 'welcome_card_transition').effect!;

      expect(
        (
          reveal: revealEffects.every(
            (effects) =>
                effects.length == 2 &&
                effects.first is ScaleInMotionEffect &&
                effects.last is MoveMotionEffect &&
                effects.every(
                  (effect) =>
                      effect.curve == Curves.easeOutQuint &&
                      effect.duration == const Duration(milliseconds: 600) &&
                      effect.delay == Duration.zero,
                ),
          ),
          returning: returnEffects.every(
            (effects) =>
                effects.length == 2 &&
                effects.first is ScaleOutMotionEffect &&
                effects.last is MoveMotionEffect &&
                effects.every(
                  (effect) =>
                      effect.curve == Curves.easeInBack &&
                      effect.duration == const Duration(milliseconds: 350) &&
                      effect.delay == Duration.zero,
                ),
          ),
          revealCardEffect: revealCardEffect.runtimeType,
          returnCardEffect: returnCardEffect.runtimeType,
        ),
        (reveal: true, returning: true, revealCardEffect: ScaleInMotionEffect, returnCardEffect: ScaleOutMotionEffect),
      );
    });

    testWidgets('when job artwork changes, floating, transition, and circle elements should remain mounted', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final stableKeys = [
        'welcome_card_float',
        'welcome_card_transition',
        for (final slot in WelcomeViewTestHelpers.artworkSlots) ...[
          'welcome_artwork_$slot',
          'welcome_artwork_transition_$slot',
          'welcome_artwork_circle_$slot',
        ],
      ];
      final previousElements = WelcomeViewTestHelpers.mountedElements(tester, stableKeys);
      final previousContent = find.byKey(const ValueKey('welcome_artwork_content_0_top')).evaluate().single;
      await WelcomeViewTestHelpers.advanceToNextReducedMotionJob(tester);

      expect(
        (
          stableElements: WelcomeViewTestHelpers.elementsAreIdentical(tester, previousElements),
          contentChanged: !identical(
            previousContent,
            find.byKey(const ValueKey('welcome_artwork_content_1_top')).evaluate().single,
          ),
        ),
        (stableElements: true, contentChanged: true),
      );
    });

    testWidgets('when artwork changes, its circle color should animate throughout the 600ms reveal', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      final circleFinder = find.byKey(const ValueKey('welcome_artwork_circle_top'));
      final palette = tester.element(circleFinder).mateo.palette;
      final initialColor = WelcomeViewTestHelpers.artworkCircleColor(tester, 'top');
      await WelcomeViewTestHelpers.beginNextReturn(tester);
      await WelcomeViewTestHelpers.finishNextReturn(tester);
      final colorAtSwitch = WelcomeViewTestHelpers.artworkCircleColor(tester, 'top');
      await tester.pump(const Duration(milliseconds: 300));
      final middleColor = WelcomeViewTestHelpers.artworkCircleColor(tester, 'top');
      await tester.pump(const Duration(milliseconds: 300));
      final finalColor = WelcomeViewTestHelpers.artworkCircleColor(tester, 'top');

      expect(
        (
          initialColor: initialColor,
          colorAtSwitch: colorAtSwitch,
          middleDiffersFromStart: middleColor != initialColor,
          middleDiffersFromEnd: middleColor != palette.blue[7],
          finalColor: finalColor,
        ),
        (
          initialColor: palette.violet[7],
          colorAtSwitch: palette.violet[7],
          middleDiffersFromStart: true,
          middleDiffersFromEnd: true,
          finalColor: palette.blue[7],
        ),
      );
    });

    testWidgets('when motion is enabled, the card and every artwork should float independently', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      final floatingKeys = [
        'welcome_card_float',
        for (final slot in WelcomeViewTestHelpers.artworkSlots) 'welcome_artwork_$slot',
      ];
      final initialTranslations = {
        for (final key in floatingKeys) key: WelcomeViewTestHelpers.motionState(tester, key).translation,
      };
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        floatingKeys.every(
          (key) => WelcomeViewTestHelpers.motionState(tester, key).translation != initialTranslations[key],
        ),
        isTrue,
      );
    });

    testWidgets('when reduced motion is enabled, all scene motion should stay at its static endpoint', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final floatingKeys = [
        'welcome_card_float',
        for (final slot in WelcomeViewTestHelpers.artworkSlots) 'welcome_artwork_$slot',
      ];
      final initialFloatingStates = {
        for (final key in floatingKeys) key: WelcomeViewTestHelpers.motionState(tester, key),
      };
      await tester.pump(const Duration(milliseconds: 650));

      expect(
        (
          floatingStill: floatingKeys.every(
            (key) => WelcomeViewTestHelpers.motionState(tester, key) == initialFloatingStates[key],
          ),
          artworkTransitionsAtEndpoint: WelcomeViewTestHelpers.artworkSlots.every((slot) {
            final state = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_$slot');
            return state.opacity == 1 && state.scale == 1 && state.translation.distance < 0.001;
          }),
          cardTransitionAtEndpoint: () {
            final state = WelcomeViewTestHelpers.motionState(tester, 'welcome_card_transition');
            return state.opacity == 1 && state.scale == 1 && state.translation.distance < 0.001;
          }(),
        ),
        (floatingStill: true, artworkTransitionsAtEndpoint: true, cardTransitionAtEndpoint: true),
      );
    });

    testWidgets('when reduced motion is enabled, the next job should replace the current one at three seconds', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final palette = tester.element(find.byKey(const ValueKey('welcome_artwork_circle_top'))).mateo.palette;
      await tester.pump(const Duration(milliseconds: 2999));
      final titleBeforeBoundary = tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data;
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        (
          titleBeforeBoundary: titleBeforeBoundary,
          titleAtBoundary: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data,
          artworkAtEndpoint: WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top'),
          circleColorAtBoundary: WelcomeViewTestHelpers.artworkCircleColor(tester, 'top'),
        ),
        (
          titleBeforeBoundary: i18n.welcome.jobs.job1.title,
          titleAtBoundary: i18n.welcome.jobs.job2.title,
          artworkAtEndpoint: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
          circleColorAtBoundary: palette.blue[7],
        ),
      );
    });

    testWidgets('when reduced motion is enabled during the initial hold, artwork should settle before a 3s switch', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(seconds: 1));
      final artworkKeys = [for (final slot in WelcomeViewTestHelpers.artworkSlots) 'welcome_artwork_transition_$slot'];
      final heldArtwork = WelcomeViewTestHelpers.motionState(tester, artworkKeys.first);
      final mountedArtwork = WelcomeViewTestHelpers.mountedElements(tester, artworkKeys);
      await WelcomeViewTestHelpers.repumpView(tester: tester);
      final settledArtwork = WelcomeViewTestHelpers.artworkSlots.every((slot) {
        final state = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_$slot');
        return state.opacity == 1 && state.scale == 1 && state.translation.distance < 0.001;
      });
      await tester.pump(const Duration(milliseconds: 2999));
      final titleBeforeBoundary = tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data;
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        (
          artworkWasHeld: heldArtwork.scale == 0.65 && heldArtwork.translation != Offset.zero,
          artworkStayedMounted: WelcomeViewTestHelpers.elementsAreIdentical(tester, mountedArtwork),
          artworkSettled: settledArtwork,
          titleBeforeBoundary: titleBeforeBoundary,
          titleAtBoundary: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data,
        ),
        (
          artworkWasHeld: true,
          artworkStayedMounted: true,
          artworkSettled: true,
          titleBeforeBoundary: i18n.welcome.jobs.job1.title,
          titleAtBoundary: i18n.welcome.jobs.job2.title,
        ),
      );
    });

    testWidgets('when reduced motion changes while idle, each new cadence should still switch at three seconds', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.repumpView(tester: tester);
      await tester.pump(const Duration(milliseconds: 2999));
      final firstJobBeforeReducedBoundary = find.byKey(const ValueKey('welcome_job_0')).evaluate().length;
      await tester.pump(const Duration(milliseconds: 1));
      final reducedSwitchAtBoundary = find.byKey(const ValueKey('welcome_job_1')).evaluate().length;
      await WelcomeViewTestHelpers.repumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 2649));
      final effectBeforeReturn = WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_top').effects!.first;
      await tester.pump(const Duration(milliseconds: 1));
      final effectAtReturn = WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_top').effects!.first;
      await tester.pump(const Duration(milliseconds: 349));
      final secondJobBeforeAnimatedBoundary = find.byKey(const ValueKey('welcome_job_1')).evaluate().length;
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(
        (
          firstJobBeforeReducedBoundary: firstJobBeforeReducedBoundary,
          reducedSwitchAtBoundary: reducedSwitchAtBoundary,
          curveBeforeReturn: effectBeforeReturn.curve,
          curveAtReturn: effectAtReturn.curve,
          secondJobBeforeAnimatedBoundary: secondJobBeforeAnimatedBoundary,
          animatedSwitchAtBoundary: find.byKey(const ValueKey('welcome_job_2')).evaluate().length,
        ),
        (
          firstJobBeforeReducedBoundary: 1,
          reducedSwitchAtBoundary: 1,
          curveBeforeReturn: Curves.easeOutQuint,
          curveAtReturn: Curves.easeInBack,
          secondJobBeforeAnimatedBoundary: 1,
          animatedSwitchAtBoundary: 1,
        ),
      );
    });

    testWidgets('when TickerMode pauses the initial reveal, return should wait 2050ms after reveal completion', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      final stateBeforePause = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await WelcomeViewTestHelpers.repumpView(tester: tester, disableAnimations: false, tickerModeEnabled: false);
      await tester.pump(const Duration(seconds: 3));
      await WelcomeViewTestHelpers.repumpView(tester: tester, disableAnimations: false);
      await tester.pump();
      final effectAfterResume = WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_top').effects!.first;
      final stateAfterResume = WelcomeViewTestHelpers.motionState(tester, 'welcome_artwork_transition_top');
      await tester.pump(const Duration(milliseconds: 2049));
      final effectBeforeIdleDwell = WelcomeViewTestHelpers.motion(
        tester,
        'welcome_artwork_transition_top',
      ).effects!.first;
      await tester.pump(const Duration(milliseconds: 1));
      final effectAtIdleDwell = WelcomeViewTestHelpers.motion(tester, 'welcome_artwork_transition_top').effects!.first;

      expect(
        (
          revealWasInProgress: stateBeforePause.scale > 0.65 && stateBeforePause.scale < 1,
          revealCompletedOnResume: stateAfterResume,
          stillRevealingAfterResume: effectAfterResume.curve,
          stillIdleBeforeDwell: effectBeforeIdleDwell.curve,
          returningAtDwell: effectAtIdleDwell.curve,
          currentJob: tester.widget<Text>(find.byKey(const ValueKey('welcome_job_title'))).data,
        ),
        (
          revealWasInProgress: true,
          revealCompletedOnResume: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
          stillRevealingAfterResume: Curves.easeOutQuint,
          stillIdleBeforeDwell: Curves.easeOutQuint,
          returningAtDwell: Curves.easeInBack,
          currentJob: i18n.welcome.jobs.job1.title,
        ),
      );
    });

    testWidgets('when artworks return, the back curve should briefly carry edge artwork outside the scene', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.beginNextReturn(tester);
      const tolerance = 0.001;
      var edgeArtworkLeftScene = false;

      for (var frame = 0; frame < 22; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        final sceneRect = tester.getRect(find.byKey(const ValueKey('welcome_scene_size')));
        for (final slot in ['rightTopCorner', 'leftBottomCorner', 'rightBottomCorner']) {
          final artworkRect = tester.getRect(find.byKey(ValueKey('welcome_artwork_circle_$slot')));
          edgeArtworkLeftScene =
              edgeArtworkLeftScene ||
              artworkRect.left < sceneRect.left - tolerance ||
              artworkRect.right > sceneRect.right + tolerance;
        }
      }

      expect(edgeArtworkLeftScene, isTrue);
    });

    testWidgets('when welcome is disposed after a rotation, all scene timers should stop cleanly', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await WelcomeViewTestHelpers.finishInitialReveal(tester);
      await WelcomeViewTestHelpers.advanceToNextAnimatedJob(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 4));

      expect(
        (exception: tester.takeException(), scheduledFrame: tester.binding.hasScheduledFrame),
        (exception: null, scheduledFrame: false),
      );
    });
  });

  group('WelcomeView entrance choreography', () {
    testWidgets('when welcome builds, entrance effects should encode the complete ordered timeline', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      final titleEffects = WelcomeViewTestHelpers.motion(tester, 'welcome_message_entrance').effects!;
      final move = titleEffects.whereType<MoveMotionEffect>().single;
      final scale = titleEffects.whereType<ScaleInMotionEffect>().single;
      final fade = titleEffects.whereType<FadeInMotionEffect>().single;
      final scene = WelcomeViewTestHelpers.motion(tester, 'welcome_scene_entrance').effect!;
      final termsEffects = WelcomeViewTestHelpers.motion(tester, 'welcome_terms_entrance').effects!;
      final termsMove = termsEffects.whereType<MoveMotionEffect>().single;
      final termsFade = termsEffects.whereType<FadeInMotionEffect>().single;
      final buttonEffects = WelcomeViewTestHelpers.motion(tester, 'welcome_button_entrance').effects!;
      final buttonMove = buttonEffects.whereType<MoveMotionEffect>().single;
      final buttonFade = buttonEffects.whereType<FadeInMotionEffect>().single;

      expect(
        (
          titleMove: (move.begin, move.end, move.delay, move.duration, move.curve),
          titleScale: (scale.scale, scale.delay, scale.duration, scale.curve),
          titleFade: (fade.delay, fade.duration, fade.curve),
          scene: (scene.delay, scene.duration, scene.curve),
          termsMove: (termsMove.begin, termsMove.end, termsMove.delay, termsMove.duration, termsMove.curve),
          termsFade: (termsFade.delay, termsFade.duration, termsFade.curve),
          buttonMove: (buttonMove.begin, buttonMove.end, buttonMove.delay, buttonMove.duration, buttonMove.curve),
          buttonFade: (buttonFade.delay, buttonFade.duration, buttonFade.curve),
        ),
        (
          titleMove: (
            Offset(
              0,
              422 -
                  (tester.getBottomRight(find.byKey(const ValueKey('welcome_scene_size'))).dy +
                          tester.getTopLeft(find.byKey(const ValueKey('welcome_start_button'))).dy -
                          20) /
                      2,
            ),
            Offset.zero,
            const Duration(milliseconds: 1100),
            const Duration(milliseconds: 500),
            Curves.easeInOutCubic,
          ),
          titleScale: (1.12, const Duration(milliseconds: 600), const Duration(milliseconds: 500), Curves.easeOutCubic),
          titleFade: (const Duration(milliseconds: 600), const Duration(milliseconds: 500), Curves.easeOutCubic),
          scene: (const Duration(milliseconds: 1600), const Duration(milliseconds: 600), Curves.easeOutCubic),
          termsMove: (
            const Offset(0, 20),
            Offset.zero,
            const Duration(milliseconds: 1850),
            const Duration(milliseconds: 500),
            Curves.easeOutCubic,
          ),
          termsFade: (const Duration(milliseconds: 1850), const Duration(milliseconds: 500), Curves.easeOutCubic),
          buttonMove: (
            const Offset(0, 20),
            Offset.zero,
            const Duration(milliseconds: 1850),
            const Duration(milliseconds: 500),
            Curves.easeOutCubic,
          ),
          buttonFade: (const Duration(milliseconds: 1850), const Duration(milliseconds: 500), Curves.easeOutCubic),
        ),
      );
    });

    testWidgets('when welcome enters, the title should fade and scale before moving smoothly into place', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(
        tester: tester,
        padding: const EdgeInsets.only(top: 59, bottom: 34),
        disableAnimations: false,
      );
      final initialTranslation = Offset(
        0,
        422 -
            (tester.getBottomRight(find.byKey(const ValueKey('welcome_scene_size'))).dy +
                    tester.getTopLeft(find.byKey(const ValueKey('welcome_start_button'))).dy -
                    20) /
                2,
      );
      final initial = WelcomeViewTestHelpers.motionState(tester, 'welcome_message_entrance');
      final initialTitleCenter = tester.getCenter(find.byKey(const ValueKey('welcome_message'))).dy;
      await tester.pump(const Duration(milliseconds: 599));
      final beforeReveal = WelcomeViewTestHelpers.motionState(tester, 'welcome_message_entrance');
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      final beforeMove = WelcomeViewTestHelpers.motionState(tester, 'welcome_message_entrance');
      await tester.pump(const Duration(milliseconds: 250));
      final duringMove = WelcomeViewTestHelpers.motionState(tester, 'welcome_message_entrance');
      await tester.pump(const Duration(milliseconds: 250));
      final completed = WelcomeViewTestHelpers.motionState(tester, 'welcome_message_entrance');

      expect(
        (
          initialOpacity: initial.opacity,
          initialScale: (initial.scale - 1.12).abs() < 0.001,
          initialTranslation: (initial.translation - initialTranslation).distance < 0.001,
          initialTitleCenter: initialTitleCenter,
          heldFor599ms: beforeReveal == initial,
          revealedOpacity: (beforeMove.opacity - 1).abs() < 0.001,
          revealedScale: (beforeMove.scale - 1).abs() < 0.001,
          heldBeforeMove: (beforeMove.translation - initialTranslation).distance < 0.001,
          moving: duringMove.translation.dy > initialTranslation.dy && duringMove.translation.dy < 0,
          completedOpacity: (completed.opacity - 1).abs() < 0.001,
          completedScale: (completed.scale - 1).abs() < 0.001,
          completedTranslation: completed.translation.distance < 0.001,
        ),
        (
          initialOpacity: 0.0,
          initialScale: true,
          initialTranslation: true,
          initialTitleCenter: 422.0,
          heldFor599ms: true,
          revealedOpacity: true,
          revealedScale: true,
          heldBeforeMove: true,
          moving: true,
          completedOpacity: true,
          completedScale: true,
          completedTranslation: true,
        ),
      );
    });

    testWidgets('when artwork settles, the controls should move up and fade in together', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 249));
      final beforeControls = (
        terms: WelcomeViewTestHelpers.motionState(tester, 'welcome_terms_entrance'),
        button: WelcomeViewTestHelpers.motionState(tester, 'welcome_button_entrance'),
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      final duringControls = (
        terms: WelcomeViewTestHelpers.motionState(tester, 'welcome_terms_entrance'),
        button: WelcomeViewTestHelpers.motionState(tester, 'welcome_button_entrance'),
      );
      await tester.pump(const Duration(milliseconds: 250));
      final afterControls = (
        terms: WelcomeViewTestHelpers.motionState(tester, 'welcome_terms_entrance'),
        button: WelcomeViewTestHelpers.motionState(tester, 'welcome_button_entrance'),
      );

      expect(
        (
          beforeControls: beforeControls,
          termsMoveDuring: duringControls.terms.translation.dy > 0 && duringControls.terms.translation.dy < 20,
          termsFadeDuring: duringControls.terms.opacity > 0 && duringControls.terms.opacity < 1,
          buttonMoveDuring: duringControls.button.translation.dy > 0 && duringControls.button.translation.dy < 20,
          buttonFadeDuring: duringControls.button.opacity > 0 && duringControls.button.opacity < 1,
          afterControls: afterControls,
        ),
        (
          beforeControls: (
            terms: (opacity: 0.0, scale: 1.0, translation: const Offset(0, 20)),
            button: (opacity: 0.0, scale: 1.0, translation: const Offset(0, 20)),
          ),
          termsMoveDuring: true,
          termsFadeDuring: true,
          buttonMoveDuring: true,
          buttonFadeDuring: true,
          afterControls: (
            terms: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
            button: (opacity: 1.0, scale: 1.0, translation: Offset.zero),
          ),
        ),
      );
    });
  });

  group('WelcomeView accessibility and controls', () {
    testWidgets('when controls fade in, semantics should stay hidden until each fade completes', (tester) async {
      final semantics = tester.ensureSemantics();
      await WelcomeViewTestHelpers.pumpView(tester: tester, disableAnimations: false);
      final termsLabel = '${i18n.welcome.terms.prefix} ${i18n.welcome.terms.link}';
      final initial = (
        terms: find.bySemanticsLabel(termsLabel).evaluate().length,
        button: find.bySemanticsLabel(i18n.welcome.startButton).evaluate().length,
      );
      await tester.pump(const Duration(milliseconds: 1850));
      final beforeControlsStart = (
        terms: find.bySemanticsLabel(termsLabel).evaluate().length,
        button: find.bySemanticsLabel(i18n.welcome.startButton).evaluate().length,
      );
      await tester.pump(const Duration(milliseconds: 499));
      final beforeControlsCompletion = (
        terms: find.bySemanticsLabel(termsLabel).evaluate().length,
        button: find.bySemanticsLabel(i18n.welcome.startButton).evaluate().length,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      final afterControlsCompletion = (
        terms: find.bySemanticsLabel(termsLabel).evaluate().length,
        button: find.bySemanticsLabel(i18n.welcome.startButton).evaluate().length,
      );
      semantics.dispose();

      expect(
        (
          initial: initial,
          beforeControlsStart: beforeControlsStart,
          beforeControlsCompletion: beforeControlsCompletion,
          afterControlsCompletion: afterControlsCompletion,
        ),
        (
          initial: (terms: 0, button: 0),
          beforeControlsStart: (terms: 0, button: 0),
          beforeControlsCompletion: (terms: 0, button: 0),
          afterControlsCompletion: (terms: 1, button: 1),
        ),
      );
    });

    testWidgets('when welcome opens, the scene should be exposed as one localized accessible image', (tester) async {
      final semantics = tester.ensureSemantics();
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final sceneData = tester.getSemantics(find.byKey(const ValueKey('welcome_job_scene'))).getSemanticsData();
      semantics.dispose();

      expect(
        (
          label: sceneData.label,
          isImage: sceneData.flagsCollection.isImage,
          headlineIsHeader: tester
              .getSemantics(find.byKey(const ValueKey('welcome_headline')))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          nestedJobSemantics: find.bySemanticsLabel(i18n.welcome.jobs.job1.title).evaluate().length,
        ),
        (label: i18n.welcome.sceneAccessibilityLabel, isImage: true, headlineIsHeader: true, nestedJobSemantics: 0),
      );
    });

    testWidgets('when welcome opens, controls should remain active accessible touch targets', (tester) async {
      final semantics = tester.ensureSemantics();
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final startFinder = find.byKey(const ValueKey('welcome_start_button'));
      final termsFinder = find.byKey(const ValueKey('welcome_terms_button'));
      final startData = tester.getSemantics(startFinder).getSemanticsData();
      final termsData = tester.getSemantics(termsFinder).getSemanticsData();
      semantics.dispose();

      expect(
        (
          startCallback: tester.widget<MateoMenuButton>(startFinder).actions.any((action) => action.onPressed != null),
          startSemantics: (
            startData.flagsCollection.isButton,
            startData.flagsCollection.isEnabled,
            startData.hasAction(SemanticsAction.tap),
          ),
          startHeight: tester.getSize(startFinder).height >= 48,
          termsCallback: tester.widget<MateoTap>(termsFinder).onPressed != null,
          termsSemantics: (
            termsData.flagsCollection.isButton,
            termsData.flagsCollection.isEnabled,
            termsData.hasAction(SemanticsAction.tap),
          ),
        ),
        (
          startCallback: true,
          startSemantics: (true, Tristate.isTrue, true),
          startHeight: true,
          termsCallback: true,
          termsSemantics: (true, Tristate.isTrue, true),
        ),
      );
    });
  });

  group('WelcomeView responsive layout', () {
    for (final scenario in [
      (name: '390x844 reference phone', width: 390.0, height: 844.0, padding: EdgeInsets.zero),
      (
        name: '360x640 compact phone with safe-area insets',
        width: 360.0,
        height: 640.0,
        padding: const EdgeInsets.only(top: 24, bottom: 24),
      ),
      (name: '600-wide layout', width: 600.0, height: 844.0, padding: EdgeInsets.zero),
      (name: '320x568 small phone', width: 320.0, height: 568.0, padding: EdgeInsets.zero),
    ]) {
      testWidgets('when welcome opens on ${scenario.name}, it should fit without scrolling', (tester) async {
        await WelcomeViewTestHelpers.pumpView(
          tester: tester,
          width: scenario.width,
          height: scenario.height,
          padding: scenario.padding,
        );

        expect(WelcomeViewTestHelpers.layoutState(tester, width: scenario.width, height: scenario.height), (
          exception: null,
          hasScrollable: false,
          contentFits: true,
        ));
      });
    }

    testWidgets('when the device has a top safe-area inset, the scene should remain below it', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, padding: const EdgeInsets.only(top: 59, bottom: 34));

      expect(tester.getTopLeft(find.byKey(const ValueKey('welcome_scene_size'))).dy, greaterThanOrEqualTo(59));
    });

    testWidgets('when text scaling is large, the fixed composition should still fit without scrolling', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, textScaler: const TextScaler.linear(2));

      expect(WelcomeViewTestHelpers.layoutState(tester, width: 390, height: 844), (
        exception: null,
        hasScrollable: false,
        contentFits: true,
      ));
    });

    testWidgets('when accessibility text scaling changes, welcome typography should keep its screen-derived size', (
      tester,
    ) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final normalHeadlineSize = tester.getRect(find.byKey(const ValueKey('welcome_headline'))).size;
      final normalSubtitleSize = tester.getRect(find.byKey(const ValueKey('welcome_subtitle'))).size;
      await WelcomeViewTestHelpers.pumpView(tester: tester, textScaler: const TextScaler.linear(2));

      expect(
        (
          headline: tester.getRect(find.byKey(const ValueKey('welcome_headline'))).size,
          subtitle: tester.getRect(find.byKey(const ValueKey('welcome_subtitle'))).size,
        ),
        (headline: normalHeadlineSize, subtitle: normalSubtitleSize),
      );
    });

    testWidgets('when width changes, scene and title should scale down only below their maximum size', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester, width: 320, height: 568);
      final smallScene = tester.getRect(find.byKey(const ValueKey('welcome_scene_size'))).size;
      final smallHeadline = tester.getRect(find.byKey(const ValueKey('welcome_headline'))).size;
      await WelcomeViewTestHelpers.pumpView(tester: tester, width: 390, height: 844);
      final referenceScene = tester.getRect(find.byKey(const ValueKey('welcome_scene_size'))).size;
      final referenceHeadline = tester.getRect(find.byKey(const ValueKey('welcome_headline'))).size;
      await WelcomeViewTestHelpers.pumpView(tester: tester, width: 600, height: 844);
      final wideScene = tester.getRect(find.byKey(const ValueKey('welcome_scene_size'))).size;
      final wideHeadline = tester.getRect(find.byKey(const ValueKey('welcome_headline'))).size;

      expect(
        (
          smallSceneIsScaled: smallScene.height < referenceScene.height,
          smallTitleIsScaled: smallHeadline.height < referenceHeadline.height,
          wideSceneUsesMaximum: wideScene,
          wideTitleUsesMaximum: wideHeadline,
        ),
        (
          smallSceneIsScaled: true,
          smallTitleIsScaled: true,
          wideSceneUsesMaximum: referenceScene,
          wideTitleUsesMaximum: referenceHeadline,
        ),
      );
    });

    testWidgets('when welcome lays out, the message should stay centered between the scene and button', (tester) async {
      await WelcomeViewTestHelpers.pumpView(tester: tester);
      final spaceAboveMessage =
          tester.getTopLeft(find.byKey(const ValueKey('welcome_message'))).dy -
          tester.getBottomRight(find.byKey(const ValueKey('welcome_scene_size'))).dy;
      final spaceBelowMessage =
          tester.getTopLeft(find.byKey(const ValueKey('welcome_start_button'))).dy -
          tester.getBottomRight(find.byKey(const ValueKey('welcome_message'))).dy;

      expect(spaceAboveMessage, closeTo(spaceBelowMessage, 0.001));
    });
  });
}
