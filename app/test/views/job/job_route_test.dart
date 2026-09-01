import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../feed/feed_view_test_helpers.dart';
import 'job_view_test_helpers.dart';

class JobRouteTestHelpers {
  JobRouteTestHelpers._();

  static GoRouter goRouter({String initialLocation = '/'}) =>
      GoRouter(initialLocation: initialLocation, routes: [$feedRoute, $jobRoute]);

  static Future<void> pumpDeepLinkedJobRoute(WidgetTester tester, {required String jobId}) async {
    FeedViewTestHelpers.mockHapticFeedback(tester);
    FeedViewTestHelpers.mockPlatformViews(tester);
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    final jobRepository = MockJobRepository();
    when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
      (_) async => ApiEnvelopeDto<JobDto>(
        data: JobViewTestHelpers.job(),
        requestId: 'test-request-id',
        timestamp: DateTime(2026, 6, 30),
        endpoint: '/v1/jobs/$jobId',
      ),
    );
    await tester.pumpWidget(
      JobViewTestHelpers.buildRoutedApp(
        goRouter: goRouter(initialLocation: '/job/$jobId'),
        feedState: () => FakeFeedState(buildResult: () => const FeedData(jobs: [], hasMore: false)),
        jobRepository: jobRepository,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
  }

  static Future<void> pumpFeed(
    WidgetTester tester, {
    required FeedJobDto feedJob,
    required JobRepository jobRepository,
    GoRouter? goRouter,
  }) async {
    FeedViewTestHelpers.mockHapticFeedback(tester);
    FeedViewTestHelpers.mockPlatformViews(tester);
    await tester.pumpWidget(
      JobViewTestHelpers.buildRoutedApp(
        goRouter: goRouter ?? JobRouteTestHelpers.goRouter(),
        feedState: () => FakeFeedState(buildResult: () => FeedData(jobs: [feedJob], hasMore: false)),
        jobRepository: jobRepository,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }
}

void main() {
  group('JobRoute.location', () {
    test('when the job id is plain ascii, it should build the /job/<id> location', () {
      expect(JobRoute(jobId: 'job_123').location, '/job/job_123');
    });

    test('when the job id contains a space, it should url-encode the space in the location', () {
      expect(JobRoute(jobId: 'job 123').location, '/job/job%20123');
    });

    test('when the job id contains a forward slash, it should url-encode the slash in the location', () {
      expect(JobRoute(jobId: 'job/123').location, '/job/job%2F123');
    });
  });

  group('when navigating to the job route with a feed job', () {
    late MockJobRepository jobRepository;

    setUp(() {
      jobRepository = MockJobRepository();
      when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
        (_) async => ApiEnvelopeDto<JobDto>(
          data: JobViewTestHelpers.job(),
          requestId: 'test-request-id',
          timestamp: DateTime(2026, 6, 30),
          endpoint: '/v1/jobs/job_123',
        ),
      );
    });

    testWidgets('when pushing the job route from the feed, it should render the JobView', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: JobRouteTestHelpers.goRouter(),
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      expect(find.byType(JobView), findsOneWidget);
    });

    testWidgets('when pushing the job route from the feed, it should pass the exact feed job to the JobView', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: JobRouteTestHelpers.goRouter(),
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      expect(tester.widget<JobView>(find.byType(JobView)).feedJob, feedJob);
    });

    testWidgets('when pushing the job route from the feed, it should mount the JobView under a transparent page', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: JobRouteTestHelpers.goRouter(),
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      final settings = ModalRoute.of(tester.element(find.byType(JobView)))!.settings;
      expect((settings as CustomTransitionPage<void>).opaque, isFalse);
    });

    testWidgets('when pushing the job route from the feed, it should use the configured shared transition durations', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobViewTestHelpers.pumpRoutedJobView(
        tester: tester,
        goRouter: JobRouteTestHelpers.goRouter(),
        feedJob: feedJob,
        jobRepository: jobRepository,
      );
      final page = ModalRoute.of(tester.element(find.byType(JobView)))!.settings as CustomTransitionPage<void>;
      expect((page.transitionDuration, page.reverseTransitionDuration), (JobRoute.pushDuration, JobRoute.popDuration));
    });

