import 'dart:async';

import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

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
    await Future.wait([
      precacheImage(Qui3d.brush.provider(), context),
      precacheImage(Qui3d.hammer.provider(), context),
      precacheImage(Qui3d.ladder.provider(), context),
      precacheImage(Qui3d.motorcycle.provider(), context),
      precacheImage(Qui3d.shoppingCart.provider(), context),
      precacheImage(Qui3d.smallTruck.provider(), context),
      precacheImage(Qui3d.toolBox.provider(), context),
      precacheImage(Qui3d.box.provider(), context),
      precacheImage(Qui3d.locationPinRestingCracked.provider(), context),
      precacheImage(Qui3d.emptyCitySaoPaulo.provider(), context),
      precacheImage(Qui3d.workItemsMess.provider(), context),
      precacheImage(Qui3d.wifiExclamation.provider(), context),
    ]);
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

    return MaterialApp(
      theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
      home: MediaQuery(data: mediaQueryData, child: child),
    );
  }

  static ProviderScope buildScope({required FakeFeedState feedState, required Widget child}) {
    return ProviderScope(overrides: [feedStateProvider.overrideWith(() => feedState)], child: child);
  }

  static Future<void> pumpFeedView({required WidgetTester tester, required FakeFeedState feedState}) async {
    mockHapticFeedback(tester);
    mockPlatformViews(tester);
    await tester.pumpWidget(
      buildApp(
        child: buildScope(feedState: feedState, child: const FeedView()),
      ),
    );
    await tester.pump(); // Microtask resolves, data arrives, exit starts
    await tester.pump(const Duration(milliseconds: 900)); // Exit completes
    await tester.pump(); // Enter starts, content renders in tree
  }

  static Widget buildFeedViewApp({required FakeFeedState feedState, bool disableAnimations = false}) {
    return buildApp(
      child: buildScope(feedState: feedState, child: const FeedView()),
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
      error: const OmfOfflineConnectionDioException(message: 'No internet connection'),
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
