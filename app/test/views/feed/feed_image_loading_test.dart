import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image.dart';
import 'package:file/file.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    cacheManager = StaticMapCacheTestHelpers.create();
    final initial = FeedViewTestHelpers.feedDataWithJobs(count: 8, hasMore: false);
    data = initial.copyWith(
      jobs: initial.jobs
          .map(
            (job) => job.copyWith(
              location: job.location.copyWith(
                imageUrl: job.location.imageUrl.replaceFirst('.webp', '_${job.jobId}.webp'),
              ),
            ),
          )
          .toList(),
    );
    feedState = FakeFeedState(buildResult: () => data);
  });

  testWidgets('when the first map waits for bytes, it should leave the adjacent layout without another image request', (
    tester,
  ) async {
    final held = await _FeedImageLoadingTestHelpers.holdDownloads(cacheManager: cacheManager);
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
    expect(held.providerStarts, [
      _FeedImageLoadingTestHelpers.request(tester, data.jobs.first.location.imageUrl).cacheKey,
    ]);
  });

  testWidgets('when a drag exposes the next job before current bytes arrive, it should start that map immediately', (
    tester,
  ) async {
    final held = await _FeedImageLoadingTestHelpers.holdDownloads(cacheManager: cacheManager);
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    final visible = _FeedImageLoadingTestHelpers.request(tester, data.jobs[0].location.imageUrl);
    final incoming = _FeedImageLoadingTestHelpers.request(tester, data.jobs[1].location.imageUrl);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SnapList)));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await tester.pump();
    final position = tester.widget<SnapList>(find.byType(SnapList)).controller!.position!;
    final observation = [
      held.providerStarts.toList(),
      position > 0 && position < 1,
      held.downloads[visible.cacheKey]!.isCompleted,
    ];
    await gesture.up();
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
    expect(observation, [
      [visible.cacheKey, incoming.cacheKey],
      true,
      false,
    ]);
  });

  testWidgets(
    'when adjacent map bytes become ready, it should decode that map before the user leaves the current job',
    (tester) async {
      final held = await _FeedImageLoadingTestHelpers.holdDownloads(cacheManager: cacheManager);
      await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
      final visible = _FeedImageLoadingTestHelpers.request(tester, data.jobs[0].location.imageUrl);
      final adjacent = _FeedImageLoadingTestHelpers.request(tester, data.jobs[1].location.imageUrl);
      held.downloads[visible.cacheKey]!.complete(held.cachedFile);
      await tester.pump();
      await tester.pump();
      final providersBeforeAdjacentBytes = [...held.providerStarts];
      held.downloads[adjacent.cacheKey]!.complete(held.cachedFile);
      await tester.pump();
      await tester.pump();
      await StaticMapCacheTestHelpers.loadImages(tester);
      final adjacentImage = find.byWidgetPredicate(
        (widget) => widget is JobLocationImage && widget.imageUrl == data.jobs[1].location.imageUrl,
        skipOffstage: false,
      );
      final decoded = tester
          .widgetList<RawImage>(
            find.descendant(
              of: adjacentImage,
              matching: find.byType(RawImage, skipOffstage: false),
              skipOffstage: false,
            ),
          )
          .any((image) => image.image != null);
      expect(
        [
          providersBeforeAdjacentBytes,
          held.providerStarts,
          decoded,
          tester.widget<SnapList>(find.byType(SnapList)).controller!.index,
        ],
        [
          [visible.cacheKey],
          [visible.cacheKey, adjacent.cacheKey],
          true,
          0,
        ],
      );
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    },
  );

  testWidgets(
    'when another swipe exposes a third map during two active downloads, it should bypass the prefetch queue',
    (tester) async {
      final held = await _FeedImageLoadingTestHelpers.holdDownloads(cacheManager: cacheManager);
      await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
      final requests = [
        for (final job in data.jobs.take(3)) _FeedImageLoadingTestHelpers.request(tester, job.location.imageUrl),
      ];
      await tester.drag(find.byType(SnapList), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(SnapList)));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await tester.pump();
      final observation = [
        held.providerStarts.toList(),
        requests.take(2).every((request) => !held.downloads[request.cacheKey]!.isCompleted),
      ];
      await gesture.up();
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
      expect(observation, [requests.map((request) => request.cacheKey).toList(), true]);
    },
  );

  testWidgets('when obsolete bytes finish after a feed refresh, it should keep the new adjacent map held', (
    tester,
  ) async {
    final held = await _FeedImageLoadingTestHelpers.holdDownloads(cacheManager: cacheManager);
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    final oldVisible = _FeedImageLoadingTestHelpers.request(tester, data.jobs.first.location.imageUrl);
    final refreshedData = data.copyWith(
      jobs: data.jobs
          .map(
            (job) => job.copyWith(
              location: job.location.copyWith(imageUrl: job.location.imageUrl.replaceFirst('.webp', '_revision2.webp')),
            ),
          )
          .toList(),
    );
    feedState.emittedValue = const AsyncLoading<FeedData>();
    await tester.pump();
    feedState.emittedValue = AsyncData(refreshedData);
    await tester.pump();
    await tester.pump();
    held.downloads[oldVisible.cacheKey]!.complete(held.cachedFile);
    await tester.pump();
    await tester.pump();
    final newVisible = _FeedImageLoadingTestHelpers.request(tester, refreshedData.jobs.first.location.imageUrl);
    final adjacent = tester
        .widgetList<JobLocationImage>(find.byType(JobLocationImage, skipOffstage: false))
        .singleWhere((image) => image.imageUrl == refreshedData.jobs[1].location.imageUrl);
    expect(
      [held.providerStarts, adjacent.enabled],
      [
        [oldVisible.cacheKey, newVisible.cacheKey],
        false,
      ],
    );
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when the viewport changes while map bytes are pending, it should reuse the existing preset request', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(
      tester: tester,
      feedState: feedState,
      cacheManager: cacheManager,
      screenSize: const Size(390, 844),
    );
    await StaticMapCacheTestHelpers.loadImages(tester);
    final held = await _FeedImageLoadingTestHelpers.holdDownloads(cacheManager: cacheManager);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    await tester.pump();
    expect(held.providerStarts, isEmpty);
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when a short feed reserves map credit, it should let the user scroll through the visible job details', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    final details = find.descendant(
      of: find.byKey(ValueKey(data.jobs.first.jobId)),
      matching: find.byType(SingleChildScrollView),
    );
    await FeedViewTestHelpers.scrollToEnd(tester: tester, viewport: details);
    final position = tester
        .state<ScrollableState>(find.descendant(of: details, matching: find.byType(Scrollable)))
        .position;
    expect((position.pixels > 0, position.pixels == position.maxScrollExtent), (true, true));
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when the feed body is tiny, it should request a usable map presentation instead of hiding its details', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(
      tester: tester,
      feedState: feedState,
      cacheManager: cacheManager,
      screenSize: const Size(360, 225),
    );
    expect(tester.getSize(find.byType(JobLocationImage).first).height, 200);
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when scrolling a tiny feed to the map footer, it should keep that job visible through the whole drag', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(
      tester: tester,
      feedState: feedState,
      cacheManager: cacheManager,
      screenSize: const Size(360, 225),
    );
    final viewport = find.byKey(ValueKey('feed_map_viewport_${data.jobs.first.jobId}'));
    await FeedViewTestHelpers.scrollToEnd(tester: tester, viewport: viewport);
    final position = tester
        .state<ScrollableState>(find.descendant(of: viewport, matching: find.byType(Scrollable)))
        .position;
    expect(
      (
        position.pixels > 0,
        position.pixels == position.maxScrollExtent,
        tester.widget<SnapList>(find.byType(SnapList)).controller!.index,
      ),
      (true, true, 0),
    );
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when a new outward drag starts at the tiny map footer, it should show the next job', (tester) async {
    await _FeedImageLoadingTestHelpers.pump(
      tester: tester,
      feedState: feedState,
      cacheManager: cacheManager,
      screenSize: const Size(360, 225),
    );
    final viewport = find.byKey(ValueKey('feed_map_viewport_${data.jobs.first.jobId}'));
    await FeedViewTestHelpers.scrollToEnd(tester: tester, viewport: viewport);
    await tester.drag(viewport, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<SnapList>(find.byType(SnapList)).controller!.index, 1);
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when a new backward drag starts at the next tiny job header, it should return to the previous job', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(
      tester: tester,
      feedState: feedState,
      cacheManager: cacheManager,
      screenSize: const Size(360, 225),
    );
    final firstViewport = find.byKey(ValueKey('feed_map_viewport_${data.jobs.first.jobId}'));
    await FeedViewTestHelpers.scrollToEnd(tester: tester, viewport: firstViewport);
    await tester.drag(firstViewport, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 500));
    final nextIndex = tester.widget<SnapList>(find.byType(SnapList)).controller!.index;
    await tester.drag(find.byKey(ValueKey('feed_map_viewport_${data.jobs[1].jobId}')), const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 500));
    expect([nextIndex, tester.widget<SnapList>(find.byType(SnapList)).controller!.index], [1, 0]);
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when a feed viewport changes, it should reuse the same preset URLs without downloading new variants', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    clearInteractions(cacheManager);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    final visibleImages = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).toList();
    verifyNever(
      () => cacheManager.getSingleFile(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    );
    final expectedRequests = {
      for (final job in data.jobs.take(4))
        job.location.imageUrl: _FeedImageLoadingTestHelpers.request(tester, job.location.imageUrl),
    };
    expect(
      [visibleImages.map((image) => (image.imageUrl, image.cacheKey)).toList(), <String>[]],
      [
        [
          for (final image in tester.widgetList<JobLocationImage>(find.byType(JobLocationImage)))
            if (image.enabled)
              if (expectedRequests[image.imageUrl] case final request?) (request.url, request.cacheKey),
        ],
        <String>[],
      ],
    );
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when a feed refresh replaces pending maps, it should load the new visible maps before stale lookahead', (
    tester,
  ) async {
    final cachedFile = await cacheManager.getSingleFile('https://maps.cataqui.com/static/v1/fixture_reference.webp');
    final started = <String>[];
    final downloads = <String, Completer<File>>{};
    when(
      () => cacheManager.getSingleFile(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((invocation) {
      final key = invocation.namedArguments[#key]! as String;
      started.add(key);
      return (downloads[key] = Completer<File>()).future;
    });
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);
    final beforeRefresh = [...started];
    final visibleKeys = [_FeedImageLoadingTestHelpers.request(tester, data.jobs.first.location.imageUrl).cacheKey];
    final refreshedData = data.copyWith(
      jobs: data.jobs
          .map(
            (job) => job.copyWith(
              location: job.location.copyWith(imageUrl: job.location.imageUrl.replaceFirst('.webp', '_revision2.webp')),
            ),
          )
          .toList(),
    );
    feedState.emittedValue = const AsyncLoading<FeedData>();
    await tester.pump();
    feedState.emittedValue = AsyncData(refreshedData);
    await tester.pump();
    await tester.pump();
    for (final download in downloads.values.toList()) {
      download.complete(cachedFile);
    }
    await tester.pump();
    await tester.pump();
    expect(
      [beforeRefresh, started],
      [
        visibleKeys,
        [
          ...visibleKeys,
          for (final job in refreshedData.jobs.take(2))
            _FeedImageLoadingTestHelpers.request(tester, job.location.imageUrl).cacheKey,
        ],
      ],
    );
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });

  testWidgets('when browsing and refreshing the feed, it should move the disk lookahead with the visible job', (
    tester,
  ) async {
    await _FeedImageLoadingTestHelpers.pump(tester: tester, feedState: feedState, cacheManager: cacheManager);

    final requested = <String>[];
    for (final job in data.jobs) {
      final request = _FeedImageLoadingTestHelpers.request(tester, job.location.imageUrl);
      requested.add(request.url);
    }
    final initialRequests = verify(
      () => cacheManager.getSingleFile(
        captureAny(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).captured;
    expect(initialRequests, [requested[0], requested[1], requested[2], requested[3]]);
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
                imageUrl: job.location.imageUrl.replaceFirst('.webp', '_revision2.webp'),
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
      for (final index in [1, 2, 3, 4])
        _FeedImageLoadingTestHelpers.request(tester, refresh.jobs[index].location.imageUrl).url,
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
          .map(
            (job) => job.copyWith(
              location: job.location.copyWith(imageUrl: job.location.imageUrl.replaceFirst('.webp', '_revision2.webp')),
            ),
          )
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
        for (final index in [0, 1, 2, 3])
          _FeedImageLoadingTestHelpers.request(tester, refreshedData.jobs[index].location.imageUrl).url,
      },
    );
    await FeedViewTestHelpers.pumpAndCleanUp(tester);
  });
}

