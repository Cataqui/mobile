import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import 'poster_onboarding_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  testWidgets('when a poster job card opens, it should inset its details by eight pixels', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester);
    final inset = tester.widget<Padding>(find.byKey(const ValueKey('poster_onboarding_waiter_job_inset')));

    expect(inset.padding, const EdgeInsets.all(8));
  });

  testWidgets('when a poster job card opens, its details should follow the map corner curve', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester);
    final decoration =
        tester.widget<DecoratedBox>(find.byKey(const ValueKey('poster_onboarding_waiter_job_card'))).decoration
            as BoxDecoration;

    expect((decoration.borderRadius! as BorderRadius).topLeft.x, 26);
  });

  testWidgets('when a poster job card opens, it should format its localized daily payment', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester);
    final amount = num.parse(i18n.posterOnboarding.jobs.waiter.amount);
    final expectedPayment = JobPaymentDto(
      type: JobPaymentType.fixed,
      minAmount: amount,
      maxAmount: amount,
      amountPeriod: JobPaymentAmountPeriod.daily,
      currency: i18n.posterOnboarding.jobCard.currencyCode,
      note: '',
    ).formatPayment(i18n);

    expect(find.text(expectedPayment), findsOneWidget);
  });

  testWidgets('when a poster job card meets the page, it should fade its map into the background', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester);
    final decoration =
        tester.widget<DecoratedBox>(find.byKey(const ValueKey('poster_onboarding_waiter_job_fade'))).decoration
            as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(
      (firstAlpha: gradient.colors.first.a, lastAlpha: gradient.colors.last.a, stops: gradient.stops),
      (firstAlpha: 0.0, lastAlpha: 1.0, stops: const [0.0, 0.9]),
    );
  });

  testWidgets('when a person responds to a job, the interest bubble should use primary palette step nine', (
    tester,
  ) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester);
    final decoration =
        tester
                .widget<DecoratedBox>(find.byKey(const ValueKey('poster_onboarding_waiter_job_interest_bubble')))
                .decoration
            as BoxDecoration;
    final expectedColor = tester.element(find.byType(PosterOnboardingJobCard).first).mateo.palette.primary[9];

    expect(decoration.color, expectedColor);
  });

  testWidgets('when a person responds to a job, it should keep twenty pixels below the map', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester);

    expect(tester.getSize(find.byKey(const ValueKey('poster_onboarding_waiter_job_interest_spacing'))).height, 20);
  });

  testWidgets('when card text is enlarged, the card should render without a layout exception', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpJobCard(tester: tester, textScaler: 2);

    expect(tester.takeException(), isNull);
  });
}
