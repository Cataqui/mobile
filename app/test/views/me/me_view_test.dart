import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/user_job.dart';
import 'package:cataqui_app/core/dtos/user_profile_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/me/me_route.dart';
import 'package:cataqui_app/views/me/me_state.dart';
import 'package:cataqui_app/views/me/me_view.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:cataqui_app/views/me/my_posts_carousel.dart';
import 'package:cataqui_app/views/me/my_posts_data.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:cataqui_app/views/me/user_avatar_morph_target.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../utils/test_app.dart';
import '../../widgets/job_location_map/google_maps_test_renderer.dart';
import '../feed/feed_view_test_helpers.dart';
import 'fake_app_auth_state.dart';
import 'fake_me_state.dart';
import 'fake_my_posts_state.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  test('when opening the Me route, it should require authentication', () {
    expect(const MeRoute().requiresAuthentication, isTrue);
    expect(const MeRoute().location, '/me');
  });

  testWidgets('when the Me page loads with a post, it should show the identifier and a job card', (tester) async {
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            meStateProvider.overrideWith(
              () => FakeMeState(AsyncData(UserProfileDto.fixture().copyWith(displayIdentifier: 'Ana Teste'))),
            ),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(
                  MyPostsData(
                    userId: 'test-user',
                    jobs: [UserJob.fixture().copyWith(createdAt: DateTime.utc(2026, 9, 23, 12))],
                    hasMore: false,
                  ),
                ),
              ),
            ),
          ],
          child: const MeView(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('me_avatar')), findsOneWidget);
    expect(find.text('Ana Teste'), findsOneWidget);
    expect(find.byKey(const ValueKey('me_identifier_skeleton')), findsNothing);
    expect(find.text(i18n.me.myPosts.title), findsOneWidget);
    expect(find.byType(MyPostCard), findsOneWidget);
    expect(find.byKey(const ValueKey('my_posts_retry_next_page')), findsNothing);
    expect(
      tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position.maxScrollExtent,
      0,
    );
    expect(find.byType(FeedJobCard), findsNothing);
  });

  testWidgets('when the Me page and posts are loading, it should show identifier and card skeletons', (tester) async {
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [meStateProvider.overrideWith(() => FakeMeState(const AsyncLoading<UserProfileDto?>()))],
          child: const MeView(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('me_identifier_skeleton')), findsOneWidget);
    expect(find.bySemanticsLabel(i18n.me.loadingSemanticLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('me_identifier')), findsNothing);
    expect(find.byType(MyPostCard), findsWidgets);
    expect(tester.widgetList<MyPostCard>(find.byType(MyPostCard)).every((card) => card.skeleton), isTrue);
  });

  testWidgets('when the Me page scrolls, its surface should contain a width-sized carousel', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final viewportWidth in [320.0, 390.0, 800.0]) {
      tester.view
        ..physicalSize = Size(viewportWidth, 900)
        ..devicePixelRatio = 1;
      await tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            myPostsStateProvider.overrideWith(() => FakeMyPostsState(const AsyncLoading<MyPostsData?>())),
          ],
          child: const MeView(),
        ),
      );

      final postsList = find.byKey(const ValueKey('me_posts_list'));
      expect(find.ancestor(of: find.byType(MyPostsCarousel), matching: find.byType(CustomScrollView)), findsOneWidget);
      expect(tester.getSize(postsList).height, closeTo((viewportWidth - 44 - 30) / 0.8, 0.01));
      if (viewportWidth == 800) {
        expect(
          tester.widget<CustomScrollView>(find.byType(CustomScrollView)).controller!.position.maxScrollExtent,
          greaterThan(0),
        );
      }
    }
  });

  testWidgets('when posts finish loading, it should replace the skeleton with the job details', (tester) async {
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    final jobsState = FakeMyPostsState(const AsyncLoading<MyPostsData?>());
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.pumpWidget(
        TestApp.screen(providerOverrides: [myPostsStateProvider.overrideWith(() => jobsState)], child: const MeView()),
      );
      final cardSkeleton = find.descendant(of: find.byType(MyPostCard), matching: find.byType(Skeleton));
      final skeletonElement = tester.element(cardSkeleton.first);
      jobsState.showData(
        MyPostsData(
          userId: 'test-user',
          jobs: [UserJob.fixture().copyWith(title: 'Loaded job', createdAt: DateTime.utc(2026, 9, 23, 12))],
          hasMore: false,
        ),
      );
      await tester.pump();
      expect(tester.element(cardSkeleton.first), same(skeletonElement));
      expect(tester.widget<Skeleton>(cardSkeleton.first).transition, isA<SkeletonTransition>());
      expect(find.text('Loaded job'), findsOneWidget);
      expect(find.bySemanticsLabel(i18n.me.myPosts.loadingPostSemanticLabel), findsNothing);
      expect(find.byWidgetPredicate((widget) => widget is MyPostCard && !widget.skeleton), findsOneWidget);
    });
  });

  testWidgets('when dragging posts horizontally, it should stop at the dragged offset without snapping', (
    tester,
  ) async {
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(
                  MyPostsData(
                    userId: 'test-user',
                    jobs: [
                      UserJob.fixture().copyWith(jobId: 'job-1', createdAt: DateTime.utc(2026, 9, 23, 12)),
                      UserJob.fixture().copyWith(jobId: 'job-2', createdAt: DateTime.utc(2026, 9, 23, 12)),
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

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
      await tester.pump();
      final postsList = find.byKey(const ValueKey('me_posts_list'));
      await tester.dragFrom(tester.getTopLeft(postsList) + const Offset(100, 70), const Offset(-73, 0));
      await tester.pump(const Duration(milliseconds: 300));

      final stoppedOffset = tester.widget<ListView>(postsList).controller!.position.pixels;
      expect(stoppedOffset, inExclusiveRange(0, 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<ListView>(postsList).controller!.position.pixels, closeTo(stoppedOffset, 0.01));
      expect(find.byType(SnapList), findsNothing);
    });
  });

  for (final viewportWidth in [390.0, 800.0]) {
    testWidgets('when three cards remain at ${viewportWidth.toInt()}px, it should load more before the end', (
      tester,
    ) async {
      FeedViewTestHelpers.mockGoogleMapsPlatform();
      tester.view
        ..physicalSize = Size(viewportWidth, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final jobsState = FakeMyPostsState(
        AsyncData(
          MyPostsData(
            userId: 'test-user',
            jobs: [
              for (var index = 0; index < 5; index++)
                UserJob.fixture().copyWith(jobId: 'job-$index', createdAt: DateTime.utc(2026, 9, 23, 12)),
            ],
            hasMore: true,
            nextCursor: 'next-page',
          ),
        ),
      );
      await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
        await tester.pumpWidget(
          TestApp.screen(
            providerOverrides: [
              meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
              myPostsStateProvider.overrideWith(() => jobsState),
            ],
            child: const MeView(),
          ),
        );

        final position = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position;
        final cardWidth = tester.getSize(find.byType(MyPostCard).first).width;
        final prefetchStart = 2 * (cardWidth + 12) - position.viewportDimension;
        position.jumpTo(prefetchStart - 1);
        await tester.pump();
        expect(jobsState.loadNextPageCalls, 0);

        position.jumpTo(prefetchStart + 1);
        await tester.pump();
        expect(jobsState.loadNextPageCalls, 1);
        await tester.pump(const Duration(milliseconds: 500));
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
        expect(jobsState.loadNextPageCalls, 1);
      });
    });
  }

  testWidgets('when the user has no posts, it should show the prompt over faded skeletons', (tester) async {
    final postsState = FakeMyPostsState(const AsyncLoading<MyPostsData?>());
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
          myPostsStateProvider.overrideWith(() => postsState),
        ],
        child: const MeView(),
      ),
    );

    expect(find.byType(MyPostCard), findsWidgets);
    expect(find.text(i18n.me.myPosts.empty), findsNothing);
    await tester.pump(const Duration(milliseconds: 650));
    final postsList = find.byKey(const ValueKey('me_posts_list'));
    final scrollController = tester.widget<ListView>(postsList).controller!;
    await tester.dragFrom(tester.getTopLeft(postsList) + const Offset(100, 70), const Offset(-73, 0));
    await tester.pump();
    final loadingOffset = scrollController.position.pixels;
    expect(loadingOffset, greaterThan(0));

    postsState.showData(const MyPostsData(userId: 'test-user', jobs: [], hasMore: false));
    await tester.pump();
    expect(find.byKey(const ValueKey('my_posts_empty_fade')), findsOneWidget);
    expect(scrollController.position.pixels, loadingOffset);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MyPostCard), findsWidgets);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text(i18n.me.myPosts.empty), findsOneWidget);
    expect(find.byKey(const ValueKey('my_posts_empty_text_motion')), findsOneWidget);
    expect(find.byKey(const ValueKey('my_posts_empty_button_motion')), findsOneWidget);
    expect(find.byKey(const ValueKey('my_posts_create_button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my_posts_create_button')),
        matching: find.byWidgetPredicate((widget) => widget is MateoIcon && widget.icon == .plusSignal),
      ),
      findsOneWidget,
    );
    expect(find.byType(MyPostCard), findsWidgets);

    await tester.dragFrom(tester.getTopLeft(postsList) + const Offset(100, 70), const Offset(-73, 0));
    await tester.pump();
    expect(scrollController.position.pixels, loadingOffset);
  });

  testWidgets('when the empty-state button is tapped, it should open Post', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      observers: [MateoNavigatorObserver()],
      initialLocation: const MeRoute().location,
      routes: [$meRoute, $postRoute],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: router,
        providerOverrides: [
          goRouterProvider.overrideWithValue(router),
          appAuthStateProvider.overrideWith(
            () => FakeAppAuthState(
              AuthSessionDto.fixture().copyWith(
                accessTokenExpiresAt: DateTime.utc(2100),
                refreshTokenExpiresAt: DateTime.utc(2100),
              ),
            ),
          ),
          meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
          myPostsStateProvider.overrideWith(
            () => FakeMyPostsState(const AsyncData(MyPostsData(userId: 'test-user', jobs: [], hasMore: false))),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('my_posts_create_button')));
    await tester.pump();

    expect(router.state.matchedLocation, const PostRoute().location);
  });

  testWidgets('when posts fail to load, it should show the illustrated error and retry', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final postsState = FakeMyPostsState(AsyncError<MyPostsData?>(StateError('offline'), StackTrace.empty));
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
          myPostsStateProvider.overrideWith(() => postsState),
        ],
        child: const MeView(),
      ),
    );

    expect(find.byKey(const ValueKey('my_posts_initial_error_illustration')), findsWidgets);
    expect(find.text(i18n.me.myPosts.error.title), findsOneWidget);
    expect(find.text(i18n.me.myPosts.error.description), findsOneWidget);
    expect(find.byKey(const ValueKey('my_posts_retry')), findsOneWidget);
    expect(postsState.buildCalls, 1);
    await tester.tap(find.byKey(const ValueKey('my_posts_retry')));
    await tester.pump();
    await tester.pump();
    expect(postsState.buildCalls, 2);
  });

  testWidgets('when the first load fails, it should switch directly to the error panel', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final postsState = FakeMyPostsState(const AsyncLoading<MyPostsData?>());
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
          myPostsStateProvider.overrideWith(() => postsState),
        ],
        child: const MeView(),
      ),
    );

    expect(find.byType(MyPostCard), findsNWidgets(2));

    postsState.showError(StateError('offline'));
    await tester.pump();
    expect(find.byType(MyPostCard), findsNothing);
    expect(find.byKey(const ValueKey('my_posts_retry')), findsOneWidget);
  });

  testWidgets('when many posts are loaded, it should build maps only for nearby cards', (tester) async {
    final mapRenderer = GoogleMapsTestRenderer()..install();
    addTearDown(mapRenderer.restore);
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(
                  MyPostsData(
                    userId: 'test-user',
                    jobs: [
                      for (var index = 0; index < 20; index++)
                        UserJob.fixture().copyWith(jobId: 'job-$index', createdAt: DateTime.utc(2026, 9, 23, 12)),
                    ],
                    hasMore: false,
                  ),
                ),
              ),
            ),
          ],
          child: const MeView(),
        ),
      ),
    );

    expect(mapRenderer.createdIds.length, lessThan(20));
  });

  testWidgets('when posts fling quickly, it should defer new maps until scrolling settles', (tester) async {
    final mapRenderer = GoogleMapsTestRenderer()..install();
    addTearDown(mapRenderer.restore);
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(
                AsyncData(
                  MyPostsData(
                    userId: 'test-user',
                    jobs: [
                      for (var index = 0; index < 24; index++)
                        UserJob.fixture().copyWith(jobId: 'job-$index', createdAt: DateTime.utc(2026, 9, 23, 12)),
                    ],
                    hasMore: false,
                  ),
                ),
              ),
            ),
          ],
          child: const MeView(),
        ),
      ),
    );

    final postsList = find.byKey(const ValueKey('me_posts_list'));
    expect(find.byKey(const ValueKey('me_post_deferred_map')), findsNothing);
    expect(mapRenderer.createdIds, isNotEmpty);
    final initialMapCount = mapRenderer.createdIds.length;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pump();
    await tester.flingFrom(tester.getTopLeft(postsList) + const Offset(100, 70), const Offset(-520, 0), 12000);
    await tester.pump();
    final scrollPosition = tester.widget<ListView>(postsList).controller!.position;
    expect(scrollPosition.isScrollingNotifier.value, isTrue);
    expect(find.byKey(const ValueKey('me_post_deferred_map'), skipOffstage: false), findsWidgets);

    for (var frame = 0; frame < 80 && scrollPosition.isScrollingNotifier.value; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
    expect(scrollPosition.isScrollingNotifier.value, isFalse);
    expect(find.byKey(const ValueKey('me_post_deferred_map')), findsNothing);
    expect(find.byType(JobLocationMap), findsWidgets);
    expect(mapRenderer.createdIds.length, greaterThan(initialMapCount));
  });

  testWidgets('when many posts load, the horizontal scroll extent should be exact before scrolling', (tester) async {
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final jobs = [
      for (var index = 0; index < 24; index++)
        UserJob.fixture().copyWith(jobId: 'job-$index', createdAt: DateTime.utc(2026, 9, 23, 12)),
    ];
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            myPostsStateProvider.overrideWith(
              () => FakeMyPostsState(AsyncData(MyPostsData(userId: 'test-user', jobs: jobs, hasMore: false))),
            ),
          ],
          child: const MeView(),
        ),
      ),
    );

    final position = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position;
    final cardWidth = tester.getSize(find.byType(MyPostCard).first).width;
    expect(position.maxScrollExtent, closeTo(jobs.length * (cardWidth + 12) - position.viewportDimension, 0.01));
  });

  testWidgets('when a later page fails, it should keep the posts and offer a retry', (tester) async {
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final jobsState = FakeMyPostsState(
      AsyncData(
        MyPostsData(
          userId: 'test-user',
          jobs: [UserJob.fixture().copyWith(jobId: 'posted-job', createdAt: DateTime.utc(2026, 9, 23, 12))],
          hasMore: true,
          nextCursor: 'next-page',
          paginationError: StateError('offline'),
        ),
      ),
    );
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(() => jobsState),
          ],
          child: const MeView(),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
      await tester.pump();
      final postsPosition = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list'))).controller!.position;
      postsPosition.jumpTo(postsPosition.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
      await tester.pump();
    });

    expect(find.byType(MyPostCard), findsOneWidget);
    expect(find.text(i18n.me.myPosts.paginationError.title), findsOneWidget);
    expect(find.text(i18n.me.myPosts.paginationError.description), findsOneWidget);
    expect(find.byKey(const ValueKey('my_posts_retry_next_page')), findsOneWidget);
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.tap(find.byKey(const ValueKey('my_posts_retry_next_page')));
      await tester.pump();
    });
    expect(jobsState.loadNextPageCalls, 1);
  });

  testWidgets('when loading more fails, it should switch directly to retry', (tester) async {
    FeedViewTestHelpers.mockGoogleMapsPlatform();
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final postsState = FakeMyPostsState(
      AsyncData(
        MyPostsData(
          userId: 'test-user',
          jobs: [UserJob.fixture().copyWith(createdAt: DateTime.utc(2026, 9, 23, 12))],
          hasMore: true,
          isLoadingMore: true,
        ),
      ),
    );
    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
            myPostsStateProvider.overrideWith(() => postsState),
          ],
          child: const MeView(),
        ),
      );
      final postsList = tester.widget<ListView>(find.byKey(const ValueKey('me_posts_list')));
      postsList.controller!.jumpTo(postsList.controller!.position.maxScrollExtent);
      await tester.pump();

      expect(find.byType(MyPostCard), findsNWidgets(2));
      postsState.showPaginationError(StateError('offline'));
      await tester.pump();
      expect(find.byType(MyPostCard), findsOneWidget);
      expect(find.byKey(const ValueKey('my_posts_retry_next_page')), findsOneWidget);
    });
  });

  testWidgets('when signed out, it should leave the identifier empty without a skeleton', (tester) async {
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [meStateProvider.overrideWith(() => FakeMeState(const AsyncData<UserProfileDto?>(null)))],
        child: const MeView(),
      ),
    );

    expect(find.byKey(const ValueKey('me_identifier')), findsNothing);
    expect(find.byKey(const ValueKey('me_identifier_skeleton')), findsNothing);
  });

  testWidgets('when logout is tapped, it should remain on the Me view', (tester) async {
    await tester.pumpWidget(const TestApp.screen(child: MeView()));

    await tester.tap(find.byKey(const ValueKey('me_logout_button')));
    await tester.pump();

    expect(find.byType(MeView), findsOneWidget);
    expect(find.bySemanticsLabel(i18n.me.logoutButtonSemanticLabel), findsOneWidget);
  });

  testWidgets('when opening the Me page from the feed then closing it, it should slide up and return to the feed', (
    tester,
  ) async {
    final container = await FeedViewTestHelpers.pumpFeedRoute(
      tester: tester,
      providerOverrides: [
        meStateProvider.overrideWith(() => FakeMeState(AsyncData(UserProfileDto.fixture()))),
        myPostsStateProvider.overrideWith(
          () => FakeMyPostsState(const AsyncData(MyPostsData(userId: 'test-user', jobs: [], hasMore: false))),
        ),
      ],
    );
    final target = container.read(userAvatarMorphTargetProvider);

    await tester.tap(find.byKey(const ValueKey('feed_me_button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    final route = ModalRoute.of(tester.element(find.byType(MeView)));
    final page = route?.settings;
    final transition = page is MateoPage<void> ? page.transition : null;
    expect(transition, isA<MateoPageTransitionSlide>());
    expect(transition?.direction, MateoPageTransitionDirection.up);
    expect(target.status.value, MorphTagStatus.flying);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(target.status.value, MorphTagStatus.completed);

    await tester.tap(find.byKey(const ValueKey('me_close_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    expect(target.status.value, MorphTagStatus.flying);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byType(FeedView), findsOneWidget);
    expect(find.byType(MeView), findsNothing);
    expect(target.status.value, MorphTagStatus.completed);
  });
}
