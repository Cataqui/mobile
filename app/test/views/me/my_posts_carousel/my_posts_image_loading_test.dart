import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:cataqui_app/views/me/my_posts_carousel/my_posts_carousel.dart';
import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:clock/clock.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../utils/static_map_cache_test_helpers.dart';
import '../../../utils/test_app.dart';
import '../fake_my_posts_state.dart';

void main() {
  late MockStaticMapCacheManager cacheManager;
  late List<UserJobSummaryDto> jobs;
  late FakeMyPostsState postsState;
  late MockStaticMapFile file;

  setUp(() {
    cacheManager = StaticMapCacheTestHelpers.create();
    file = MockStaticMapFile();
    when(
      file.readAsBytes,
    ).thenAnswer((_) async => const LocalFileSystem().file('test/fixtures/static_map.jpg').readAsBytesSync());
    jobs = [
      for (var index = 0; index < 20; index++)
        UserJobSummaryDto.fixture().copyWith(
          jobId: 'map-job-$index',
          createdAt: DateTime.utc(2026, 9, 30, 12),
          location: UserJobSummaryDto.fixture().location.copyWith(
            latitude: -23.5 + index * .01,
            imageUrl: '${UserJobSummaryDto.fixture().location.imageUrl}/job=$index',
          ),
        ),
    ];
    postsState = FakeMyPostsState(AsyncData(MyPostsData(userId: 'test-user', jobs: jobs, hasMore: false)));
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  for (final width in [280.0, 600.0]) {
    testWidgets('when flinging a $width pixel carousel, it should defer new maps above one viewport per second', (
      tester,
    ) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
        await MyPostsImageLoadingTestHelpers.pump(
          tester,
          cacheManager: cacheManager,
          postsState: postsState,
          width: width,
        );
        final listFinder = find.byKey(const ValueKey('me_posts_list'));
        final list = tester.widget<ListView>(listFinder);
        final position = list.controller!.position;
        final listContext = tester.element(listFinder);
        expect(position.viewportDimension, width);
        for (final direction in [-1, 1]) {
          expect(list.physics!.recommendDeferredLoading(direction * (width - 1), position, listContext), isFalse);
          expect(list.physics!.recommendDeferredLoading(direction * (width + 1), position, listContext), isTrue);
        }
        await MyPostsImageLoadingTestHelpers.cleanUp(tester);
      });
    });
  }

  testWidgets('when flinging faster than a card passes, it should defer uncached maps on cards flying past', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      final pendingStreams = MyPostsImageLoadingTestHelpers.holdMaps(
        cacheManager: cacheManager,
        file: file,
        urls: {
          for (final job in jobs.skip(2)) StaticMapRequest(imageUrl: job.location.imageUrl, size: .pixels960x960).url,
        },
      );
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      await MyPostsImageLoadingTestHelpers.dragAndHold(tester, const Offset(-800, 0));
      await tester.fling(find.byKey(const ValueKey('me_posts_list')), const Offset(-200, 0), 550);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final position = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position;
      expect(position.isScrollingNotifier.value, isTrue);
      expect(
        tester.widgetList<MyPostCard>(find.byType(MyPostCard)).any((card) => card.job?.jobId == jobs[4].jobId),
        isTrue,
      );
      final fastFrameRequests = pendingStreams.keys.toSet();

      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
      await tester.runAsync(() async {
        for (final entry in pendingStreams.entries) {
          entry.value.add(MyPostsImageLoadingTestHelpers.fileInfo(url: entry.key, file: file));
          unawaited(entry.value.close());
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(fastFrameRequests, isNot(contains(requests[4].url)));
      expect(fastFrameRequests, isNot(contains(requests[5].url)));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('when opening many posts, it should prepare three upcoming maps without mounting their cards', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      final streamedUrls = verify(
        () => cacheManager.getFileStream(
          captureAny(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).captured.cast<String>();
      expect(streamedUrls.toSet(), {
        for (final index in [0, 1, 2, 3]) requests[index].url,
      });
      expect(
        verify(
          () => cacheManager.getSingleFile(
            captureAny(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
          ),
        ).captured,
        [requests[4].url],
      );
      expect(find.byType(MyPostCard), findsNWidgets(2));
      for (final index in [2, 3]) {
        final status = PaintingBinding.instance.imageCache.statusForKey(
          CachedNetworkImageProvider(
            requests[index].url,
            cacheKey: requests[index].cacheKey,
            cacheManager: cacheManager,
          ),
        );
        expect(status.keepAlive, isTrue, reason: 'The upcoming map should already be decoded for a swipe.');
      }
      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
    });
  });

  testWidgets('when replacing posts while browsing, it should prepare the new maps and retain a bounded window', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      clearInteractions(cacheManager);
      final refreshedJobs = [
        for (final job in jobs)
          job.copyWith(
            location: job.location.copyWith(
              latitude: job.location.latitude + 1,
              imageUrl: '${job.location.imageUrl}/revision=2',
            ),
          ),
      ];
      postsState.showData(MyPostsData(userId: 'test-user', jobs: refreshedJobs, hasMore: false));
      await tester.pump();
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 600));
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, refreshedJobs);
      expect(
        verify(
          () => cacheManager.getFileStream(
            captureAny(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
            withProgress: any(named: 'withProgress'),
          ),
        ).captured.toSet(),
        {
          for (final index in [0, 1, 2, 3]) requests[index].url,
        },
      );
      expect(
        verify(
          () => cacheManager.getSingleFile(
            captureAny(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
          ),
        ).captured,
        [requests[4].url],
      );
      expect(find.byType(MyPostCard), findsNWidgets(2));
      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
    });
  });
  testWidgets('when dragging back toward earlier posts, it should prepare the next three maps to the left', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      await MyPostsImageLoadingTestHelpers.dragAndHold(tester, const Offset(-4480, 0));
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 200));
      clearInteractions(cacheManager);

      await MyPostsImageLoadingTestHelpers.dragAndHold(tester, const Offset(100, 0));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 200));
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      final position = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position;
      final firstVisible = (position.pixels / 372).floor();
      expect(firstVisible, greaterThan(4));
      expect(
        verify(
          () => cacheManager.getFileStream(
            captureAny(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
            withProgress: any(named: 'withProgress'),
          ),
        ).captured.toSet(),
        {requests[firstVisible].url, requests[firstVisible - 1].url, requests[firstVisible - 2].url},
      );
      expect(
        verify(
          () => cacheManager.getSingleFile(
            captureAny(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
          ),
        ).captured,
        [requests[firstVisible - 3].url],
      );
      expect(find.byType(MyPostCard).evaluate().length, lessThanOrEqualTo(3));
      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
    });
  });

  testWidgets('when leaving while upcoming maps load, it should finish active work without requesting farther maps', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      final pendingStreams = MyPostsImageLoadingTestHelpers.holdMaps(
        cacheManager: cacheManager,
        file: file,
        urls: {
          StaticMapRequest(imageUrl: jobs[2].location.imageUrl, size: .pixels960x960).url,
          StaticMapRequest(imageUrl: jobs[3].location.imageUrl, size: .pixels960x960).url,
        },
      );
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      expect(pendingStreams.keys.toSet(), {requests[2].url, requests[3].url});
      verifyNever(
        () => cacheManager.getSingleFile(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      );

      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
      await tester.runAsync(() async {
        for (final entry in pendingStreams.entries) {
          entry.value.add(MyPostsImageLoadingTestHelpers.fileInfo(url: entry.key, file: file));
          unawaited(entry.value.close());
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      for (final index in [2, 3]) {
        expect(
          PaintingBinding.instance.imageCache
              .statusForKey(
                CachedNetworkImageProvider(
                  requests[index].url,
                  cacheKey: requests[index].cacheKey,
                  cacheManager: cacheManager,
                ),
              )
              .keepAlive,
          isTrue,
          reason: 'Already active image work should have finished after the carousel closed.',
        );
      }
      verifyNever(
        () => cacheManager.getSingleFile(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('when flinging past many posts, it should prepare the centered landing map and next passing map first', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      final pendingStreams = MyPostsImageLoadingTestHelpers.holdMaps(
        cacheManager: cacheManager,
        file: file,
        urls: {
          for (final job in jobs.skip(2)) StaticMapRequest(imageUrl: job.location.imageUrl, size: .pixels960x960).url,
        },
      );
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      expect(pendingStreams.keys.toSet(), {requests[2].url, requests[3].url});

      await tester.fling(find.byKey(const ValueKey('me_posts_list')), const Offset(-800, 0), 2500);
      await tester.pump();
      final position = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position;
      final flingStart = position.pixels;
      final startingUrls = pendingStreams.keys.toSet();
      await tester.runAsync(() async {
        for (final url in [requests[2].url, requests[3].url]) {
          pendingStreams[url]!.add(MyPostsImageLoadingTestHelpers.fileInfo(url: url, file: file));
          unawaited(pendingStreams[url]!.close());
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      final newlyPreparedUrls = pendingStreams.keys.where((url) => !startingUrls.contains(url)).toList();
      expect(newlyPreparedUrls, [requests[7].url, requests[4].url]);
      expect(position.pixels, closeTo(flingStart, 1));
      verifyNever(
        () => cacheManager.getSingleFile(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      );

      await tester.runAsync(() async {
        pendingStreams[requests[7].url]!.add(MyPostsImageLoadingTestHelpers.fileInfo(url: requests[7].url, file: file));
        unawaited(pendingStreams[requests[7].url]!.close());
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(pendingStreams.keys.where((url) => !startingUrls.contains(url)).toList(), [
        requests[7].url,
        requests[4].url,
        requests[6].url,
      ]);
      expect(position.pixels, closeTo(flingStart, 1));

      await tester.pump(const Duration(seconds: 6));
      final firstLanding = (position.pixels / 372).floor();
      final lastLanding = ((position.pixels + position.viewportDimension) / 372).ceil() - 1;
      expect(firstLanding, 6);
      expect(lastLanding, 7);

      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
      await tester.runAsync(() async {
        for (final entry in pendingStreams.entries) {
          if (entry.value.isClosed) continue;
          entry.value.add(MyPostsImageLoadingTestHelpers.fileInfo(url: entry.key, file: file));
          unawaited(entry.value.close());
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('when an upcoming map fails, it should continue preparing others and retry when that post is viewed', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      var failedMapAttempts = 0;
      when(
        () => cacheManager.getFileStream(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer((invocation) {
        final url = invocation.positionalArguments.first as String;
        if (url == StaticMapRequest(imageUrl: jobs[2].location.imageUrl, size: .pixels960x960).url) {
          failedMapAttempts += 1;
          if (failedMapAttempts == 1) return Stream<FileResponse>.error(Exception('prefetch unavailable'));
        }
        return Stream<FileResponse>.value(MyPostsImageLoadingTestHelpers.fileInfo(url: url, file: file));
      });
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      expect(failedMapAttempts, 1);
      verify(() => cacheManager.getSingleFile(requests[4].url, key: requests[4].cacheKey)).called(1);

      await MyPostsImageLoadingTestHelpers.dragAndHold(tester, const Offset(-800, 0));
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(failedMapAttempts, 2);
      expect(
        PaintingBinding.instance.imageCache
            .statusForKey(
              CachedNetworkImageProvider(requests[2].url, cacheKey: requests[2].cacheKey, cacheManager: cacheManager),
            )
            .keepAlive,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
    });
  });

  testWidgets('when the screen narrows and posts refresh to one item, it should not prepare maps outside the list', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      await MyPostsImageLoadingTestHelpers.pump(tester, cacheManager: cacheManager, postsState: postsState);
      clearInteractions(cacheManager);
      tester.view.physicalSize = const Size(280, 900);
      final refreshedJobs = [
        jobs.first.copyWith(
          location: jobs.first.location.copyWith(
            latitude: -20.5,
            imageUrl: '${jobs.first.location.imageUrl}/revision=2',
          ),
        ),
      ];
      postsState.showData(MyPostsData(userId: 'test-user', jobs: refreshedJobs, hasMore: false));
      await tester.pump();
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 200));
      final request = MyPostsImageLoadingTestHelpers.requests(tester, refreshedJobs).single;
      expect(
        verify(
          () => cacheManager.getFileStream(
            captureAny(),
            key: any(named: 'key'),
            headers: any(named: 'headers'),
            withProgress: any(named: 'withProgress'),
          ),
        ).captured,
        [request.url],
      );
      verifyNever(
        () => cacheManager.getSingleFile(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      );
      expect(find.byType(MyPostCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
    });
  });

  testWidgets('when posts are hidden and shown again, it should pause queued map preparation and resume on return', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 10, 1, 12)), () async {
      final prefetchEnabled = ValueNotifier(true);
      addTearDown(prefetchEnabled.dispose);
      final pendingStreams = MyPostsImageLoadingTestHelpers.holdMaps(
        cacheManager: cacheManager,
        file: file,
        urls: {
          StaticMapRequest(imageUrl: jobs[2].location.imageUrl, size: .pixels960x960).url,
          StaticMapRequest(imageUrl: jobs[3].location.imageUrl, size: .pixels960x960).url,
        },
      );
      await MyPostsImageLoadingTestHelpers.pump(
        tester,
        cacheManager: cacheManager,
        postsState: postsState,
        prefetchEnabled: prefetchEnabled,
      );
      final requests = MyPostsImageLoadingTestHelpers.requests(tester, jobs);
      prefetchEnabled.value = false;
      await tester.pump();
      await tester.runAsync(() async {
        for (final entry in pendingStreams.entries) {
          entry.value.add(MyPostsImageLoadingTestHelpers.fileInfo(url: entry.key, file: file));
          unawaited(entry.value.close());
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      verifyNever(
        () => cacheManager.getSingleFile(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
        ),
      );

      prefetchEnabled.value = true;
      await tester.pump();
      await tester.pump();
      verify(() => cacheManager.getSingleFile(requests[4].url, key: requests[4].cacheKey)).called(1);
      expect(tester.takeException(), isNull);
      await MyPostsImageLoadingTestHelpers.cleanUp(tester);
    });
  });
}

abstract final class MyPostsImageLoadingTestHelpers {
  static Future<void> pump(
    WidgetTester tester, {
    required MockStaticMapCacheManager cacheManager,
    required FakeMyPostsState postsState,
    ValueNotifier<bool>? prefetchEnabled,
    double width = 390,
  }) async {
    tester.view
      ..physicalSize = Size(width, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TestApp(
        providerOverrides: [
          staticMapCacheManagerProvider.overrideWith((ref) => cacheManager),
          myPostsStateProvider.overrideWith(() => postsState),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final carousel = MyPostsCarousel(viewportWidth: constraints.maxWidth, rightOverflow: 0);
            if (prefetchEnabled == null) return carousel;
            return ValueListenableBuilder<bool>(
              valueListenable: prefetchEnabled,
              child: carousel,
              builder: (context, enabled, child) => TickerMode(enabled: enabled, child: child!),
            );
          },
        ),
      ),
    );
    // Map codec work runs outside FakeAsync; settle after loading those images.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await StaticMapCacheTestHelpers.loadImages(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 600));
  }

  static List<StaticMapRequest> requests(WidgetTester tester, List<UserJobSummaryDto> jobs) {
    return [for (final job in jobs) StaticMapRequest(imageUrl: job.location.imageUrl, size: .pixels960x960)];
  }

  static FileInfo fileInfo({required String url, required MockStaticMapFile file}) =>
      FileInfo(file, FileSource.Cache, DateTime.utc(2100), url);

  static Map<String, StreamController<FileResponse>> holdMaps({
    required MockStaticMapCacheManager cacheManager,
    required MockStaticMapFile file,
    required Set<String> urls,
  }) {
    final pendingStreams = <String, StreamController<FileResponse>>{};
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((invocation) {
      final url = invocation.positionalArguments.first as String;
      if (urls.contains(url)) {
        return (pendingStreams[url] ??= StreamController<FileResponse>()).stream;
      }
      return Stream<FileResponse>.value(fileInfo(url: url, file: file));
    });
    return pendingStreams;
  }

  static Future<void> dragAndHold(WidgetTester tester, Offset offset) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('me_posts_list'))));
    await gesture.moveBy(Offset(offset.dx.sign * 24, 0), timeStamp: const Duration(milliseconds: 10));
    await tester.pump();
    await gesture.moveBy(offset, timeStamp: const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up(timeStamp: const Duration(milliseconds: 400));
    await tester.pump();
  }

  static Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }
}
