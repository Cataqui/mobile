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

Widget _goldenScenario({required FakeFeedState feedState, bool hasSeenSwipeFeedHint = true}) {
  return SizedBox(
    width: 390,
    height: 780,
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
  group('FeedView Golden Tests', () {
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
  });
}
