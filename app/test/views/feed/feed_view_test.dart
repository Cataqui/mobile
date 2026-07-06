import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qui/qui.dart';

import 'feed_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedView', () {
    group('chrome', () {
      testWidgets('when the view renders in any state, it should not show the location button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text('São Paulo'), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the view renders in any state, it should not show the search bar', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.searchPlaceholder), findsNothing);
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

    group('initial offline error', () {
      testWidgets('when initial error is offline, it should render the QuiOfflineErrorState', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.byType(QuiOfflineErrorState), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should render the offline title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.offline.title), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should render the offline description', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.offline.description), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should render the offline retry button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.offline.retryButtonTitle), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when initial error is offline, it should not render the generic error title', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.text(i18n.feed.error.title), findsNothing);
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
        expect(find.text(i18n.feed.empty.description), findsOneWidget);
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
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.text(i18n.feed.empty.adjustAreaButtonTitle));
        await tester.pump(const Duration(milliseconds: 900));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should not render QuiTikTokFeed', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is QuiTikTokFeed), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('data — with jobs', () {
      testWidgets('when feedData has jobs, it should render QuiTikTokFeed', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is QuiTikTokFeed), findsOneWidget);
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

      testWidgets('when the visible job card tap action runs, it should navigate to that job detail', (tester) async {
        final goRouter = GoRouter(initialLocation: '/', routes: [$feedRoute, $jobRoute]);
        FeedViewTestHelpers.mockHapticFeedback(tester);
        FeedViewTestHelpers.mockPlatformViews(tester);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              feedStateProvider.overrideWith(() => FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3))),
              goRouterProvider.overrideWithValue(goRouter),
            ],
            child: MaterialApp.router(
              theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
              routerConfig: goRouter,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump();
        final feedJobCard = find.byType(FeedJobCard).first;
        final tapAnimation = tester.widget<QuiTapAnimation>(
          find.descendant(of: feedJobCard, matching: find.byType(QuiTapAnimation)),
        );
        await tapAnimation.onPressed!(Future<void>.value());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.byType(JobView), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feed cards are built, it should key them by jobId', (tester) async {
        final feedData = FeedViewTestHelpers.feedDataWithJobs(count: 3);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => feedData),
        );
        await tester.pump();

        final feed = tester.widget<QuiTikTokFeed<FeedJobDto>>(find.byType(QuiTikTokFeed<FeedJobDto>));
        expect(feed.items.keyBuilder?.call(feedData.jobs.first, 0), feedData.jobs.first.jobId);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('inTransition SlideTransition', () {
      // Scopes the SlideTransition finder to only those inside QuiWidgetTransition
      // to avoid false matches from MaterialPageRoute's route transition SlideTransition.
      Finder _quiSlideTransition() =>
          find.descendant(of: find.byType(QuiWidgetTransition), matching: find.byType(SlideTransition));

      testWidgets('when feedState is data, it should wrap the entering widget in a SlideTransition', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(_quiSlideTransition(), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should not include a SlideTransition', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        await tester.pump();
        expect(_quiSlideTransition(), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is error, it should not include a SlideTransition', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(_quiSlideTransition(), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when configured, it should retain both 600 millisecond transition durations', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );

        final transition = tester.widget<QuiWidgetTransition>(find.byType(QuiWidgetTransition));
        expect(
          (outDuration: transition.outDuration, inDuration: transition.inDuration),
          (outDuration: const Duration(milliseconds: 600), inDuration: const Duration(milliseconds: 600)),
        );
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when data starts entering, it should retain the 0.30 vertical slide offset', (tester) async {
        final feedState = FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>());
        FeedViewTestHelpers.mockHapticFeedback(tester);
        FeedViewTestHelpers.mockPlatformViews(tester);
        await tester.pumpWidget(FeedViewTestHelpers.buildFeedViewApp(feedState: feedState));
        await tester.pump();

        feedState.emittedValue = AsyncData(FeedViewTestHelpers.feedDataEmpty());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();

        final slide = tester.widget<SlideTransition>(_quiSlideTransition());
        expect(slide.position.value.dy, closeTo(0.30, 0.001));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when data is halfway through entering, it should retain the easeOutCubic slide curve', (
        tester,
      ) async {
        final feedState = FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>());
        FeedViewTestHelpers.mockHapticFeedback(tester);
        FeedViewTestHelpers.mockPlatformViews(tester);
        await tester.pumpWidget(FeedViewTestHelpers.buildFeedViewApp(feedState: feedState));
        await tester.pump();

        feedState.emittedValue = AsyncData(FeedViewTestHelpers.feedDataEmpty());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 300));

        final slide = tester.widget<SlideTransition>(_quiSlideTransition());
        expect(slide.position.value.dy, closeTo(0.0375, 0.002));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when data is halfway through entering, it should retain the easeOutCubic fade', (tester) async {
        final feedState = FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>());
        FeedViewTestHelpers.mockHapticFeedback(tester);
        FeedViewTestHelpers.mockPlatformViews(tester);
        await tester.pumpWidget(FeedViewTestHelpers.buildFeedViewApp(feedState: feedState));
        await tester.pump();

        feedState.emittedValue = AsyncData(FeedViewTestHelpers.feedDataEmpty());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 300));

        final opacityValues = tester
            .widgetList<FadeTransition>(
              find.descendant(of: find.byType(QuiWidgetTransition), matching: find.byType(FadeTransition)),
            )
            .map((fade) => fade.opacity.value);
        expect(opacityValues, contains(closeTo(0.875, 0.002)));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
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

      testWidgets('when feedData is empty, it should wrap the empty widget in a KeyedSubtree with ValueKey feed_data', (
        tester,
      ) async {
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
      });

      testWidgets('when feedData has jobs, it should wrap the data widget in a KeyedSubtree with ValueKey feed_data', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
        );
        await tester.pump();
        // Same 'feed_data' key as the empty state — keeps the same entry
        // so empty→jobs is an in-place update, not a transition.
        expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });
  });
}
