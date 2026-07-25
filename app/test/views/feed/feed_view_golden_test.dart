import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locale/locale.dart';

import 'feed_view_test_helpers.dart';

class _FixedAppStorageState extends AppStorageState {
  _FixedAppStorageState({required this.hasSeenSwipeFeedHint});

  final bool hasSeenSwipeFeedHint;

  @override
  Future<AppStorageData> build() {
    final data = AppStorageData(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint);
    state = AsyncData(data);
    return Future<AppStorageData>.value(data);
  }
}

Widget _goldenScenario({required FakeFeedState feedState, bool hasSeenSwipeFeedHint = true, double height = 780}) {
  return SizedBox(
    width: 390,
    height: height,
    child: TickerMode(
      enabled: false,
      child: FeedViewTestHelpers.buildApp(
        disableAnimations: true,
        child: ProviderScope(
          overrides: [
            feedStateProvider.overrideWith(() => feedState),
            appStorageStateProvider.overrideWith(
              () => _FixedAppStorageState(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint),
            ),
          ],
          child: const FeedView(),
        ),
      ),
    ),
  );
}

void main() {
  const compactScenarioHeight = 400.0;
  late Translations i18n;

  group('FeedView Golden Tests', () {
    setUpAll(() async {
      i18n = await AppLocale.ptBr.build();
    });

    setUp(FeedViewTestHelpers.mockMapChannels);

    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'feed_view_states',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(GoldenTestGroup));

        return null;
      },
      builder: () {
        return GoldenTestGroup(
          scenarioConstraints: const BoxConstraints.tightFor(width: 390, height: 780),
          children: [
            GoldenTestScenario(
              name: 'loading',
              child: _goldenScenario(feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>())),
            ),
            GoldenTestScenario(
              name: 'error',
              child: _goldenScenario(
                feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('test error'), StackTrace.current)),
              ),
            ),
            GoldenTestScenario(
              name: 'offline',
              child: _goldenScenario(
                feedState: FakeFeedState(
                  initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'empty',
              child: _goldenScenario(
                feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataEmpty())),
              ),
            ),
            GoldenTestScenario(
              name: 'data with jobs',
              child: _goldenScenario(
                feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithJobs(count: 3))),
              ),
            ),
          ],
        );
      },
    );

    goldenTest(
      'when the empty state fits above the search area, it should remain centered in the view',
      fileName: 'feed_view_empty_state_centered',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));

        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataEmpty())),
        );
      },
    );

    goldenTest(
      'when the empty state is taller than the space above the search area, it should show scrollable content',
      fileName: 'feed_view_empty_state_compact',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));

        return null;
      },
      builder: () {
        return _goldenScenario(
          height: compactScenarioHeight,
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataEmpty())),
        );
      },
    );

    goldenTest(
      'when scrolling a compact empty state to the end, it should show the action above the search area',
      fileName: 'feed_view_empty_state_compact_scrolled',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        return null;
      },
      builder: () {
        return _goldenScenario(
          height: compactScenarioHeight,
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataEmpty())),
        );
      },
    );

    goldenTest(
      'when swiping through all available jobs, it should show the end state',
      fileName: 'feed_view_swiped_end_state',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithPaginationEnd())),
        );
      },
    );

    goldenTest(
      'when loading more jobs after swiping, it should show the loading more jobs state',
      fileName: 'feed_view_swiped_loading_more_state',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(
            initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithLoadingMore()),
            getFeedJobsResult: ({required fetchNextPage}) => Completer<void>().future,
          ),
        );
      },
    );

    goldenTest(
      'when an error occurs loading more jobs after swiping, it should show the loading more jobs error state',
      fileName: 'feed_view_swiped_loading_more_error_state',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithPaginationError())),
        );
      },
    );

    goldenTest(
      'when an offline error occurs loading more jobs after swiping, it should show the offline error state',
      fileName: 'feed_view_swiped_offline_error_state',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        await FeedViewTestHelpers.swipeAwayCurrentJob(tester);

        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(
            initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithOfflinePaginationError()),
          ),
        );
      },
    );

    goldenTest(
      'when feed has job data and the swipe hint has not been seen, it should show the overlay on top of the feed',
      fileName: 'feed_view_swipe_hint_visible',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithJobs(count: 1))),
          hasSeenSwipeFeedHint: false,
        );
      },
    );

    goldenTest(
      'when feed has job data and the user has already seen the hint, it should not show the overlay',
      fileName: 'feed_view_swipe_hint_hidden',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataWithJobs(count: 1))),
        );
      },
    );

    goldenTest(
      'when the current city button is tapped, it should show the approved location availability message',
      fileName: 'feed_view_location_availability_sheet',
      whilePerforming: (tester) async {
        await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(MaterialApp));
        await tester.tap(find.text(i18n.feed.locationAvailability.cityLabel));
        await tester.pumpAndSettle();
        final sheetImageFinder = find.descendant(
          of: find.byKey(const Key('mateo_bottom_sheet_surface')),
          matching: find.byType(Image),
        );
        final sheetImage = tester.widget<Image>(sheetImageFinder);
        await tester.runAsync(() async {
          await precacheImage(sheetImage.image, tester.element(sheetImageFinder));
        });
        await tester.pumpAndSettle();
        return null;
      },
      builder: () {
        return _goldenScenario(
          feedState: FakeFeedState(initialAsyncValue: AsyncData(FeedViewTestHelpers.feedDataEmpty())),
        );
      },
    );
  });
}
