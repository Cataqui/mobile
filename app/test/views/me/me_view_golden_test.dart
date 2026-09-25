import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/me/me_route.dart';
import 'package:cataqui_app/views/me/me_state.dart';
import 'package:cataqui_app/views/me/me_view.dart';
import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';
import '../../widgets/job_location_map/google_maps_test_renderer.dart';
import '../feed/feed_view_test_helpers.dart';
import 'fake_me_state.dart';
import 'fake_my_posts_state.dart';

void main() {
  setUp(() {
    final mapRenderer = GoogleMapsTestRenderer()..install();
    addTearDown(mapRenderer.restore);
  });

  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when the Me page loads, it should show the display identifier and posted jobs',
        fileName: 'me_view',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MeGoldenTestHelpers.pumpGolden,
        pumpBeforeTest: MeGoldenTestHelpers.settleGolden,
        builder: () => TestApp.screen(
          mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(
                  MyPostsData(
                    userId: 'test-user',
                    jobs: [
                      MeGoldenTestHelpers.job(),
                      MeGoldenTestHelpers.job(status: .archived),
                    ],
                    hasMore: false,
                  ),
                ),
              ),
            ),
          ],
          child: const MeView(),
        ),
      );

      goldenTest(
        'when the Me page and posts are loading, it should show identifier and card skeletons',
        fileName: 'me_loading',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MeGoldenTestHelpers.pumpGolden,
        pumpBeforeTest: MeGoldenTestHelpers.settleGolden,
        builder: () => TestApp.screen(
          mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(const AsyncLoading<UserProfileDto?>())),
            myPostsStateProvider.overrideWith(() => FakeMyPostsState(const AsyncLoading<MyPostsData?>())),
          ],
          child: const MeView(),
        ),
      );

      goldenTest(
        'when there are no posts, it should show the post prompt',
        fileName: 'me_empty',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MeGoldenTestHelpers.pumpGolden,
        pumpBeforeTest: MeGoldenTestHelpers.settleGolden,
        builder: () => TestApp.screen(
          mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(const AsyncData(MyPostsData(userId: 'test-user', jobs: [], hasMore: false))),
            ),
          ],
          child: const MeView(),
        ),
      );

      goldenTest(
        'when posts fail to load, it should show the initial error panel',
        fileName: 'me_initial_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MeGoldenTestHelpers.pumpGolden,
        pumpBeforeTest: MeGoldenTestHelpers.settleGolden,
        builder: () => TestApp.screen(
          mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(AsyncError<MyPostsData?>(StateError('offline'), StackTrace.empty)),
            ),
          ],
          child: const MeView(),
        ),
        whilePerforming: MeGoldenTestHelpers.showInitialError,
      );

      goldenTest(
        'when more posts fail to load, it should show the pagination retry panel',
        fileName: 'me_pagination_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MeGoldenTestHelpers.pumpGolden,
        pumpBeforeTest: MeGoldenTestHelpers.settleGolden,
        builder: () => TestApp.screen(
          mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(
                  MyPostsData(
                    userId: 'test-user',
                    jobs: [MeGoldenTestHelpers.job()],
                    hasMore: true,
                    paginationError: StateError('offline'),
                  ),
                ),
              ),
            ),
          ],
          child: const MeView(),
        ),
        whilePerforming: MeGoldenTestHelpers.showPaginationError,
      );

      goldenTest(
        'when the Me page opens, it should slide and fade the posts list into place',
        fileName: 'me_posts_entrance_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MeGoldenTestHelpers.pumpGolden,
        pumpBeforeTest: (tester) =>
            withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () => tester.pump(const Duration(milliseconds: 80))),
        builder: () => TestApp.screen(
          mediaQueryData: const MediaQueryData(size: Size(390, 844)),
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(MyPostsData(userId: 'test-user', jobs: [MeGoldenTestHelpers.job()], hasMore: false)),
              ),
            ),
          ],
          child: const MeView(),
        ),
      );

      goldenTest(
        'when the Me page opens from the feed, it should slide up as the avatar moves into place',
        fileName: 'me_morph_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        builder: MeGoldenTestHelpers.feedRoute,
        whilePerforming: MeGoldenTestHelpers.openToMidpoint,
      );
    },
  );
}

