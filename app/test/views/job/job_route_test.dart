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
  }

  static Future<void> pumpFeed(
    WidgetTester tester, {
    required FeedJobDto feedJob,
    required JobRepository jobRepository,
  }) async {
    FeedViewTestHelpers.mockHapticFeedback(tester);
    FeedViewTestHelpers.mockPlatformViews(tester);
    await tester.pumpWidget(
      JobViewTestHelpers.buildRoutedApp(
        goRouter: goRouter(),
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

      expect(tester.widget<JobView>(find.byType(JobView)).feedJob, feedJob);
    });
  });
}
