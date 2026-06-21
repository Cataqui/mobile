import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

import 'feed_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedView', () {
    group('chrome', () {
      testWidgets('when the view renders in any state, it should show the São Paulo location button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text('São Paulo'), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the view renders in any state, it should show the search bar placeholder', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.searchPlaceholder), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the location button is tapped, it should not throw', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        await tester.tap(find.text('São Paulo'));
        await tester.pump(const Duration(milliseconds: 900));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('initial loading', () {
      testWidgets('when feedState is loading, it should render the initial-loading QuiOrbit', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.byType(QuiOrbit), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should not render FeedJobCard', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.byType(FeedJobCard), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should not render error title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.text(i18n.feed.error.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should not render empty title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.text(i18n.feed.empty.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('initial error', () {
      testWidgets('when feedState is error, it should render the error title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.title), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should render the error description', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.description), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should render the retry button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.retryButtonTitle), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should not render QuiOrbit', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.byType(QuiOrbit), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should not render empty title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.title), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('data — empty', () {
      testWidgets('when feedData is empty, it should render the empty title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.title), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should render the empty description', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(
          find.text(i18n.feed.empty.description),
          findsOneWidget,
        );
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should render the adjust area button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.empty.adjustAreaButtonTitle), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the adjust area button is tapped, it should not throw', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        await tester.tap(find.text(i18n.feed.empty.adjustAreaButtonTitle));
        await tester.pump(const Duration(milliseconds: 900));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should not render QuiSwipeDeck', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is QuiSwipeDeck), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('data — with jobs', () {
      testWidgets('when feedData has jobs, it should render QuiSwipeDeck', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is QuiSwipeDeck), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should render FeedJobCard for the current job', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );
        await tester.pump();
        expect(find.text('Descarregar Caminhão'), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should render the dismiss QuiIconButton', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );
        await tester.pump();
        expect(find.byType(QuiIconButton), findsAtLeast(1));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the job card is tapped, it should not throw', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );
        await tester.pump();
        await tester.tap(find.text('Descarregar Caminhão'));
        await tester.pump(const Duration(milliseconds: 900));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('inTransition SlideTransition', () {
      // Scopes the SlideTransition finder to only those inside QuiWidgetTransition
      // to avoid false matches from MaterialPageRoute's route transition SlideTransition.
      Finder _quiSlideTransition() => find.descendant(
            of: find.byType(QuiWidgetTransition),
            matching: find.byType(SlideTransition),
          );

      testWidgets(
        'when feedState is data, it should wrap the entering widget in a SlideTransition',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
          );
          await tester.pump();
          expect(_quiSlideTransition(), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets(
        'when feedState is loading, it should not include a SlideTransition',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
          );
          await tester.pump();
          expect(_quiSlideTransition(), findsNothing);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets(
        'when feedState is error, it should not include a SlideTransition',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
          );
          await tester.pump();
          expect(_quiSlideTransition(), findsNothing);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );
    });

    group('feed state keys', () {
      // Each feed state must be wrapped in a KeyedSubtree with a unique key
      // so QuiWidgetTransition can detect state changes and animate between
      // them. Without distinct keys, transitions between same-type widgets
      // (e.g., Center→Center for loading→error) would be silently skipped.
      testWidgets(
        'when feedState is loading, it should wrap the loading widget in a KeyedSubtree with ValueKey feed_loading',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
          );
          expect(find.byKey(const ValueKey('feed_loading')), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets(
        'when feedState is error, it should wrap the error widget in a KeyedSubtree with ValueKey feed_error',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
          );
          await tester.pump();
          expect(find.byKey(const ValueKey('feed_error')), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets(
        'when feedData is empty, it should wrap the empty widget in a KeyedSubtree with ValueKey feed_data',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
          );
          await tester.pump();
          // Uses 'feed_data' (same as data with jobs) because empty IS data
          // — the FeedData state, not a separate loading/error state.
          // QuiWidgetTransition compares by (runtimeType + Key), and
          // the empty and non-empty builders both return Padding. Without
          // the shared KeyedSubtree, even empty→jobs would skip animation.
          expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );

      testWidgets(
        'when feedData has jobs, it should wrap the data widget in a KeyedSubtree with ValueKey feed_data',
        (tester) async {
          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          );
          await tester.pump();
          // Same 'feed_data' key as the empty state — keeps the same entry
          // so empty→jobs is an in-place update, not a transition.
          expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );
    });
  });
}
