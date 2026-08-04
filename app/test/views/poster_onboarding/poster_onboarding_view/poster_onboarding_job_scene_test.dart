import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'poster_onboarding_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  testWidgets('when the poster job scene opens, it should configure a slow left-moving marquee', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobScene(tester: tester);
    final marquee = tester.widget<Marquee>(find.byKey(const ValueKey('poster_onboarding_job_marquee')));

    expect(
      (duration: marquee.duration, direction: marquee.direction, spacing: marquee.spacing),
      (duration: const Duration(seconds: 30), direction: MarqueeDirection.left, spacing: 10),
    );
  });

  testWidgets('when the poster job scene opens, it should provide all nine unique job examples', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobScene(tester: tester);
    final cards = tester
        .widget<Marquee>(find.byKey(const ValueKey('poster_onboarding_job_marquee')))
        .children
        .whereType<PosterOnboardingJobCard>()
        .toList(growable: false);

    expect(
      (
        count: cards.length,
        keys: cards.map((card) => card.key).toSet().length,
        titles: cards.map((card) => card.title).toSet().length,
        amounts: cards.map((card) => card.localizedAmount).toSet().length,
        descriptions: cards.map((card) => card.description).toSet().length,
        interests: cards.map((card) => card.interestLabel).toSet().length,
      ),
      (count: 9, keys: 9, titles: 9, amounts: 9, descriptions: 9, interests: 9),
    );
  });

  testWidgets('when job examples are tilted, every rotation should remain within five degrees', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobScene(tester: tester);
    final rotations = tester
        .widget<Marquee>(find.byKey(const ValueKey('poster_onboarding_job_marquee')))
        .children
        .whereType<PosterOnboardingJobCard>()
        .map((card) => card.rotationDegrees);

    expect(
      rotations,
      everyElement(
        inInclusiveRange(
          -PosterOnboardingJobCard.maximumRotationDegrees,
          PosterOnboardingJobCard.maximumRotationDegrees,
        ),
      ),
    );
  });

  testWidgets('when reduced motion is enabled, the job marquee should remain stationary', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobScene(tester: tester);
    final waiter = find.byKey(const ValueKey('poster_onboarding_waiter_job_preview')).first;
    final initialPosition = tester.getTopLeft(waiter);
    await tester.pump(const Duration(seconds: 5));

    expect(tester.getTopLeft(waiter), initialPosition);
  });

  testWidgets('when motion is enabled, the job marquee should move the examples over time', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobScene(tester: tester, disableAnimations: false);
    final waiter = find.byKey(const ValueKey('poster_onboarding_waiter_job_preview')).first;
    final initialPosition = tester.getTopLeft(waiter);
    await tester.pump(const Duration(milliseconds: 1500));

    expect(tester.getTopLeft(waiter), isNot(initialPosition));
  });

  testWidgets('when the poster job scene opens, it should expose one localized accessibility summary', (tester) async {
    final semantics = tester.ensureSemantics();
    await PosterOnboardingViewTestHelpers.pumpJobScene(tester: tester);

    try {
      expect(find.bySemanticsLabel(i18n.posterOnboarding.sceneAccessibilityLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
