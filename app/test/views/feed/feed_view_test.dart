import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/job/job_route.dart';
import 'package:cataqui_app/views/job/job_view.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:cataqui_app/widgets/offline_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import 'feed_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  group('FeedView', () {
    group('chrome', () {
      testWidgets('when the view renders in any state, it should show the current city button', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.text(i18n.feed.locationAvailability.cityLabel), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the current city button renders, it should provide a 48 pixel touch target', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );

        expect(tester.getSize(find.byType(MateoTextButton)).height, greaterThanOrEqualTo(48));
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the current city button is tapped, it should explain where Cataquí is available', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.tap(find.text(i18n.feed.locationAvailability.cityLabel));
        await tester.pumpAndSettle();

        expect(find.text(i18n.feed.locationAvailability.message), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the availability message is open and the close button is tapped, it should close the message', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.tap(find.text(i18n.feed.locationAvailability.cityLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(i18n.feed.locationAvailability.closeButtonTitle));
        await tester.pumpAndSettle();

        expect(find.text(i18n.feed.locationAvailability.message), findsNothing);
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
      testWidgets('when feedState is loading, it should render the initial-loading skeleton', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.byType(MateoSkeleton), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedState is loading, it should render the skeleton FeedJobCard', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
        );
        expect(find.byType(FeedJobCard), findsOneWidget);
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

      testWidgets('when feedState is error, it should not render skeleton loading', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: AsyncError(Exception('network error'), StackTrace.current)),
        );
        await tester.pump();
        expect(find.byType(MateoSkeleton), findsNothing);
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
      testWidgets('when initial error is offline, it should render the OfflineErrorState', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(
            initialAsyncValue: AsyncError(FeedViewTestHelpers.offlineDioException(), StackTrace.current),
          ),
        );
        await tester.pump();
        expect(find.byType(OfflineErrorState), findsOneWidget);
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

      testWidgets('when the adjust area button is tapped, it should explain where Cataquí is available', (
        tester,
      ) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.byKey(const ValueKey('feed_empty_adjust_area_button')));
        await tester.pumpAndSettle();

        expect(find.text(i18n.feed.locationAvailability.message), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData is empty, it should not render MateoYSnapList', (tester) async {
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is MateoYSnapList), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('data — with jobs', () {
      testWidgets('when feedData has jobs, it should render MateoYSnapList', (tester) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.byWidgetPredicate((w) => w is MateoYSnapList), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should render FeedJobCard for the current job', (tester) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.text('Descarregar Caminhão'), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the visible job card tap action runs, it should navigate to that job detail', (tester) async {
        final goRouter = GoRouter(initialLocation: '/', routes: [$feedRoute, $jobRoute]);
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        FeedViewTestHelpers.mockHapticFeedback(tester);
        FeedViewTestHelpers.mockPlatformViews(tester);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              feedStateProvider.overrideWith(
                () => FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
              ),
              sharedPreferencesAsyncProvider.overrideWithValue(prefs),
              goRouterProvider.overrideWithValue(goRouter),
            ],
            child: TestApp.router(routerConfig: goRouter),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump();
        final feedJobCard = find.byType(FeedJobCard).first;
        final tapAnimation = tester.widget<MateoTap>(find.descendant(of: feedJobCard, matching: find.byType(MateoTap)));
        await tapAnimation.onPressed!(Future<void>.value());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.byType(JobView), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feed cards are built, it should key them by jobId', (tester) async {
        final feedData = FeedViewTestHelpers.feedDataWithJobs(count: 3);
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => feedData),
          prefs: prefs,
        );
        await tester.pump();

        final feed = tester.widget<MateoYSnapList<FeedJobDto>>(find.byType(MateoYSnapList<FeedJobDto>));
        expect(feed.items.keyBuilder?.call(feedData.jobs.first, 0), feedData.jobs.first.jobId);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('feed state keys', () {
      // Each feed state must be wrapped in a KeyedSubtree with a unique key
      // so state changes are correctly detected. Without distinct keys,
      // Flutter would reuse the same element for same-type widgets
      // (e.g., Center→Center for loading→error).
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
        // The empty and non-empty builders both return different root
        // widgets, so the shared key keeps the element tree stable.
        expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when feedData has jobs, it should wrap the data widget in a KeyedSubtree with ValueKey feed_data', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);
        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        // Same 'feed_data' key as the empty state — keeps the same entry
        // so empty→jobs is an in-place update, not a transition.
        expect(find.byKey(const ValueKey('feed_data')), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });
    });

    group('swipe-up hint overlay', () {
      late MockSharedPreferencesAsync prefs;

      setUp(() {
        prefs = MockSharedPreferencesAsync();
        when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
      });

      testWidgets('when the user has not seen the hint, it should show the swipe-up hint overlay', (tester) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the user has not seen the hint, it should not show the overlay while the feed is loading', (
        tester,
      ) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(initialAsyncValue: const AsyncLoading<FeedData>()),
          prefs: prefs,
        );

        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the feed has no jobs, it should not show the swipe-up hint overlay', (tester) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the user has already seen the hint, it should not show the overlay', (tester) async {
        when(() => prefs.getBool(any())).thenAnswer((_) async => true);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );
        await tester.pump();
        expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets(
        'when the user swipes up past the first job, the overlay should disappear and the seen flag should be persisted',
        (tester) async {
          when(() => prefs.getBool(any())).thenAnswer((_) async => false);

          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
            prefs: prefs,
          );

          await tester.pump();
          expect(find.text(i18n.feed.swipeUpHint.caption), findsOneWidget);

          await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
          await tester.pump();

          verify(() => prefs.setBool('seen_swipe_feed_hint', true)).called(1);
          expect(find.text(i18n.feed.swipeUpHint.caption), findsNothing);
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );
    });

    group('map gating', () {
      setUp(FeedViewTestHelpers.mockMapChannels);

      testWidgets('when the swipe-up hint appear animation is running, it should not mount the first card map', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        // Let the hint appear animation start (post frame callback)
        await tester.pump();

        // Hint appear animation is running — maps should be gated
        expect(find.byType(MapLibreMap), findsNothing);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets('when the swipe-up hint appear animation completes, it should mount the first card map', (
        tester,
      ) async {
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getBool(any())).thenAnswer((_) async => false);

        await FeedViewTestHelpers.pumpFeedView(
          tester: tester,
          feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
          prefs: prefs,
        );

        // Let the hint appear animation start
        await tester.pump();

        // Wait for the appear animation to finish and gate to release
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 900));

        // Maps should now mount
        expect(find.byType(MapLibreMap), findsOneWidget);
        await FeedViewTestHelpers.pumpAndCleanUp(tester);
      });

      testWidgets(
        'when the user swipes before the hint appear animation completes, it should mount the next card map immediately',
        (tester) async {
          final prefs = MockSharedPreferencesAsync();
          when(() => prefs.getBool(any())).thenAnswer((_) async => false);

          await FeedViewTestHelpers.pumpFeedView(
            tester: tester,
            feedState: FakeFeedState(buildResult: () => FeedViewTestHelpers.feedDataWithJobs(count: 3)),
            prefs: prefs,
          );

          // Let the hint appear animation start
          await tester.pump();

          // Swipe before appear animation completes
          await FeedViewTestHelpers.swipeAwayCurrentJob(tester);
          await tester.pump();

          // Map should mount immediately (gate released by notification)
          expect(find.byType(MapLibreMap), findsAtLeastNWidgets(1));
          await FeedViewTestHelpers.pumpAndCleanUp(tester);
        },
      );
    });
  });
}
