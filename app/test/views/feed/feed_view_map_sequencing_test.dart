import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'feed_view_test_helpers.dart';

void main() {
  setUp(FeedViewTestHelpers.mockGoogleMapsPlatform);

  group('FeedView map sequencing', () {
    testWidgets(
      'when the first-time swipe hint is appearing, it should prepare the current and next job location maps behind it',
      (tester) async {
        await tester.pumpWidget(
          FeedViewTestHelpers.buildFeedViewApp(
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
            hasSeenSwipeFeedHint: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(GoogleMap), findsNWidgets(2));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      },
    );

    testWidgets('when the feed first shows multiple jobs, it should prepare the current and next job location maps', (
      tester,
    ) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      expect(find.byType(GoogleMap), findsNWidgets(2));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    testWidgets('when swiping before the first location map finishes loading, it should show the next job map', (
      tester,
    ) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
      await tester.pump();

      expect(find.byType(GoogleMap), findsNWidgets(3));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    testWidgets(
      'when swiping after the next location map is prepared, it should keep nearby job maps ready for swiping',
      (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );

        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
        await tester.pump();

        expect(find.byType(GoogleMap), findsNWidgets(3));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      },
    );

    testWidgets('when swiping forward and back, it should reuse the previous job location map', (tester) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      final firstCardMap = find.descendant(
        of: find.byKey(const ValueKey('mateo_y_snap_list_card_job_0')),
        matching: find.byType(GoogleMap),
      );
      final firstMapState = tester.state(firstCardMap);

      await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
      await tester.drag(find.text('Garçom para Fim de Semana 1'), const Offset(0, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 800));

      expect(tester.state(firstCardMap), same(firstMapState));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

    testWidgets('when swiping through several jobs, it should retain only the previous, current, and next maps', (
      tester,
    ) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 5)),
      );

      await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
      await FeedViewTestHelpers.swipeAwayCurrentJob(tester, title: 'Garçom para Fim de Semana 1');
      await FeedViewTestHelpers.swipeAwayCurrentJob(tester, title: 'Garçom para Fim de Semana 2');

      expect(find.byType(GoogleMap), findsNWidgets(3));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });
  });
}
