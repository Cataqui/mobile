import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import '../../utils/static_map_cache_test_helpers.dart';
import 'feed_view_test_helpers.dart';

void main() {
  late MockStaticMapCacheManager cacheManager;
  late FeedData data;
  late FakeFeedState feedState;

  setUp(() {
    cacheManager = StaticMapCacheTestHelpers.create();
    final initial = FeedViewTestHelpers.feedDataWithJobs(count: 8, hasMore: false);
    data = initial.copyWith(
      jobs: initial.jobs
          .map(
            (job) =>
                job.copyWith(location: job.location.copyWith(imageUrl: '${job.location.imageUrl}/job=${job.jobId}')),
          )
          .toList(),
    );
    feedState = FakeFeedState(buildResult: () => data);
  });

  testWidgets('when browsing and refreshing the feed, it should move the disk lookahead with the visible job', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);

    final requested = <String>[];
    for (final job in data.jobs) {
      final request = StaticMapRequest(imageUrl: job.location.imageUrl, size: .pixels960x2560);
      requested.add(request.url);
    }
    final initialRequests = verify(
      () => cacheManager.getSingleFile(
        captureAny(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).captured;
    expect(initialRequests, [requested[2], requested[3]]);
    expect(
      tester.widgetList<JobLocationImage>(find.byType(JobLocationImage)).where((image) => image.enabled).length,
      lessThanOrEqualTo(3),
    );
    final snapListController = tester.widget<SnapList>(find.byType(SnapList)).controller!;
    await StaticMapCacheTestHelpers.loadImages(tester);
    final movement = snapListController.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await movement;
    await tester.pump();
    expect(
      verify(
        () => cacheManager.getSingleFile(
          captureAny(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      ).captured,
      [requested[4]],
    );
    final refresh = data.copyWith(
      jobs: data.jobs
          .map(
            (job) => job.copyWith(
              location: job.location.copyWith(
                latitude: job.location.latitude + 1,
                imageUrl: '${job.location.imageUrl}/revision=2',
              ),
            ),
          )
          .toList(),
    );
    feedState.emittedValue = AsyncData(refresh);
    await tester.pump();
    await tester.pump();
    final refreshed = verify(
      () => cacheManager.getSingleFile(
        captureAny(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).captured;
    expect(refreshed.toSet(), {
      for (final index in [3, 4])
        StaticMapRequest(imageUrl: refresh.jobs[index].location.imageUrl, size: .pixels960x2560).url,
    });
    verifyNever(cacheManager.emptyCache);
    final nextMovement = snapListController.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await nextMovement;
    await tester.pump();
    verifyNever(() => cacheManager.removeFile(any()));
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when a refresh recreates the feed, it should load and prefetch images from the first job', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    await StaticMapCacheTestHelpers.loadImages(tester);
    for (var index = 0; index < 2; index++) {
      await tester.drag(find.byType(SnapList), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.widget<SnapList>(find.byType(SnapList)).controller!.index, 2);

    feedState.emittedValue = const AsyncLoading<FeedData>();
    await tester.pump();
    expect(find.byType(SnapList), findsNothing);
    clearInteractions(cacheManager);

    final refreshedData = data.copyWith(
      jobs: data.jobs
          .map((job) => job.copyWith(location: job.location.copyWith(imageUrl: '${job.location.imageUrl}/revision=2')))
          .toList(),
    );
    feedState.emittedValue = AsyncData(refreshedData);
    await tester.pump();
    await tester.pump();

    expect(tester.widget<SnapList>(find.byType(SnapList)).controller!.index, 0);
    final firstImage = tester
        .widgetList<JobLocationImage>(find.byType(JobLocationImage))
        .singleWhere((image) => image.imageUrl == refreshedData.jobs.first.location.imageUrl);
    expect(firstImage.enabled, isTrue);
    expect(
      verify(
        () => cacheManager.getSingleFile(
          captureAny(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      ).captured.toSet(),
      {
        for (final index in [2, 3])
          StaticMapRequest(imageUrl: refreshedData.jobs[index].location.imageUrl, size: .pixels960x2560).url,
      },
    );
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });
}

abstract final class _FeedImageLoadingTestHelpers {
  static Future<void> pump({
    required WidgetTester tester,
    required FakeFeedState feedState,
    required MockStaticMapCacheManager cacheManager,
  }) async {
    await tester.pumpWidget(
      FeedViewTestHelpers.buildApp(
        providerOverrides: [
          ...FeedViewTestHelpers.buildProviderOverrides(feedState: feedState, hasSeenSwipeFeedHint: true),
          staticMapCacheManagerProvider.overrideWith((ref) => cacheManager),
        ],
        child: const FeedView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
  }
}
