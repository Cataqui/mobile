import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/welcome/welcome_route.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';

abstract final class WelcomeRouteTestHelpers {
  static Future<({ProviderContainer container, GoRouter router})> pumpRoute({
    required WidgetTester tester,
    MockSharedPreferencesAsync? sharedPreferences,
  }) async {
    final resolvedSharedPreferences = sharedPreferences ?? MockSharedPreferencesAsync();
    when(() => resolvedSharedPreferences.getBool(any())).thenAnswer((_) async => null);
    when(() => resolvedSharedPreferences.setBool(any(), any())).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: const WelcomeRoute().location,
      routes: [
        $welcomeRoute,
        GoRoute(path: '/feed', builder: (context, state) => const SizedBox.shrink()),
        GoRoute(path: '/post', builder: (context, state) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: router,
        mediaQueryData: const MediaQueryData(disableAnimations: true),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          sharedPreferencesAsyncProvider.overrideWithValue(resolvedSharedPreferences),
        ],
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(WelcomeView)), listen: false);
    await container.read(appStorageStateProvider.future);
    return (container: container, router: router);
  }
}

void main() {
  testWidgets('when opening the welcome route, it should show the welcome screen', (tester) async {
    await WelcomeRouteTestHelpers.pumpRoute(tester: tester);

    expect(find.byType(WelcomeView), findsOneWidget);
  });

  testWidgets('when tapping start, it should show every localized welcome action without navigating', (tester) async {
    final routeState = await WelcomeRouteTestHelpers.pumpRoute(tester: tester);
    final i18n = AppLocale.ptBr.buildSync();
    await tester.tap(find.byKey(const ValueKey('welcome_start_button')));
    await tester.pumpAndSettle();

    expect(
      (
        route: routeState.router.routeInformationProvider.value.uri.path,
        postTitle: find.text(i18n.welcome.actions.post.title).evaluate().length,
        postDescription: find.text(i18n.welcome.actions.post.description).evaluate().length,
        browseTitle: find.text(i18n.welcome.actions.browse.title).evaluate().length,
        browseDescription: find.text(i18n.welcome.actions.browse.description).evaluate().length,
      ),
      (route: const WelcomeRoute().location, postTitle: 1, postDescription: 1, browseTitle: 1, browseDescription: 1),
    );
  });

  testWidgets('when choosing post with a valid session, it should open the protected post route', (tester) async {
    final (:container, :router) = await WelcomeRouteTestHelpers.pumpRoute(tester: tester);
    await container
        .read(appAuthStateProvider.notifier)
        .setSession(
          AuthSessionDto.fixture().copyWith(
            accessTokenExpiresAt: DateTime.utc(2100),
            refreshTokenExpiresAt: DateTime.utc(2100),
          ),
        );

    await tester.widget<MateoMenuButton>(find.byKey(const ValueKey('welcome_start_button'))).actions.first.onPressed!(
      Future<void>.value(),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/post');
  });

  testWidgets('when choosing browse, it should complete onboarding and open the feed', (tester) async {
    final (:container, :router) = await WelcomeRouteTestHelpers.pumpRoute(tester: tester);

    await tester.widget<MateoMenuButton>(find.byKey(const ValueKey('welcome_start_button'))).actions.last.onPressed!(
      Future<void>.value(),
    );
    await tester.pumpAndSettle();

    expect(
      (
        route: router.routeInformationProvider.value.uri.path,
        completedOnboarding: container.read(appStorageStateProvider).requireValue.hasCompletedOnboarding,
      ),
      (route: '/feed', completedOnboarding: true),
    );
  });

  testWidgets('when tapping terms, it should launch the terms URL without navigating', (tester) async {
    const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
    MethodCall? launchCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(urlLauncherChannel, (
      call,
    ) async {
      launchCall = call;
      return true;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        urlLauncherChannel,
        null,
      ),
    );
    final routeState = await WelcomeRouteTestHelpers.pumpRoute(tester: tester);
    await tester.tap(find.byKey(const ValueKey('welcome_terms_button')));
    await tester.pump();

    expect(
      (
        route: routeState.router.routeInformationProvider.value.uri.path,
        method: launchCall?.method,
        url: (launchCall?.arguments as Map<Object?, Object?>?)?['url'],
      ),
      (route: const WelcomeRoute().location, method: 'launch', url: 'https://cataqui.com/terms'),
    );
  });
}
