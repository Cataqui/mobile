import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/enums/job_view_morph_tag.dart';
import 'package:cataqui_app/views/job/job_contact_button.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import 'job_view_test_helpers.dart';

void main() {
  late Translations i18n;
  late GoRouter goRouter;
  late MockJobRepository jobRepository;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  setUp(() {
    goRouter = GoRouter(initialLocation: const FeedRoute().location, routes: [$feedRoute, $jobRoute]);
    jobRepository = MockJobRepository();
    when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
      (_) async => ApiEnvelopeDto<JobDto>(
        data: JobViewTestHelpers.job(),
        requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
        timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
        endpoint: '/v1/jobs/job_123',
      ),
    );
  });

  group('JobView', () {
    testWidgets('when opened from a feed job, it should show the feed title immediately', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: feedJob,
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.text('Unload a truck'), findsOneWidget);
    });

    testWidgets('when opened from a feed job, it should show the feed payment immediately', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: feedJob,
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.textContaining(r'R$150'), findsOneWidget);
    });

    testWidgets('when opened from a feed job posted 20 hours ago, it should show the feed time immediately', (
      tester,
    ) async {
      final fixedNow = DateTime(2026, 6, 30, 11);
      final feedJob = JobViewTestHelpers.feedJob(createdAt: fixedNow.subtract(const Duration(hours: 20)));

      await withClock(Clock(() => fixedNow), () async {
        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: feedJob,
          jobState: JobViewTestHelpers.loadingState(),
        );
      });

      expect(find.text(i18n.feedJob.timeAgo.hours(count: 20)), findsOneWidget);
    });

    testWidgets('when the full job loads, it should show the full description', (tester) async {
      const description = 'Descrição completa do trabalho com horários, local e detalhes importantes.';

      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadedState(job: JobViewTestHelpers.job(description: description)),
      );

      expect(find.text(description), findsOneWidget);
    });

    testWidgets('when the full job fails, it should show the retry button', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.errorState(),
      );

      expect(find.text(i18n.feed.error.retryButtonTitle), findsOneWidget);
    });

    testWidgets('when the full job fails and retry is tapped, it should retry loading the full job', (tester) async {
      var retryCount = 0;

      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.errorState(
          retryResult: () async {
            retryCount += 1;
          },
        ),
      );
      final retryButton = find.text(i18n.feed.error.retryButtonTitle);
      await tester.ensureVisible(retryButton);
      await tester.pump();
      await tester.tap(retryButton);
      // Pump past the 50ms loading delay timer so the test can settle.
      await tester.pump(const Duration(milliseconds: 60));

      expect(retryCount, equals(1));
    });

    testWidgets('when opened, it should render the JobView screen', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.byType(JobView), findsOneWidget);
    });

    testWidgets('when opened, it should wrap the screen with interactive dismissal', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.byType(InteractiveSwipeDismiss), findsOneWidget);
    });

    testWidgets('when opened, it should make the whole header a dismissal handle', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
      );

      final headerHandle = find.byKey(const ValueKey('job_dismiss_handle'));
      expect(
        find.descendant(of: headerHandle, matching: find.byKey(const ValueKey('job_dismiss_handle_visual'))),
        findsOneWidget,
      );
    });

    testWidgets('when opened from the feed, it should render the title inside the moving header', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob(title: 'Separador de Mercadorias');

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );

      final headerMorph = tester.widget<Morph>(
        find
            .ancestor(
              of: find.text('Separador de Mercadorias', skipOffstage: false),
              matching: find.byWidgetPredicate((widget) => widget is Morph),
            )
            .first,
      );
      expect(headerMorph.tag, equals(JobViewMorphTag.header.valueFor(jobId: feedJob.jobId)));
    });

    testWidgets('when dragging the surface down, it should preview dismissal without scrubbing the route animation', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      final surface = find.byType(MateoScrollableView);
      final initialTopLeft = tester.getTopLeft(surface);
      final gesture = await tester.startGesture(tester.getCenter(surface));
      await gesture.moveBy(const Offset(0, 220));
      await tester.pump();

      final route = ModalRoute.of(tester.element(find.byType(JobView)));
      expect((
        route!.animation!.value,
        tester.getTopLeft(surface) - initialTopLeft,
      ), equals((1, const Offset(0, 81.4))));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('when dragging the surface past the threshold, it should pop back to the feed', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      await tester.drag(find.byType(MateoScrollableView), const Offset(0, 260));
      await tester.pumpAndSettle();

      expect(find.byType(JobView), findsNothing);
    });

    testWidgets('when dragging the surface below the threshold, it should restore JobView', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      await tester.drag(find.byType(MateoScrollableView), const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 430));
      await tester.pump();

      expect(find.byType(JobView), findsOneWidget);
    });

    testWidgets(
      'when the description is scrolled down and the user drags downward, it should scroll instead of closing',
      (tester) async {
        final feedJob = JobViewTestHelpers.feedJob();
        final description = List<String>.filled(80, 'Linha de descrição longa.').join('\n');
        when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
          (_) async => ApiEnvelopeDto<JobDto>(
            data: JobViewTestHelpers.job(description: description),
            requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
            timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
            endpoint: '/v1/jobs/job_123',
          ),
        );

        await JobViewTestHelpers.pumpRoutedJobView(
          tester: tester,
          goRouter: goRouter,
          feedJob: feedJob,
          jobRepository: jobRepository,
        );
        await tester.drag(find.byType(MateoScrollableView), const Offset(0, -500));
        await tester.pump();
        await tester.drag(find.byType(MateoScrollableView), const Offset(0, 150));
        await tester.pump();

        final route = ModalRoute.of(tester.element(find.byType(JobView)));
        expect(route!.animation!.value, equals(1));
      },
    );

    testWidgets(
      'when the description is scrolled down and the header edge is dragged, it should pop back to the feed',
      (tester) async {
        final feedJob = JobViewTestHelpers.feedJob();
        final description = List<String>.filled(80, 'Linha de descrição longa.').join('\n');
        when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
          (_) async => ApiEnvelopeDto<JobDto>(
            data: JobViewTestHelpers.job(description: description),
            requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
            timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
            endpoint: '/v1/jobs/job_123',
          ),
        );

        await JobViewTestHelpers.pumpRoutedJobView(
          tester: tester,
          goRouter: goRouter,
          feedJob: feedJob,
          jobRepository: jobRepository,
        );
        await tester.drag(find.byType(MateoScrollableView), const Offset(0, -500));
        await tester.pump();
        final header = find.byKey(const ValueKey('job_dismiss_handle'));
        final gesture = await tester.startGesture(tester.getCenter(header));
        await gesture.moveBy(const Offset(0, 260));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(JobView), findsNothing);
      },
    );

    testWidgets(
      'when interactive dismissal moves the surface, it should preserve fixed-slot geometry without scrolling',
      (tester) async {
        final feedJob = JobViewTestHelpers.feedJob();
        final description = List<String>.filled(80, 'Linha de descrição longa.').join('\n');
        when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
          (_) async => ApiEnvelopeDto<JobDto>(
            data: JobViewTestHelpers.job(description: description),
            requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
            timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
            endpoint: '/v1/jobs/job_123',
          ),
        );

        await JobViewTestHelpers.pumpRoutedJobView(
          tester: tester,
          goRouter: goRouter,
          feedJob: feedJob,
          jobRepository: jobRepository,
        );
        final header = find.byKey(const ValueKey('job_dismiss_handle'));
        final body = find.byKey(const ValueKey('job_title')).last;
        final footer = find.descendant(of: find.byType(JobContactButton), matching: find.byType(MateoButton)).last;
        final scrollPosition = Scrollable.of(tester.element(body)).position;
        await tester.drag(find.byType(MateoScrollableView), const Offset(0, -500));
        await tester.pump();
        Offset positionInView(Finder finder) {
          final view = tester.renderObject<RenderBox>(find.byType(MateoScrollableView));
          final child = tester.renderObject<RenderBox>(finder);
          return view.globalToLocal(child.localToGlobal(Offset.zero));
        }

        final initial = (
          headerToBody: positionInView(body) - positionInView(header),
          bodyToFooter: positionInView(footer) - positionInView(body),
          scrollOffset: scrollPosition.pixels,
        );

        final gesture = await tester.startGesture(tester.getCenter(header));
        await gesture.moveBy(const Offset(0, 120));
        await tester.pump();

        final current = (
          headerToBody: positionInView(body) - positionInView(header),
          bodyToFooter: positionInView(footer) - positionInView(body),
          scrollOffset: scrollPosition.pixels,
        );
        expect(
          current,
          predicate<({Offset headerToBody, Offset bodyToFooter, double scrollOffset})>(
            (geometry) =>
                (geometry.headerToBody - initial.headerToBody).distance < 0.001 &&
                (geometry.bodyToFooter - initial.bodyToFooter).distance < 0.001 &&
                geometry.scrollOffset == initial.scrollOffset,
            'preserves header, body, footer, and scroll geometry',
          ),
        );
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });

  group('when opened from a deep link without a feed job', () {
    testWidgets('when loading, it should not show the title', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.text(JobViewTestHelpers.feedJob().title), findsNothing);
    });

    testWidgets('when loaded, it should show the job title from the fetched data', (tester) async {
      const title = 'Carregar caminhão';

      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.loadedState(job: JobViewTestHelpers.job(title: title)),
      );

      expect(find.text(title), findsOneWidget);
    });

    testWidgets('when loaded, it should show the payment from the fetched data', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.loadedState(),
      );

      expect(find.textContaining(r'R$150'), findsOneWidget);
    });

    testWidgets('when loaded with a job posted 20 hours ago, it should show the time-ago from the fetched data', (
      tester,
    ) async {
      final fixedNow = DateTime(2026, 6, 30, 11);
      final createdAt = fixedNow.subtract(const Duration(hours: 20));

      await withClock(Clock(() => fixedNow), () async {
        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: null,
          jobId: 'job_deep_link',
          jobState: JobViewTestHelpers.loadedState(job: JobViewTestHelpers.job(createdAt: createdAt)),
        );
      });

      expect(find.text(i18n.feedJob.timeAgo.hours(count: 20)), findsOneWidget);
    });

    testWidgets('when the full job fails, it should show the retry button', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.errorState(),
      );

      expect(find.text(i18n.feed.error.retryButtonTitle), findsOneWidget);
    });

    testWidgets('when the full job fails and retry is tapped, it should retry loading the full job', (tester) async {
      var retryCount = 0;

      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.errorState(
          retryResult: () async {
            retryCount += 1;
          },
        ),
      );
      final retryButton = find.text(i18n.feed.error.retryButtonTitle);
      await tester.ensureVisible(retryButton);
      await tester.pump();
      await tester.tap(retryButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(retryCount, equals(1));
    });
  });
}