    testWidgets(
      'when swiping down before the job route finishes opening, it should reverse immediately without errors',
      (tester) async {
        final feedJob = JobViewTestHelpers.feedJob(title: 'Auxiliar de cozinha para evento noturno');
        final goRouter = JobRouteTestHelpers.goRouter();
        await JobRouteTestHelpers.pumpFeed(tester, feedJob: feedJob, jobRepository: jobRepository, goRouter: goRouter);
        unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(tester.element(find.byType(FeedView))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        final route = ModalRoute.of(tester.element(find.byType(JobView)))!;
        final openingProgress = route.animation!.value;
        var routePopped = false;
        unawaited(route.popped.then((_) => routePopped = true));
        var maximumProgress = openingProgress;
        void recordProgress() {
          maximumProgress = math.max(maximumProgress, route.animation!.value);
        }

        route.animation!.addListener(recordProgress);
        addTearDown(() => route.animation?.removeListener(recordProgress));
        var feedConfigurationCount = 0;
        void recordConfiguration() {
          if (goRouter.routerDelegate.currentConfiguration.matches.length == 1) {
            feedConfigurationCount += 1;
          }
        }

        goRouter.routerDelegate.addListener(recordConfiguration);
        addTearDown(() => goRouter.routerDelegate.removeListener(recordConfiguration));

        await tester.fling(
          find.byType(MateoScrollableView),
          const Offset(0, 260),
          2000,
          frameInterval: const Duration(seconds: 1),
        );
        await tester.pump();
        final reversingImmediately = route.animation!.status == AnimationStatus.reverse;
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        final errors = <Object>[];
        Object? error;
        while ((error = tester.takeException()) != null) {
          errors.add(error!);
        }

        expect(
          (
            reversedImmediately: reversingImmediately,
            openingStoppedBeforeCompletion: maximumProgress < 1,
            jobRemoved: find.byType(JobView).evaluate().isEmpty,
            feedCurrent: find.byType(FeedView).evaluate().isNotEmpty,
            routePopped: routePopped,
            oneDismissal: feedConfigurationCount == 1,
            openingWasPartial: openingProgress < 1,
            hasErrors: errors.isNotEmpty,
          ),
          (
            reversedImmediately: true,
            openingStoppedBeforeCompletion: true,
            jobRemoved: true,
            feedCurrent: true,
            routePopped: true,
            oneDismissal: true,
            openingWasPartial: true,
            hasErrors: false,
          ),
        );
      },
    );

    testWidgets('when flinging the handle before the job route finishes opening, it should reverse without errors', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();
      final goRouter = JobRouteTestHelpers.goRouter();
      await JobRouteTestHelpers.pumpFeed(tester, feedJob: feedJob, jobRepository: jobRepository, goRouter: goRouter);
      unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(tester.element(find.byType(FeedView))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final route = ModalRoute.of(tester.element(find.byType(JobView)))!;
      var maximumProgress = route.animation!.value;
      void recordProgress() {
        maximumProgress = math.max(maximumProgress, route.animation!.value);
      }

      route.animation!.addListener(recordProgress);
      addTearDown(() => route.animation?.removeListener(recordProgress));

      await tester.fling(
        find.byKey(const ValueKey('job_dismiss_handle')),
        const Offset(0, 180),
        2000,
        frameInterval: const Duration(seconds: 1),
      );
      await tester.pump();
      final reversedImmediately = route.animation!.status == AnimationStatus.reverse;
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      final errors = <Object>[];
      Object? error;
      while ((error = tester.takeException()) != null) {
        errors.add(error!);
      }

      expect(
        (
          reversedImmediately: reversedImmediately,
          openingStoppedBeforeCompletion: maximumProgress < 1,
          jobRemoved: find.byType(JobView).evaluate().isEmpty,
          hasErrors: errors.isNotEmpty,
        ),
        (reversedImmediately: true, openingStoppedBeforeCompletion: true, jobRemoved: true, hasErrors: false),
      );
    });
  });

  group('when deep-linking to /job/:jobId without an extra', () {
    testWidgets('when deep-linking to /job/:jobId with no extra, it should render the JobView', (tester) async {
      await JobRouteTestHelpers.pumpDeepLinkedJobRoute(tester, jobId: 'abc');
      expect(find.byType(JobView), findsOneWidget);
    });

    testWidgets('when deep-linking to /job/:jobId with no extra, it should set the correct jobId on the JobView', (
      tester,
    ) async {
      await JobRouteTestHelpers.pumpDeepLinkedJobRoute(tester, jobId: 'abc');
      expect(tester.widget<JobView>(find.byType(JobView)).jobId, 'abc');
    });

    testWidgets('when deep-linking to /job/:jobId with no extra, it should set feedJob to null on the JobView', (
      tester,
    ) async {
      await JobRouteTestHelpers.pumpDeepLinkedJobRoute(tester, jobId: 'abc');
      expect(tester.widget<JobView>(find.byType(JobView)).feedJob, isNull);
    });

    testWidgets(
      'when deep-linking to /job/:jobId with no extra, it should mount the JobView under a NoTransitionPage',
      (tester) async {
        await JobRouteTestHelpers.pumpDeepLinkedJobRoute(tester, jobId: 'abc');
        final settings = ModalRoute.of(tester.element(find.byType(JobView)))!.settings;
        expect(settings, isA<NoTransitionPage<void>>());
      },
    );
  });

  group('when navigating via the generated typed API', () {
    late MockJobRepository jobRepository;

    setUp(() {
      jobRepository = MockJobRepository();
      when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
        (_) async => ApiEnvelopeDto<JobDto>(
          data: JobViewTestHelpers.job(),
          requestId: 'test-request-id',
          timestamp: DateTime(2026, 6, 30),
          endpoint: '/v1/jobs/job_123',
        ),
      );
    });

    testWidgets('when calling go() with a feed job, it should render the JobView with that feed job', (tester) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobRouteTestHelpers.pumpFeed(tester, feedJob: feedJob, jobRepository: jobRepository);

      JobRoute(jobId: feedJob.jobId, $extra: feedJob).go(tester.element(find.byType(FeedView)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 560));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<JobView>(find.byType(JobView)).feedJob, feedJob);
    });

    testWidgets('when calling replace() with a feed job, it should render the JobView with that feed job', (
      tester,
    ) async {
      final feedJob = JobViewTestHelpers.feedJob();
      await JobRouteTestHelpers.pumpFeed(tester, feedJob: feedJob, jobRepository: jobRepository);

      JobRoute(jobId: feedJob.jobId, $extra: feedJob).replace(tester.element(find.byType(FeedView)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 560));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<JobView>(find.byType(JobView)).feedJob, feedJob);
    });
  });
}
