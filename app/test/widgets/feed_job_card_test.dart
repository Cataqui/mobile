import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/dtos/map_config_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../utils/test_app.dart';
import '../views/job/job_view_test_helpers.dart';

FeedJobDto _fixture({JobPaymentDto? payment, String? title, String? descriptionSummary}) {
  return FeedJobDto(
    jobId: 'job_123',
    title: title ?? 'Garçom para Fim de Semana',
    createdAt: DateTime(2025, 6, 15),
    payment:
        payment ??
        const JobPaymentDto(
          type: JobPaymentType.fixed,
          minAmount: 120,
          maxAmount: 200,
          amountPeriod: JobPaymentAmountPeriod.daily,
          currency: 'BRL',
          note: '',
        ),
    location: FeedJobLocationDto(
      neighborhood: 'Pinheiros',
      latitude: -23.556391,
      longitude: -46.844076,
      areaRadius: 2000,
      mapConfig: MapConfigDto.fixture(),
    ),
    descriptionSummary: descriptionSummary ?? 'Experiente em atendimento ao cliente.',
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(child: TestApp(child: child));
}

/// Runs [body] with a fixed clock for deterministic timestamp rendering.
Future<void> _withFixedClock(Clock fixedClock, Future<void> Function() body) async {
  await withClock(fixedClock, body);
}

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedJobCard', () {
    group('rendering', () {
      testWidgets('when created with a job, it should display the title', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        expect(find.text('Garçom para Fim de Semana'), findsOneWidget);
      });

      testWidgets('when created with a job, it should display the payment', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        expect(find.textContaining(r'R$'), findsOneWidget);
        expect(find.textContaining('120'), findsOneWidget);
        expect(find.textContaining(i18n.jobPayment.paymentPeriodDaily), findsOneWidget);
      });

      testWidgets('when created with a job, it should display the description', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        expect(find.text('Experiente em atendimento ao cliente.'), findsOneWidget);
      });

      testWidgets('when created, the card should have 38px border radius', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);

        expect((decoratedBox.decoration as BoxDecoration).borderRadius, equals(BorderRadius.circular(38)));
      });

      testWidgets('when created, the title should use semi-bold weight', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.style!.fontWeight, equals(FontWeight.w600));
      });

      testWidgets('when created, the title should use 22px font size', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.style!.fontSize, equals(22));
      });

      testWidgets('when created, the payment should use 25px font size', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final paymentText = find.textContaining(r'R$');
        final text = tester.widget<Text>(paymentText);

        expect(text.style!.fontSize, equals(25));
      });

      testWidgets('when created, the payment should use the accessible pay text color', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final paymentText = find.textContaining(r'R$');
        final text = tester.widget<Text>(paymentText);

        expect(text.style!.color, equals(MateoColorScheme.light().text.profit));
      });

      testWidgets('when created, the description should use 15.7px font size', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.style!.fontSize, equals(16));
      });

      testWidgets('when created, the description should use secondary text color', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));
        final context = tester.element(find.byType(FeedJobCard));

        expect(text.style!.color, equals(context.mateo.colorScheme.text.secondary));
      });

      testWidgets('when created, the title should be limited to 2 lines', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.maxLines, equals(2));
      });

      testWidgets('when created, the title should use ellipsis overflow', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('when created, the description should be limited to 3 lines', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.maxLines, equals(3));
      });

      testWidgets('when created, the description should use ellipsis overflow', (tester) async {
        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture())));

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.overflow, equals(TextOverflow.ellipsis));
      });
    });

    group('timestamp', () {
      testWidgets('when createdAt is 20h before now, it should display 20h atrás', (tester) async {
        final createdAt = DateTime(2025, 6, 15, 0);
        final fixedNow = createdAt.add(const Duration(hours: 20));

        await _withFixedClock(Clock(() => fixedNow), () async {
          await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture().copyWith(createdAt: createdAt))));

          expect(find.text(i18n.feedJob.timeAgo.hours(count: 20)), findsOneWidget);
        });
      });

      testWidgets('when createdAt is 1 day before now, it should display 1 dia atrás', (tester) async {
        final createdAt = DateTime(2025, 6, 15);
        final fixedNow = createdAt.add(const Duration(days: 1));

        await _withFixedClock(Clock(() => fixedNow), () async {
          await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture().copyWith(createdAt: createdAt))));

          expect(find.text(i18n.feedJob.timeAgo.days(count: 1)), findsOneWidget);
        });
      });
    });

    group('hero keys', () {
      test('when generating the background hero key, it should return the expected tag format', () {
        expect(FeedJobCard.backgroundHeroKey('job_123'), 'job-job_123-surface');
      });

      test('when generating the header hero key, it should return the expected tag format', () {
        expect(FeedJobCard.headerHeroKey('job_123'), 'job-job_123-header');
      });

      test('when generating hero keys for the same job, the background and header keys should differ', () {
        expect(FeedJobCard.backgroundHeroKey('job_123'), isNot(FeedJobCard.headerHeroKey('job_123')));
      });
    });

    group('cross-widget consistency', () {
      testWidgets('when FeedJobCard and JobView reference the same job, it should use matching hero tags', (
        tester,
      ) async {
        const jobId = 'job_123';

        await tester.pumpWidget(_wrap(FeedJobCard(feedJob: _fixture().copyWith(jobId: jobId))));
        final cardBackgroundTag = tester.widget<MateoHeroBackground>(find.byType(MateoHeroBackground)).tag;
        final cardHeaderTag = tester.widget<MateoHeroGroup>(find.byType(MateoHeroGroup)).tag;

        await tester.pumpWidget(const SizedBox());

        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: JobViewTestHelpers.feedJob(jobId: jobId),
          jobState: JobViewTestHelpers.loadingState(),
        );
        final viewBackgroundTag = tester.widget<MateoHeroBackground>(find.byType(MateoHeroBackground)).tag;
        final viewHeaderTag = tester.widget<MateoHeroGroup>(find.byType(MateoHeroGroup)).tag;

        expect(viewBackgroundTag, equals(cardBackgroundTag));
        expect(viewHeaderTag, equals(cardHeaderTag));
      });
    });
  });
}
