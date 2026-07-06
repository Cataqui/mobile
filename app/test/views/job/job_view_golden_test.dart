import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qui/qui.dart';

import '../../mocks.dart';
import '../feed/feed_view_test_helpers.dart';
import 'job_view_test_helpers.dart';

void main() {
  autoUpdateGoldenFiles = true;
  setUpAll(() {
    registerFallbackValue(AppLocale.ptBr);
  });

  group('JobView Golden Tests', () {
    goldenTest(
      'when the full job is loading, it should show the immediate header and description spinner',
      fileName: 'job_view_loading_description',
      builder: () => withClock(
        JobViewGoldenTestHelpers.fixedClock(),
        () => JobViewGoldenTestHelpers.scenario(
          feedJob: JobViewTestHelpers.feedJob(),
          jobState: JobViewTestHelpers.loadingState(),
        ),
      ),
    );

    goldenTest(
      'when the full job has loaded, it should show the immediate header and full description',
      fileName: 'job_view_loaded_description',
      builder: () => withClock(
        JobViewGoldenTestHelpers.fixedClock(),
        () => JobViewGoldenTestHelpers.scenario(
          feedJob: JobViewTestHelpers.feedJob(),
          jobState: JobViewTestHelpers.loadedState(),
        ),
      ),
    );

    goldenTest(
      'when the full job fails, it should show the immediate header and retry action',
      fileName: 'job_view_error_retry',
      builder: () => withClock(
        JobViewGoldenTestHelpers.fixedClock(),
        () => JobViewGoldenTestHelpers.scenario(
          feedJob: JobViewTestHelpers.feedJob(),
          jobState: JobViewTestHelpers.errorState(),
        ),
      ),
    );

    goldenTest(
      'when dragging down from the top, it should show the card shrinking back toward the feed',
      fileName: 'job_view_mid_drag_close',
      builder: () => withClock(JobViewGoldenTestHelpers.fixedClock(), JobViewGoldenTestHelpers.routedScenario),
      pumpBeforeTest: JobViewGoldenTestHelpers.prepareRoutedFeed,
      whilePerforming: JobViewGoldenTestHelpers.dragMidClose,
    );
  });
}

class JobViewGoldenTestHelpers {
  JobViewGoldenTestHelpers._();

  static Clock fixedClock() {
    return Clock(() => DateTime(2026, 6, 30, 11));
  }

  static Widget scenario({required FeedJobDto feedJob, required FakeJobState jobState}) {
    return SizedBox(
      width: 390,
      height: 844,
      child: TickerMode(
        enabled: false,
        child: JobViewTestHelpers.buildApp(feedJob: feedJob, jobState: jobState),
      ),
    );
  }

  static Widget routedScenario() {
    final goRouter = GoRouter(initialLocation: '/', routes: [$feedRoute, $jobRoute]);
    final feedJob = JobViewTestHelpers.feedJob();
    final jobRepository = MockJobRepository();

    when(
      () => jobRepository.getJob(
        jobId: any(named: 'jobId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer(
      (_) async => ApiEnvelopeDto<JobDto>(
        data: JobViewTestHelpers.job(),
        requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
        timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
        endpoint: '/job/${feedJob.jobId}',
      ),
    );

    return SizedBox(
      width: 390,
      height: 844,
      child: JobViewTestHelpers.buildRoutedApp(
        goRouter: goRouter,
        feedState: () => FakeFeedState(buildResult: () => FeedData(jobs: [feedJob], hasMore: false)),
        jobRepository: jobRepository,
      ),
    );
  }

  static Future<void> prepareRoutedFeed(WidgetTester tester) async {
    FeedViewTestHelpers.mockPlatformViews(tester);
    FeedViewTestHelpers.mockMapChannels();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
  }

  static Future<AsyncCallback?> dragMidClose(WidgetTester tester) async {
    final feedJob = tester.widget<FeedJobCard>(find.byType(FeedJobCard).first).feedJob;

    unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(tester.element(find.byType(FeedJobCard).first)));
    await tester.pump();
    await tester.pump(QuiHeroPage.defaultTransitionDuration);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    await gesture.moveBy(const Offset(0, 140));
    await tester.pump();

    return gesture.up;
  }
}
