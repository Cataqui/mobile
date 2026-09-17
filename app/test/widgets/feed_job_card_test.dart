import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/job/enums/job_view_transform_tag.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:oh_my_flutter/src/widgets/morph/morph.dart' show MorphColumnFlightDelegate, MorphColumnProperties;

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

  static MorphColumnProperties captureHeader(WidgetTester tester, String jobId) {
    final finder = find.byKey(ValueKey(JobViewTransformTag.header.valueFor(jobId: jobId)));
    return MorphColumnFlightDelegate.captureColumn(
      context: tester.element(finder),
      column: tester.widget<Column>(finder),
      renderObject: tester.renderObject<RenderFlex>(finder),
      axisScale: const Offset(1, 1),
      switchThreshold: 0.9,
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
    testWidgets('closing description morph retains width while the card has room', (tester) async {
      final feedJob = _FeedJobCardTestHelpers.fixture(descriptionSummary: 'Summary of the job available nearby.');
      await JobViewTestHelpers.pumpJobView(tester: tester, jobState: FakeJobState(), feedJob: feedJob);
      await tester.pumpAndSettle();
      final source = _FeedJobCardTestHelpers.captureHeader(tester, feedJob.jobId);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: feedJob)));
      await tester.pumpAndSettle();
      final destination = _FeedJobCardTestHelpers.captureHeader(tester, feedJob.jobId);
      final descriptionWidth = tester.getSize(find.byKey(const ValueKey('job_description'))).width;
      final minimumWidth = source.children[3].rect.width < descriptionWidth
          ? source.children[3].rect.width
          : descriptionWidth;
      for (final progress in [0.2, 0.5, 0.8]) {
        final flight = const MorphColumnFlightDelegate().lerpProperties(
          source,
          destination,
          MorphFlightProgress(
            curvedProgress: progress,
            uncurvedProgress: progress,
            flightKind: .routePop,
            animationStatus: .forward,
          ),
        );
        expect(flight.children[3].rect.width, greaterThanOrEqualTo(minimumWidth));
      }
    });

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

      testWidgets('when created, the card should have 36px border radius', (tester) async {
        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture())));
        await tester.pumpAndSettle();

        final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);

        expect(((decoratedBox.decoration as ShapeDecoration).shape as MateoRoundedShapeBorder).radius, equals(36));
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

        expect(text.style!.color, equals(MateoTheme.of(tester.element(paymentText)).colorScheme.text.profit));
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

        expect(text.style!.color, equals(MateoTheme.of(context).colorScheme.text.secondary));
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
      testWidgets('when opening a feed job, it should let Mateo animate the complete surface', (tester) async {
        final feedJob = _FeedJobCardTestHelpers.fixture();

        await tester.pumpWidget(_FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: feedJob)));
        await tester.pumpAndSettle();
        final surface = tester.widget<MateoSurface>(find.byType(MateoSurface));

        expect(
          surface.animation,
          isA<MateoSurfaceAnimationTransform>()
              .having((animation) => animation.id, 'id', JobViewTransformTag.surface.valueFor(jobId: feedJob.jobId))
              .having((animation) => animation.duration, 'duration', JobRoute.pushDuration)
              .having((animation) => animation.curve, 'curve', Curves.fastOutSlowIn),
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
        final cardSurface = tester.widget<MateoSurface>(find.byType(MateoSurface));
        final cardHeader = tester.widget<Morph>(
          find.byWidgetPredicate(
            (widget) => widget is Morph && widget.target.tag == JobViewTransformTag.header.valueFor(jobId: jobId),
          ),
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: JobViewTestHelpers.feedJob(jobId: jobId),
          jobState: JobViewTestHelpers.loadingState(),
        );
        final viewSurface = tester.widget<MateoViewSurface>(find.byKey(const ValueKey('job_surface')));
        final viewHeader = tester.widget<Morph>(
          find.byWidgetPredicate(
            (widget) => widget is Morph && widget.target.tag == JobViewTransformTag.header.valueFor(jobId: jobId),
          ),
        );

        expect((
          (viewSurface.animation! as MateoSurfaceAnimationTransform).id,
          viewHeader.target.tag,
        ), equals(((cardSurface.animation! as MateoSurfaceAnimationTransform).id, cardHeader.target.tag)));
      });

      testWidgets('when the feed card and detail view rebuild, it should keep stable shared-transition identities', (
        tester,
      ) async {
        const jobId = 'job_123';
        final surfaceTag = JobViewTransformTag.surface.valueFor(jobId: jobId);
        final headerTag = JobViewTransformTag.header.valueFor(jobId: jobId);

        await tester.pumpWidget(
          _FeedJobCardTestHelpers.wrap(FeedJobCard(feedJob: _FeedJobCardTestHelpers.fixture().copyWith(jobId: jobId))),
        );

        await tester.pumpAndSettle();
        final cardIdentities = (
          (tester.widget<MateoSurface>(find.byType(MateoSurface)).animation! as MateoSurfaceAnimationTransform).id,
          tester
              .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.target.tag == headerTag))
              .child
              .key,
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: JobViewTestHelpers.feedJob(jobId: jobId),
          jobState: JobViewTestHelpers.loadingState(),
        );
        final viewIdentities = (
          (tester.widget<MateoViewSurface>(find.byKey(const ValueKey('job_surface'))).animation!
                  as MateoSurfaceAnimationTransform)
              .id,
          tester
              .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.target.tag == headerTag))
              .child
              .key,
        );

        expect((
          cardIdentities,
          viewIdentities,
        ), equals(((surfaceTag, ValueKey(headerTag)), (surfaceTag, ValueKey(headerTag)))));
      });
    });
  });
}
