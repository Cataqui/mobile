import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';

void main() {
  testWidgets('when navigating to a public route, it should navigate immediately', (tester) async {
    final goRouter = GoRouter(initialLocation: '/post', routes: [$feedRoute, $postRoute]);
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(TestApp.router(routerConfig: goRouter));
    await tester.pumpAndSettle();
    final providerContainer = ProviderScope.containerOf(tester.element(find.byType(PostView)), listen: false);

    await providerContainer
        .read(appRouterProvider.notifier)
        .go(tester.element(find.byType(PostView)), const FeedRoute());
    await tester.pumpAndSettle();

    expect(goRouter.routerDelegate.currentConfiguration.uri.path, const FeedRoute().location);
  });

  testWidgets('when the source context unmounts during authentication, it should not navigate', (tester) async {
    final loginCompleter = Completer<bool>();
    final loginSheetController = MockLoginSheetController();
    late ProviderContainer providerContainer;
    when(loginSheetController.show).thenAnswer((_) async {
      final didLogin = await loginCompleter.future;
      if (!didLogin) return false;

      await providerContainer
          .read(appAuthStateProvider.notifier)
          .setSession(
            AuthSessionDto.fixture().copyWith(
              accessTokenExpiresAt: DateTime.utc(2100),
              refreshTokenExpiresAt: DateTime.utc(2100),
            ),
          );
      return true;
    });
    final goRouter = GoRouter(
      initialLocation: const FeedRoute().location,
      routes: [
        $feedRoute,
        $postRoute,
        GoRoute(path: '/other', builder: (context, state) => const SizedBox.shrink()),
      ],
    );
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: goRouter,
        providerOverrides: [loginSheetControllerProvider.overrideWithValue(loginSheetController)],
      ),
    );
    await tester.pumpAndSettle();
    providerContainer = ProviderScope.containerOf(tester.element(find.byType(FeedView)), listen: false);
    final navigation = providerContainer
        .read(appRouterProvider.notifier)
        .push(tester.element(find.byType(FeedView)), const PostRoute());
    await tester.pump();

    goRouter.go('/other');
    await tester.pumpAndSettle();
    loginCompleter.complete(true);
    await navigation;

    expect(goRouter.routerDelegate.currentConfiguration.uri.path, '/other');
  });
}
