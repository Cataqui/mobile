import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks.dart';
import '../../utils/static_map_cache_test_helpers.dart';
import '../../utils/test_app.dart';
import 'feed_view_test_helpers.dart';

void main() {
  late MockStaticMapCacheManager manager;
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    manager = StaticMapCacheTestHelpers.create(fixturePath: 'test/fixtures/static_map_v1_tall.webp');
  });

  goldenTest(
    'when a short feed shows native map credit, it should keep the complete attribution below job details',
    fileName: 'feed_native_map_attribution_short',
    constraints: const BoxConstraints.tightFor(width: 392, height: 357),
    builder: () => _FeedImageGoldenHelpers.build(manager),
    pumpWidget: TestApp.pumpGolden,
    pumpBeforeTest: TestApp.settleGolden,
    whilePerforming: (tester) async {
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.pumpAndSettle();
      return null;
    },
  );

  goldenTest(
    'when a tiny feed scrolls to the native map footer, it should show the complete attribution in its rounded card',
    fileName: 'feed_native_map_attribution_tiny_scrolled',
    constraints: const BoxConstraints.tightFor(width: 392, height: 225),
    builder: () => _FeedImageGoldenHelpers.build(manager),
    pumpWidget: TestApp.pumpGolden,
    pumpBeforeTest: TestApp.settleGolden,
    whilePerforming: (tester) async {
      await StaticMapCacheTestHelpers.loadImages(tester);
      await tester.pumpAndSettle();
      await FeedViewTestHelpers.scrollToEnd(
        tester: tester,
        viewport: find.byKey(const ValueKey('feed_map_viewport_job_0')),
      );
      return null;
    },
  );
}

abstract final class _FeedImageGoldenHelpers {
  static Widget build(MockStaticMapCacheManager manager) => TestApp.screen(
    mediaQueryData: const MediaQueryData(disableAnimations: true),
    providerOverrides: [
      ...FeedViewTestHelpers.buildProviderOverrides(
        feedState: FakeFeedState(
          initialAsyncValue: AsyncData<FeedData>(FeedViewTestHelpers.feedDataWithJobs(hasMore: false)),
        ),
        hasSeenSwipeFeedHint: true,
      ),
      staticMapCacheManagerProvider.overrideWith((ref) => manager),
    ],
    child: const TickerMode(enabled: false, child: FeedView()),
  );
}
