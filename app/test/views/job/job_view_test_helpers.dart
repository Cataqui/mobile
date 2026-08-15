import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/job/job_data.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_state.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import '../feed/feed_view_test_helpers.dart';

// FakeJobState exists because _$JobState (from riverpod_generator) is
// library-private and cannot be accessed by mocktail outside job_state.dart.
// By extending JobState, we inherit the correct runBuild() from _$JobState.
class FakeJobState extends JobState {
  FakeJobState({this.buildResult, this.initialAsyncValue, this.retryResult});

  final FutureOr<JobData> Function(String jobId)? buildResult;
  final AsyncValue<JobData>? initialAsyncValue;
  final Future<void> Function()? retryResult;

  @override
  Future<JobData> build(String jobId) {
    if (initialAsyncValue != null) {
      state = initialAsyncValue!;
      return Completer<JobData>().future;
    }
    if (buildResult != null) {
      final result = buildResult!(jobId);
      if (result is Future<JobData>) return result;
      return Future<JobData>.value(result);
    }
    return Future<JobData>.value(JobViewTestHelpers.jobData());
  }

  @override
  Future<void> retry() async {
    await retryResult?.call();
  }
}

class JobViewTestHelpers {
  JobViewTestHelpers._();

  static MockSharedPreferencesAsync _seenPrefs() {
    final p = MockSharedPreferencesAsync();
    when(() => p.getBool(any())).thenAnswer((_) async => true);
    when(() => p.setBool(any(), any())).thenAnswer((_) async {});
    return p;
  }

  static FeedJobDto feedJob({String jobId = 'job_123', String title = 'Unload a truck', DateTime? createdAt}) {
    return FeedJobDto.fixture().copyWith(
      jobId: jobId,
      title: title,
      createdAt: createdAt ?? DateTime(2026, 6, 30, 8),
      payment: const JobPaymentDto(
        type: JobPaymentType.fixed,
        minAmount: 150,
        amountPeriod: JobPaymentAmountPeriod.daily,
        currency: 'BRL',
      ),
    );
  }

  static JobDto job({String jobId = 'job_123', String? title, String? description, DateTime? createdAt}) {
    return JobDto.fixture().copyWith(
      jobId: jobId,
      title: title ?? 'Unload a truck',
      createdAt: createdAt ?? JobDto.fixture().createdAt,
      description:
          description ??
          'Precisamos de uma pessoa para descarregar um caminhão pequeno no centro. O trabalho deve durar algumas horas e o pagamento será feito no fim do dia.',
      payment: const JobPaymentDto(
        type: JobPaymentType.fixed,
        minAmount: 150,
        amountPeriod: JobPaymentAmountPeriod.daily,
        currency: 'BRL',
      ),
    );
  }

  static JobData jobData({JobDto? job}) {
    return JobData(job: job ?? JobViewTestHelpers.job());
  }

  static FakeJobState loadingState() {
    return FakeJobState(initialAsyncValue: const AsyncLoading<JobData>());
  }

  static FakeJobState loadedState({JobDto? job}) {
    return FakeJobState(initialAsyncValue: AsyncData<JobData>(jobData(job: job)));
  }

  static FakeJobState errorState({Future<void> Function()? retryResult}) {
    return FakeJobState(
      initialAsyncValue: AsyncError<JobData>(StateError('job failed'), StackTrace.current),
      retryResult: retryResult,
    );
  }

  static Widget buildApp({
    required FakeJobState jobState,
    String? jobId,
    FeedJobDto? feedJob,
    bool disableAnimations = true,
  }) {
    final resolvedJobId = jobId ?? feedJob!.jobId;
    final mediaQueryData = const MediaQueryData(
      size: Size(390, 844),
      devicePixelRatio: 3,
      textScaler: TextScaler.noScaling,
    ).copyWith(disableAnimations: disableAnimations);
    return ProviderScope(
      overrides: [jobStateProvider(resolvedJobId).overrideWith(() => jobState)],
      child: TestApp.screen(
        mediaQueryData: mediaQueryData,
        child: JobView(jobId: resolvedJobId, feedJob: feedJob),
      ),
    );
  }

  static Widget buildRoutedApp({
    required GoRouter goRouter,
    required FeedState Function() feedState,
    required JobRepository jobRepository,
    bool disableAnimations = false,
    String? fontFamily,
  }) {
    final mediaQueryData = const MediaQueryData(
      size: Size(390, 844),
      devicePixelRatio: 3,
      textScaler: TextScaler.noScaling,
    ).copyWith(disableAnimations: disableAnimations);
    return TestApp.router(
      routerConfig: goRouter,
      mediaQueryData: mediaQueryData,
      fontFamily: fontFamily,
      providerOverrides: [
        goRouterProvider.overrideWithValue(goRouter),
        feedStateProvider.overrideWith(feedState),
        jobRepositoryProvider.overrideWithValue(jobRepository),
        sharedPreferencesAsyncProvider.overrideWithValue(_seenPrefs()),
      ],
    );
  }

  static Future<void> pumpJobView({
    required WidgetTester tester,
    required FakeJobState jobState,
    FeedJobDto? feedJob,
    String? jobId,
    bool disableAnimations = true,
  }) async {
    final resolvedJobId = jobId ?? feedJob!.jobId;
    await tester.pumpWidget(
      buildApp(jobId: resolvedJobId, feedJob: feedJob, jobState: jobState, disableAnimations: disableAnimations),
    );
    await tester.pump();
  }

  static Future<void> pumpRoutedJobView({
    required WidgetTester tester,
    required GoRouter goRouter,
    required FeedJobDto feedJob,
    required JobRepository jobRepository,
    FeedData? feedData,
    bool disableAnimations = false,
  }) async {
    FeedViewTestHelpers.mockHapticFeedback(tester);
    FeedViewTestHelpers.mockPlatformViews(tester);

    await tester.pumpWidget(
      buildRoutedApp(
        goRouter: goRouter,
        feedState: () => FakeFeedState(buildResult: () => feedData ?? FeedData(jobs: [feedJob], hasMore: false)),
        jobRepository: jobRepository,
        disableAnimations: disableAnimations,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    unawaited(JobRoute(jobId: feedJob.jobId, $extra: feedJob).push(tester.element(find.byType(FeedView))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 560));
    await tester.pumpAndSettle();
  }
}
