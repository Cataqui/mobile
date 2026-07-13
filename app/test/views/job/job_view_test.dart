import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

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
    goRouter = GoRouter(initialLocation: '/', routes: [$feedRoute, $jobRoute]);
    jobRepository = MockJobRepository();
    when(
      () => jobRepository.getJob(jobId: any(named: 'jobId')),
    ).thenAnswer(
      (_) async => ApiEnvelopeDto<JobDto>(
        data: JobViewTestHelpers.job(),
        requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
        timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
        endpoint: '/job/job_123',
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
      await tester.tap(find.text(i18n.feed.error.retryButtonTitle));
      await tester.pump();

      expect(retryCount, equals(1));
    });

    testWidgets('when opened, it should show the QUI back button', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.byType(QuiViewBackButton), findsOneWidget);
    });

    testWidgets('when motion is enabled and the screen starts opening, it should keep the QUI back button hidden', (
      tester,
    ) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
        disableAnimations: false,
      );

      final fadeTransition = tester.widget<FadeTransition>(
        find
            .ancestor(of: find.byType(QuiViewBackButton, skipOffstage: false), matching: find.byType(FadeTransition))
            .first,
      );
      expect(fadeTransition.opacity.value, equals(0));
    });

    testWidgets('when motion is enabled and the opening transition finishes, it should show the QUI back button once', (
      tester,
    ) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
        disableAnimations: false,
      );
      await tester.pump(const Duration(milliseconds: 560));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      final hasVisibleFade = tester.widgetList<FadeTransition>(
        find.ancestor(of: find.byType(QuiViewBackButton, skipOffstage: false), matching: find.byType(FadeTransition)),
      );
      expect(hasVisibleFade.any((fadeTransition) => fadeTransition.opacity.value == 1), isTrue);
    });

    testWidgets('when motion is enabled and the QUI back button is tapped, it should hide before leaving', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
        disableAnimations: false,
      );

      await tester.tap(find.byType(QuiViewBackButton));
      await tester.pump();

      final fadeTransition = tester.widget<FadeTransition>(
        find
            .ancestor(of: find.byType(QuiViewBackButton, skipOffstage: false), matching: find.byType(FadeTransition))
            .first,
      );
      expect(fadeTransition.opacity.value, equals(0));
    });

    testWidgets(
      'when motion is enabled and the QUI back button is tapped, it should keep the full description as a shared element',
      (tester) async {
        const description = 'Descrição completa do trabalho com horários, local e detalhes importantes.';

        await JobViewTestHelpers.pumpJobView(
          tester: tester,
          feedJob: JobViewTestHelpers.feedJob(),
          jobState: JobViewTestHelpers.loadedState(job: JobViewTestHelpers.job(description: description)),
          disableAnimations: false,
        );
        await tester.pump(const Duration(milliseconds: 560));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.tap(find.byType(QuiViewBackButton));
        await tester.pump();

        expect(
          find.ancestor(of: find.text(description, skipOffstage: false), matching: find.byType(Hero)),
          findsOneWidget,
        );
      },
    );

    testWidgets('when opened, it should render the JobView screen', (tester) async {
      await JobViewTestHelpers.pumpJobView(
        tester: tester,
        feedJob: JobViewTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
      );

      expect(find.byType(JobView), findsOneWidget);
    });

    testWidgets('when opened from the feed, it should render the title inside the grouped header hero', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob(title: 'Separador de Mercadorias');

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );

      final headerHero = tester.widget<Hero>(
        find
            .ancestor(of: find.text('Separador de Mercadorias', skipOffstage: false), matching: find.byType(Hero))
            .first,
      );
      expect(headerHero.tag, equals(FeedJobCard.headerHeroKey(feedJob.jobId)));
    });

    testWidgets('when opened from the feed, it should render the background hero with the matching tag', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );

      final backgroundHero = tester.widget<QuiHeroBackground>(find.byType(QuiHeroBackground).first);
      expect(backgroundHero.tag, equals(FeedJobCard.backgroundHeroKey(feedJob.jobId)));
    });

    testWidgets('when dragging down from the top, it should move the job route toward the feed card', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 220));
      await tester.pump();

      final route = QuiHeroPageRoute.maybeOf(tester.element(find.byType(JobView)));
      expect(route!.transitionValue, lessThan(1));
      await gesture.up();
    });

    testWidgets('when dragging down from the top past half the screen, it should pop back to the feed', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 260));
      await tester.pumpAndSettle();

      expect(find.byType(JobView), findsNothing);
    });

    testWidgets('when dragging down from the top less than half the screen, it should reopen JobView', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 430));
      await tester.pump();

      expect(find.byType(JobView), findsOneWidget);
    });

    testWidgets(
      'when the description is scrolled down and the user drags downward, it should scroll instead of closing',
      (tester) async {
        final feedJob = JobViewTestHelpers.feedJob();
        final description = List<String>.filled(80, 'Linha de descrição longa.').join('\n');
        when(
          () => jobRepository.getJob(jobId: any(named: 'jobId')),
        ).thenAnswer(
          (_) async => ApiEnvelopeDto<JobDto>(
            data: JobViewTestHelpers.job(description: description),
            requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
            timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
            endpoint: '/job/job_123',
          ),
        );

        await JobViewTestHelpers.pumpRoutedJobView(
          tester: tester,
          goRouter: goRouter,
          feedJob: feedJob,
          jobRepository: jobRepository,
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pump();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
        await tester.pump();

        final route = QuiHeroPageRoute.maybeOf(tester.element(find.byType(JobView)));
        expect(route!.transitionValue, equals(1));
      },
    );

    testWidgets('when interactive closing starts, it should hide the QUI back button and description', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();

      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: goRouter,
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();

      final fadeTransition = tester.widget<FadeTransition>(
        find
            .ancestor(of: find.byType(QuiViewBackButton, skipOffstage: false), matching: find.byType(FadeTransition))
            .first,
      );
      expect(fadeTransition.opacity.value, equals(0));
      await gesture.up();
    });
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
      await tester.tap(find.text(i18n.feed.error.retryButtonTitle));
      await tester.pump();

      expect(retryCount, equals(1));
    });
  });
}
