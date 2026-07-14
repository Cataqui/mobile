import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'feed_view_test_helpers.dart';

void main() {
  setUp(FeedViewTestHelpers.mockMapChannels);

  group('FeedView map sequencing', () {
    testWidgets('when the feed loads with multiple jobs, it should mount only the first card MapLibreMap', (
      tester,
    ) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      expect(find.byType(MapLibreMap), findsOneWidget);
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    testWidgets('when the first map fires onMapIdle, it should mount the second card MapLibreMap', (tester) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      final firstMap = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
      firstMap.onStyleLoadedCallback?.call();
      firstMap.onMapIdle?.call();
      await tester.pump();

      expect(find.byType(MapLibreMap), findsNWidgets(2));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    testWidgets('when swiping before onMapIdle fires, the onNext fallback should mount the next card map', (
      tester,
    ) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
      await tester.pump();

      expect(find.byType(MapLibreMap), findsNWidgets(2));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    testWidgets(
      'when swiping to a card whose map is already ready, it should keep both immediately swipeable maps mounted',
      (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );

        final firstMap = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
        firstMap.onStyleLoadedCallback?.call();
        firstMap.onMapIdle?.call();
        await tester.pump();

        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
        await tester.pump();

        expect(find.byType(MapLibreMap), findsNWidgets(2));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      },
    );
  });
}
