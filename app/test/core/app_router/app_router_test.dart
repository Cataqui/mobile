import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/notp_intent_exchange_result_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/post/contact/post_contact_view.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';

void main() {
  testWidgets('when navigating to a public route, it should navigate immediately', (tester) async {
    final goRouter = GoRouter(
      observers: [MateoNavigatorObserver()],
      initialLocation: '/post',
      routes: [$feedRoute, $postRoute],
    );
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
      observers: [MateoNavigatorObserver()],
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

  testWidgets('when saved credentials exist, post opens before refresh completes', (tester) async {
    final refreshResponse = Completer<ApiEnvelopeDto<IssuedAuthSessionDto>>();
    final authRepository = MockAuthRepository();
    final sharedPreferences = MockSharedPreferencesAsync();
    when(() => sharedPreferences.getBool(any())).thenAnswer((_) async => false);
    when(
      () => authRepository.refreshSession(refreshToken: 'saved-refresh-token'),
    ).thenAnswer((_) => refreshResponse.future);
    final goRouter = GoRouter(
      observers: [MateoNavigatorObserver()],
      initialLocation: const FeedRoute().location,
      routes: [$feedRoute, $postRoute],
    );
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: goRouter,
        providerOverrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          cataquiApiCookieJarProvider.overrideWith((ref) async => CookieJar()),
          sharedPreferencesAsyncProvider.overrideWithValue(sharedPreferences),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(FeedView)), listen: false);
    await container.read(appStorageStateProvider.future);
    await container.read(cataquiApiCookieJarProvider.future);
    await container
        .read(appStorageStateProvider.notifier)
        .setAuthCredentials(
          credentials: AuthCredentialsDto.fixture().copyWith(
            refreshToken: 'saved-refresh-token',
            refreshTokenExpiresAt: DateTime.utc(2100),
          ),
        );

    await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PostView), findsOneWidget);
    expect(find.byType(LoginSheet), findsNothing);
    verify(() => authRepository.refreshSession(refreshToken: 'saved-refresh-token')).called(1);

    final issuedSession = (NotpIntentExchangeResultDto.issuedSessionFixture() as IssuedAuthSessionDto).copyWith(
      expiresAt: DateTime.utc(2100),
      refreshExpiresAt: DateTime.utc(2100),
    );
    refreshResponse.complete(ApiEnvelopeDto.fixture(data: issuedSession));
    await tester.pumpAndSettle();
    expect(container.read(appAuthStateProvider), AuthSessionDto.fromIssuedAuthSession(issuedSession));
  });

  testWidgets('when Post goes to Feed, the footer can open a fresh Post page', (tester) async {
    final goRouter = GoRouter(
      observers: [MateoNavigatorObserver()],
      initialLocation: const FeedRoute().location,
      routes: [$feedRoute, $postRoute],
    );
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(TestApp.router(routerConfig: goRouter));
    await tester.pumpAndSettle();
    final providerContainer = ProviderScope.containerOf(tester.element(find.byType(FeedView)), listen: false);
    await providerContainer
        .read(appAuthStateProvider.notifier)
        .setSession(
          AuthSessionDto.fixture().copyWith(
            accessTokenExpiresAt: DateTime.utc(2100),
            refreshTokenExpiresAt: DateTime.utc(2100),
          ),
        );

    await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
    await tester.pumpAndSettle();
    expect(find.byType(PostView), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('post_description_input')), 'Draft from first visit');

    const FeedRoute().go(tester.element(find.byType(PostView)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feed_job_creation_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PostView), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('post_description_input'))).controller!.text, isEmpty);
  });

  testWidgets('when saved credentials are revoked, post draft remains and contact requests login', (tester) async {
    final authRepository = MockAuthRepository();
    final loginSheetController = MockLoginSheetController();
    final loginResult = Completer<bool>();
    when(loginSheetController.show).thenAnswer((_) => loginResult.future);
    addTearDown(() {
      if (!loginResult.isCompleted) loginResult.complete(false);
    });
    final sharedPreferences = MockSharedPreferencesAsync();
    when(() => sharedPreferences.getBool(any())).thenAnswer((_) async => false);
    when(() => authRepository.refreshSession(refreshToken: 'revoked-refresh-token')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/sessions/refresh'),
        response: Response<void>(requestOptions: RequestOptions(path: '/auth/sessions/refresh'), statusCode: 401),
      ),
    );
    final goRouter = GoRouter(
      observers: [MateoNavigatorObserver()],
      initialLocation: const FeedRoute().location,
      routes: [$feedRoute, $postRoute],
    );
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: goRouter,
        providerOverrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          cataquiApiCookieJarProvider.overrideWith((ref) async => CookieJar()),
          loginSheetControllerProvider.overrideWithValue(loginSheetController),
          sharedPreferencesAsyncProvider.overrideWithValue(sharedPreferences),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(FeedView)), listen: false);
    await container.read(appStorageStateProvider.future);
    await container.read(cataquiApiCookieJarProvider.future);
    await container
        .read(appStorageStateProvider.notifier)
        .setAuthCredentials(
          credentials: AuthCredentialsDto.fixture().copyWith(
            refreshToken: 'revoked-refresh-token',
            refreshTokenExpiresAt: DateTime.utc(2100),
          ),
        );

    unawaited(
      container.read(appRouterProvider.notifier).push(tester.element(find.byType(FeedView)), const PostRoute()),
    );
    await tester.pumpAndSettle();
    expect(container.read(appStorageStateProvider).requireValue.authCredentials, isNull);
    verifyNever(loginSheetController.show);
    await tester.enterText(find.byKey(const ValueKey('post_description_input')), 'Draft remains here');
    await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PostView), findsOneWidget);
    expect(find.byType(PostContactView), findsOneWidget);
    expect(find.text('Draft remains here'), findsOneWidget);
    verify(loginSheetController.show).called(1);
    expect(container.read(appStorageStateProvider).requireValue.authCredentials, isNull);
  });
}
