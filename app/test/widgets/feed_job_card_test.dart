import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../utils/test_app.dart';
import '../views/job/job_view_test_helpers.dart';

class _FeedJobCardTestHelpers {
  _FeedJobCardTestHelpers._();

  static FeedJobDto fixture({JobPaymentDto? payment, String? title, String? descriptionSummary}) {
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
      location: const FeedJobLocationDto(latitude: -23.556391, longitude: -46.844076, areaRadius: 2000),
      descriptionSummary: descriptionSummary ?? 'Experiente em atendimento ao cliente.',
    );
  }

  static Widget wrap(Widget child) {
    return ProviderScope(child: TestApp(child: child));
  }
}

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedJobCard', () {
    group('rendering', () {
      testWidgets('when created with a job, it should display the title', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        expect(find.text('Garçom para Fim de Semana'), findsOneWidget);
      });

      testWidgets('when created with a job, it should display the payment', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        expect(
          (
            find.textContaining(r'R$').evaluate().length,
            find.textContaining('120').evaluate().length,
            find.textContaining(i18n.jobPayment.paymentPeriodDaily).evaluate().length,
          ),
          (1, 1, 1),
        );
      });

      testWidgets('when created with a job, it should display the description', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        expect(find.text('Experiente em atendimento ao cliente.'), findsOneWidget);
      });

      testWidgets('when created, the card should have 38px border radius', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);

        expect((decoratedBox.decoration as BoxDecoration).borderRadius, equals(BorderRadius.circular(38)));
      });

      testWidgets('when created, the title should use semi-bold weight', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.style!.fontWeight, equals(FontWeight.w600));
      });

      testWidgets('when created, the title should use 22px font size', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.style!.fontSize, equals(22));
      });

      testWidgets('when created, the payment should use 26px font size', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final paymentText = find.textContaining(r'R$');
        final text = tester.widget<Text>(paymentText);

        expect(text.style!.fontSize, equals(26));
      });

      testWidgets('when created, the payment should use the accessible pay text color', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final paymentText = find.textContaining(r'R$');
        final text = tester.widget<Text>(paymentText);

        expect(text.style!.color, equals(MateoColorScheme.light().text.profit));
      });

      testWidgets('when created, the description should use 15px font size', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.style!.fontSize, equals(15));
      });

      testWidgets('when created, the description should use secondary text color', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));
        final context = tester.element(find.byType(FeedJobCard));

        expect(text.style!.color, equals(context.mateo.colorScheme.text.secondary));
      });

      testWidgets('when created, the title should be limited to 2 lines', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.maxLines, equals(2));
      });

      testWidgets('when created, the title should use ellipsis overflow', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Garçom para Fim de Semana'));

        expect(text.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('when created, the description should be limited to 3 lines', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.maxLines, equals(3));
      });

      testWidgets('when created, the description should use ellipsis overflow', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final text = tester.widget<Text>(find.text('Experiente em atendimento ao cliente.'));

        expect(text.overflow, equals(TextOverflow.ellipsis));
      });
    });

    group('timestamp', () {
      testWidgets('when createdAt is 20h before now, it should display 20h atrás', (tester) async {
        final createdAt = DateTime(2025, 6, 15, 0);
        final fixedNow = createdAt.add(const Duration(hours: 20));

        await withClock(Clock(() => fixedNow), () async {
          await tester.pumpWidget(
            _FeedJobCardTestHelpers.wrap(
              FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture().copyWith(createdAt: createdAt)),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(i18n.feedJob.timeAgo.hours(count: 20)), findsOneWidget);
        });
      });

      testWidgets('when createdAt is 1 day before now, it should display 1 dia atrás', (tester) async {
        final createdAt = DateTime(2025, 6, 15);
        final fixedNow = createdAt.add(const Duration(days: 1));

        await withClock(Clock(() => fixedNow), () async {
          await tester.pumpWidget(
            _FeedJobCardTestHelpers.wrap(
              FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture().copyWith(createdAt: createdAt)),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(i18n.feedJob.timeAgo.days(count: 1)), findsOneWidget);
        });
      });
    });

    group('cross-widget consistency', () {
      testWidgets('when opening a feed job, it should let the built-in container transition animate the surface', (
        tester,
      ) async {
        final feedJob = _FeedJobCardTestHelpers.fixture();

        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: feedJob)));
        await tester.pumpAndSettle();
        final surfaceMorph = tester.widget<Morph>(
          find.byWidgetPredicate((widget) => widget is Morph && widget.tag == 'job-${feedJob.jobId}-surface'),
        );

        expect(
          surfaceMorph,
          isA<Morph>()
              .having((morph) => morph.child, 'child', isA<Container>())
              .having((morph) => morph.flightDelegate, 'flightDelegate', isNull),
        );
      });

      testWidgets('when the same job appears in the feed and detail view, it should connect both shared transitions', (
        tester,
      ) async {
        const jobId = 'job_123';

        await tester.pumpWidget(
          _FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture().copyWith(jobId: jobId))),
        );

        await tester.pumpAndSettle();
        final cardSurface = tester.widget<Morph>(
          find.byWidgetPredicate((widget) => widget is Morph && widget.tag == 'job-$jobId-surface'),
        );
        final cardHeader = tester.widget<Morph>(
          find.byWidgetPredicate((widget) => widget is Morph && widget.tag == 'job-$jobId-header'),
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: JobViewTestHelpers.feedJob(jobId: jobId),
          jobState: JobViewTestHelpers.loadingState(),
        );
        final viewSurface = tester.widget<Morph>(
          find.byWidgetPredicate((widget) => widget is Morph && widget.tag == 'job-$jobId-surface'),
        );
        final viewHeader = tester.widget<Morph>(
          find.byWidgetPredicate((widget) => widget is Morph && widget.tag == 'job-$jobId-header'),
        );

        expect((viewSurface.tag, viewHeader.tag), equals((cardSurface.tag, cardHeader.tag)));
      });

      testWidgets('when the feed card and detail view rebuild, it should keep stable shared-transition identities', (
        tester,
      ) async {
        const jobId = 'job_123';
        const surfaceTag = 'job-$jobId-surface';
        const headerTag = 'job-$jobId-header';
        const fadeTag = 'job-$jobId-edge-fade';

        await tester.pumpWidget(
          _FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture().copyWith(jobId: jobId))),
        );

        await tester.pumpAndSettle();
        final cardKeys = (
          tester
              .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == surfaceTag))
              .child
              .key,
          tester
              .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == headerTag))
              .child
              .key,
          tester.widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == fadeTag)).child.key,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: JobViewTestHelpers.feedJob(jobId: jobId),
          jobState: JobViewTestHelpers.loadingState(),
        );
        final viewKeys = (
          tester
              .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == surfaceTag))
              .child
              .key,
          tester
              .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == headerTag))
              .child
              .key,
          tester.widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == fadeTag)).child.key,
        );

        expect(
          (cardKeys, viewKeys),
          equals((
            (const ValueKey(surfaceTag), const ValueKey(headerTag), const ValueKey(fadeTag)),
            (const ValueKey(surfaceTag), const ValueKey(headerTag), const ValueKey(fadeTag)),
          )),
        );
      });
    });
  });
}