abstract final class MeGoldenTestHelpers {
  static UserJobSummaryDto job({JobStatus status = .active}) => UserJobSummaryDto.fixture().copyWith(
    jobId: status == .active ? 'active-job' : 'archived-job',
    title: 'Garçom',
    payment: r'R$100/dia',
    descriptionSummary:
        'Preciso de um garçom para 3 dias em um evento. Precisa ter experiência e já ter participado de eventos...',
    status: status,
    createdAt: DateTime.utc(2026, 9, 23, 12),
  );

  static Future<void> pumpGolden(WidgetTester tester, Widget widget) =>
      withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () => tester.pumpWidget(widget));

  static Future<void> settleGolden(WidgetTester tester) =>
      withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), tester.pumpAndSettle);

  static Future<Future<void> Function()> scrollToTrailingItem(WidgetTester tester) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      final list = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list')));
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
    });
    return () async {};
  }

  static Future<Future<void> Function()> showPaginationError(WidgetTester tester) async {
    final cleanup = await scrollToTrailingItem(tester);
    await precacheErrorIllustration(tester, const ValueKey('my_posts_pagination_error_illustration'));
    return cleanup;
  }

  static Future<Future<void> Function()> showInitialError(WidgetTester tester) async {
    await precacheErrorIllustration(tester, const ValueKey('my_posts_initial_error_illustration'));
    return () async {};
  }

  static Future<void> precacheErrorIllustration(WidgetTester tester, Key key) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      final imageFinder = find.byKey(key).last;
      final image = tester.widget<Image>(imageFinder);
      await tester.runAsync(() => precacheImage(image.image, tester.element(imageFinder)));
      await tester.pump();
    });
  }

  static Widget feedRoute() {
    final goRouter = GoRouter(
      observers: [MateoNavigatorObserver()],
      initialLocation: const FeedRoute().location,
      routes: [$feedRoute, $meRoute],
    );
    addTearDown(goRouter.dispose);

    return TestApp.router(
      routerConfig: goRouter,
      mediaQueryData: const MediaQueryData(size: Size(390, 844)),
      providerOverrides: [
        goRouterProvider.overrideWithValue(goRouter),
        feedStateProvider.overrideWith(() => FakeFeedState(buildResult: FeedViewTestHelpers.feedDataEmpty)),
        appStorageStateProvider.overrideWith(() => FixedAppStorageState(hasSeenSwipeFeedHint: true)),
        meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
        myPostsStateProvider.overrideWith(
          () => FakeMyPostsState(AsyncData(MyPostsData(userId: 'test-user', jobs: [job()], hasMore: false))),
        ),
      ],
    );
  }

  static Future<Future<void> Function()> openToMidpoint(WidgetTester tester) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      FeedViewTestHelpers.mockHapticFeedback(tester);
      FeedViewTestHelpers.mockPlatformViews(tester);
      FeedViewTestHelpers.mockGoogleMapsPlatform();
      await tester.pumpAndSettle();
      await FeedViewTestHelpers.prepareGoldenCapture(tester: tester, contextFinder: find.byType(FeedView));

      final container = ProviderScope.containerOf(tester.element(find.byType(FeedView)), listen: false);
      await container
          .read(appAuthStateProvider.notifier)
          .setSession(
            AuthSessionDto.fixture().copyWith(
              accessTokenExpiresAt: DateTime.utc(2100),
              refreshTokenExpiresAt: DateTime.utc(2100),
            ),
          );

      await tester.tap(find.byKey(const ValueKey('feed_me_button')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byType(MeView), findsOneWidget);
    });

    return () =>
        withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () => tester.pumpWidget(const SizedBox.shrink()));
  }
}
