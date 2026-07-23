import 'dart:async';

import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/three_d.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';

// FakeFeedState exists because _$FeedState (from riverpod_generator) is
// library-private and cannot be accessed by mocktail outside feed_state.dart.
// By extending FeedState, we inherit the correct runBuild() from _$FeedState.
class FakeFeedState extends FeedState {
  FakeFeedState({this.buildResult, this.initialAsyncValue, this.getFeedJobsResult});

  final FutureOr<FeedData> Function()? buildResult;
  final AsyncValue<FeedData>? initialAsyncValue;
  final Future<void> Function({required bool fetchNextPage})? getFeedJobsResult;

  @override
  Future<FeedData> build() {
    if (initialAsyncValue != null) {
      state = initialAsyncValue!;
      return Completer<FeedData>().future;
    }
    if (buildResult != null) {
      final result = buildResult!();
      if (result is Future<FeedData>) return result;
      return Future<FeedData>.value(result);
    }
    return Future<FeedData>.value(const FeedData(jobs: [], hasMore: false));
  }

  @override
  Future<void> getFeedJobs({bool fetchNextPage = false}) async {
    await getFeedJobsResult?.call(fetchNextPage: fetchNextPage);
  }

  set emittedValue(AsyncValue<FeedData> value) {
    state = value;
  }

  AsyncValue<FeedData> get emittedValue => state;
}

class FixedAppStorageState extends AppStorageState {
  FixedAppStorageState({required this.hasSeenSwipeFeedHint});

  final bool hasSeenSwipeFeedHint;

  @override
  Future<AppStorageData> build() {
    final data = AppStorageData(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint);
    state = AsyncData(data);
    return Future<AppStorageData>.value(data);
  }
}

class FeedViewTestHelpers {
  FeedViewTestHelpers._();

  static const _surfaceSize = Size(390, 844);

  static void mockHapticFeedback(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async => null,
    );
  }

  static void mockPlatformViews(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      _handlePlatformViewCall,
    );
  }

  static void mockMapChannels() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform_views, _handlePlatformViewCall);
    for (var id = 0; id < 20; id++) {
      messenger.setMockMethodCallHandler(MethodChannel('plugins.flutter.io/maplibre_gl_$id'), _handleMapLibreCall);
    }
  }

  static Future<Object?> _handlePlatformViewCall(MethodCall call) async {
    return switch (call.method) {
      'create' => 1,
      'resize' => const <String, double>{'width': 390, 'height': 540},
      'dispose' || 'offset' || 'setDirection' || 'clearFocus' || 'touch' => null,
      _ => null,
    };
  }

  static Future<Object?> _handleMapLibreCall(MethodCall call) async {
    return switch (call.method) {
      'map#waitForMap' => null,
      _ => null,
    };
  }

  static Future<void> precacheFeedStateImages(BuildContext context) async {
    await $ThreeD.precache(context);
  }

  static Future<void> prepareGoldenCapture({required WidgetTester tester, required Finder contextFinder}) async {
    mockPlatformViews(tester);
    await tester.runAsync(() async {
      await precacheFeedStateImages(tester.element(contextFinder)).timeout(const Duration(seconds: 5));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  static Widget buildApp({required Widget child, bool disableAnimations = false}) {
    final mediaQueryData = const MediaQueryData(
      size: _surfaceSize,
      devicePixelRatio: 3,
      textScaler: TextScaler.noScaling,
    ).copyWith(disableAnimations: disableAnimations);

    return TestApp.screen(mediaQueryData: mediaQueryData, child: child);
  }

  static ProviderScope buildScope({
    required FakeFeedState feedState,
    required Widget child,
    GoRouter? goRouter,
    MockSharedPreferencesAsync? prefs,
    bool? hasSeenSwipeFeedHint,
  }) {
    return ProviderScope(
      overrides: [
        feedStateProvider.overrideWith(() => feedState),
        if (goRouter != null) goRouterProvider.overrideWithValue(goRouter),
        if (prefs != null) sharedPreferencesAsyncProvider.overrideWithValue(prefs),
        if (hasSeenSwipeFeedHint != null)
          appStorageStateProvider.overrideWith(() => FixedAppStorageState(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint)),
      ],
      child: child,
    );
  }

  static Future<void> pumpFeedView({
    required WidgetTester tester,
    required FakeFeedState feedState,
    GoRouter? goRouter,
    MockSharedPreferencesAsync? prefs,
    bool? hasSeenSwipeFeedHint,
  }) async {
    mockHapticFeedback(tester);
    mockPlatformViews(tester);
    await tester.pumpWidget(
      buildApp(
        child: buildScope(
          feedState: feedState,
          goRouter: goRouter,
          prefs: prefs,
          hasSeenSwipeFeedHint: hasSeenSwipeFeedHint ?? (prefs != null ? null : true),
          child: const FeedView(),
        ),
      ),
    );
    await tester.pump(); // Microtask resolves, data arrives, exit starts
    await tester.pump(const Duration(milliseconds: 900)); // Exit completes
    await tester.pump(); // Enter starts, content renders in tree
  }

  static Widget buildFeedViewApp({
    required FakeFeedState feedState,
    bool disableAnimations = false,
    MockSharedPreferencesAsync? prefs,
    bool? hasSeenSwipeFeedHint,
  }) {
    return buildApp(
      child: buildScope(
        feedState: feedState,
        prefs: prefs,
        hasSeenSwipeFeedHint: hasSeenSwipeFeedHint ?? (prefs != null ? null : true),
        child: const FeedView(),
      ),
      disableAnimations: disableAnimations,
    );
  }

  static FeedData feedDataEmpty() => const FeedData(jobs: [], hasMore: false);

  static FeedData feedDataWithJobs({int count = 1, bool hasMore = true}) {
    return FeedData(
      jobs: List<FeedJobDto>.generate(
        count,
        (i) => FeedJobDto.fixture().copyWith(
          jobId: 'job_$i',
          title: i == 0 ? 'Descarregar Caminhão' : 'Garçom para Fim de Semana $i',
        ),
      ),
      hasMore: hasMore,
    );
  }

  static FeedData feedDataWithLoadingMore() {
    return feedDataWithJobs(count: 1);
  }

  static FeedData feedDataWithPaginationError() {
    return feedDataWithJobs(count: 1).copyWith(paginationError: StateError('test pagination error'));
  }

  static FeedData feedDataWithPaginationEnd() {
    return feedDataWithJobs(count: 1, hasMore: false);
  }

  static DioException offlineDioException() {
    return DioException(
      requestOptions: RequestOptions(path: '/feed'),
      error: const OfflineConnectionDioException(message: 'No internet connection'),
    );
  }

  static FeedData feedDataWithOfflinePaginationError() {
    return feedDataWithJobs(count: 1).copyWith(paginationError: offlineDioException());
  }

  static Future<void> swipeAwayCurrentJob(WidgetTester tester) async {
    await tester.drag(find.text('Descarregar Caminhão'), const Offset(0, -800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800));
  }

  static Future<void> pumpAndCleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }
}
