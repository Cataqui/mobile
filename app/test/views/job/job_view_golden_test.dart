import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/gen/three_d.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../feed/feed_view_test_helpers.dart';
import 'job_view_test_helpers.dart';

void main() {
  group('JobView Golden Tests', () {
    goldenTest(
      'when the full job is loading, it should show the immediate header and description spinner',
      fileName: 'job_view_loading_description',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: JobViewGoldenTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadingState(),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
    );

    goldenTest(
      'when the full job has loaded, it should show the immediate header and full description',
      fileName: 'job_view_loaded_description',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: JobViewGoldenTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadedState(),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.settle,
    );

    goldenTest(
      'when the full job fails, it should show the immediate header and retry action',
      fileName: 'job_view_error_retry',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: JobViewGoldenTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.errorState(),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.settle,
    );

    goldenTest(
      'when the title is very long, it should clamp to 4 lines with ellipsis',
      fileName: 'job_view_long_title',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: JobViewGoldenTestHelpers.feedJob(
          title:
              'Preciso de um ajudante muito experiente para descarregar um '
              'caminhão pesado amanhã cedo no centro da cidade perto da '
              'estação',
        ),
        jobState: JobViewTestHelpers.loadedState(),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.settle,
    );

    goldenTest(
      'when deep-linked and loading, it should show header skeletons and description skeleton',
      fileName: 'job_view_deep_link_loading',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.loadingState(),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
    );

    goldenTest(
      'when deep-linked and loaded, it should show the fetched header and description',
      fileName: 'job_view_deep_link_loaded',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.loadedState(job: JobViewGoldenTestHelpers.job()),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.settle,
    );

    goldenTest(
      'when deep-linked and error, it should show header skeletons and retry action',
      fileName: 'job_view_deep_link_error',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: null,
        jobId: 'job_deep_link',
        jobState: JobViewTestHelpers.errorState(),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.settle,
    );

    goldenTest(
      'when scrolled to the bottom of a very long description, it should show bottom padding before the edge fade',
      fileName: 'job_view_long_description',
      builder: () => JobViewGoldenTestHelpers.scenario(
        feedJob: JobViewGoldenTestHelpers.feedJob(),
        jobState: JobViewTestHelpers.loadedState(
          job: JobViewGoldenTestHelpers.job(description: JobViewGoldenTestHelpers.veryLongDescription),
        ),
      ),
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.scrollToBottom,
    );

    goldenTest(
      'when dragging down from the top, it should show the card shrinking back toward the feed',
      fileName: 'job_view_mid_drag_close',
      builder: JobViewGoldenTestHelpers.routedScenario,
      pumpWidget: JobViewGoldenTestHelpers.pumpWidget,
      pumpBeforeTest: JobViewGoldenTestHelpers.prepareRoutedFeed,
      whilePerforming: JobViewGoldenTestHelpers.dragMidClose,
    );
  });
}

class JobViewGoldenTestHelpers {
  JobViewGoldenTestHelpers._();

  static final DateTime fixedNow = DateTime(2026, 6, 30, 11);

  static Future<void> pumpWidget(WidgetTester tester, Widget widget) {
    return withClock(fixedClock(), () => tester.pumpWidget(widget));
  }

  static Future<void> settle(WidgetTester tester) async {
    await withClock(fixedClock(), () async {
      await tester.runAsync(() => $ThreeD.precache(tester.element(find.byType(JobView))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    });
  }

  static String get veryLongDescription {
    final paragraphs = List.generate(
      30,
      (i) =>
          '${i + 1}. Este é um parágrafo muito longo da descrição da '
          'oportunidade para garantir que o conteúdo ultrapasse o tamanho '
          'da tela e seja necessário rolar para baixo. Esta vaga exige '
          'disponibilidade imediata e bastante disposição para o trabalho.',
    );
    return paragraphs.join('\n\n');
  }

  static Future<void> scrollToBottom(WidgetTester tester) async {
    await withClock(fixedClock(), () async {
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -10000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });
  }

  static Clock fixedClock() {
    return Clock(() => fixedNow);
  }

  static FeedJobDto feedJob({String? title}) {
    return JobViewTestHelpers.feedJob(
      title: title ?? 'Unload a truck',
      createdAt: fixedNow.subtract(const Duration(hours: 3)),
    );
  }

  static JobDto job({String? description}) {
    return JobViewTestHelpers.job(description: description, createdAt: fixedNow.subtract(const Duration(hours: 3)));
  }

  static Widget scenario({required FakeJobState jobState, FeedJobDto? feedJob, String? jobId}) {
    final resolvedJobId = jobId ?? feedJob!.jobId;
    return SizedBox(
      width: 390,
      height: 844,
      child: TickerMode(
        enabled: false,
        child: JobViewTestHelpers.buildApp(jobId: resolvedJobId, feedJob: feedJob, jobState: jobState),
      ),
    );
  }

  static Widget routedScenario() {
    final goRouter = GoRouter(initialLocation: '/', routes: [$feedRoute, $jobRoute]);
    final goldenFeedJob = feedJob();
    final jobRepository = MockJobRepository();

    when(() => jobRepository.getJob(jobId: any(named: 'jobId'))).thenAnswer(
      (_) async => ApiEnvelopeDto<JobDto>(
        data: job(),
        requestId: '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
        timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
        endpoint: '/job/${goldenFeedJob.jobId}',
      ),
    );

    return SizedBox(
      width: 390,
      height: 844,
      child: JobViewTestHelpers.buildRoutedApp(
        goRouter: goRouter,
        feedState: () => FakeFeedState(buildResult: () => FeedData(jobs: [goldenFeedJob], hasMore: false)),
        jobRepository: jobRepository,
      ),
    );
  }

  static Future<void> prepareRoutedFeed(WidgetTester tester) async {
    await withClock(fixedClock(), () async {
      FeedViewTestHelpers.mockPlatformViews(tester);
      FeedViewTestHelpers.mockGoogleMapsPlatform();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();
    });
  }

  static Future<AsyncCallback?> dragMidClose(WidgetTester tester) async {
    return withClock(fixedClock(), () async {
      final feedJob = tester.widget<FeedJobCard>(find.byType(FeedJobCard).first).feedJob;

      unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(tester.element(find.byType(FeedJobCard).first)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 560));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
      await gesture.moveBy(const Offset(0, 140));
      await tester.pump();

      return gesture.up;
    });
  }
}
