import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'feed_view_test_helpers.dart';

void main() {
  setUp(FeedViewTestHelpers.mockGoogleMapsPlatform);

  group('FeedView map sequencing', () {
    testWidgets('keeps map geometry stable when keyboard hides bottom safe padding', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final keyboardOpen = ValueNotifier<bool>(false);
      addTearDown(keyboardOpen.dispose);
      await tester.pumpWidget(
        FeedViewTestHelpers.buildApp(
          providerOverrides: FeedViewTestHelpers.buildProviderOverrides(
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 1, hasMore: false)),
            hasSeenSwipeFeedHint: true,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: keyboardOpen,
            builder: (context, open, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewPadding: const EdgeInsets.only(bottom: 34),
                padding: EdgeInsets.only(bottom: open ? 0 : 34),
                viewInsets: EdgeInsets.only(bottom: open ? 300 : 0),
              ),
              child: child!,
            ),
            child: const FeedView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mapFinder = find.byType(GoogleMap).first;
      final mapRect = tester.getRect(mapFinder);
      final mapState = tester.state(mapFinder);
      keyboardOpen.value = true;
      await tester.pumpAndSettle();
      expect(tester.getRect(mapFinder), mapRect);
      expect(tester.state(mapFinder), same(mapState));
      keyboardOpen.value = false;
      await tester.pumpAndSettle();
      expect(tester.getRect(mapFinder), mapRect);
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });

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

        expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(2));
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

      expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(2));
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

      expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(3));
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

        expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(3));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      },
    );

    testWidgets('when swiping forward and back, it should reuse the previous job location map', (tester) async {
      await FeedViewTestHelpers.pumpFeedView(
        tester: tester,
        feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
      );

      final firstCardMap = find.byType(GoogleMap, skipOffstage: false).first;
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

      expect(find.byType(GoogleMap, skipOffstage: false), findsNWidgets(3));
      await FeedViewTestHelpers.pumpAndCleanUp(tester);
    });
  });
}