abstract final class _FeedImageLoadingTestHelpers {
  static Future<({File cachedFile, Map<String, Completer<File>> downloads, List<String> providerStarts})>
  holdDownloads({required MockStaticMapCacheManager cacheManager}) async {
    final cachedFile = await cacheManager.getSingleFile('https://maps.cataqui.com/static/v1/fixture_reference.webp');
    final downloads = <String, Completer<File>>{};
    final providerStarts = <String>[];
    when(
      () => cacheManager.getSingleFile(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (invocation) => downloads.putIfAbsent(invocation.namedArguments[#key]! as String, Completer<File>.new).future,
    );
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((invocation) {
      final key = invocation.namedArguments[#key]! as String;
      providerStarts.add(key);
      return Stream.fromFuture(
        downloads
            .putIfAbsent(key, Completer<File>.new)
            .future
            .then((file) => FileInfo(file, FileSource.Cache, DateTime.utc(2100), key)),
      );
    });
    return (cachedFile: cachedFile, downloads: downloads, providerStarts: providerStarts);
  }

  static StaticMapRequest request(WidgetTester tester, String imageUrl) {
    return StaticMapRequest.forSize(imageUrl: imageUrl, size: .tall)!;
  }

  static Future<void> pump({
    required WidgetTester tester,
    required FakeFeedState feedState,
    required MockStaticMapCacheManager cacheManager,
    Size? screenSize,
  }) async {
    if (screenSize != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screenSize;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
    }
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
