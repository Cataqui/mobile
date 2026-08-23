import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/network/auth_interceptor/auth_interceptor.dart';
import 'package:cataqui_app/core/network/geosearch/geosearch_access_token_interceptor.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limit_interceptor.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/onboarding/onboarding_route.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../mocks.dart';
import '../utils/test_app.dart';

void main() {
  group('secureStorageProvider', () {
    test('when read, it should isolate and migrate the Cataquí authentication storage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final androidOptions = container.read(secureStorageProvider).aOptions.toMap();

      expect(
        (namespace: androidOptions['storageNamespace'], migrateWithBackup: androidOptions['migrateWithBackup']),
        (namespace: 'cataqui_auth', migrateWithBackup: 'true'),
      );
    });
  });

  group('unauthenticatedCataquiApiV1DioProvider', () {
    test('when read, it should prefix the configured Cataquí API root URL with v1', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );

      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.options.baseUrl, 'https://staging.api.cataqui.com/v1');
    });

    test('when resolving an endpoint, it should keep the v1 API prefix', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );

      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(
        RequestOptions(baseUrl: dio.options.baseUrl, path: '/feed').uri.toString(),
        'https://staging.api.cataqui.com/v1/feed',
      );
    });

    test('when read, it should include the accept-language header from the current locale', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );

      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.options.headers['accept-language'], 'pt-BR');
    });

    test('when flavor is development, it should include request logging', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isTrue);
    });

    test('when flavor is production, it should skip request logging', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isFalse);
    });

    test('when flavor is production, it should register the offline error interceptor', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is OfflineErrorDioInterceptor), isTrue);
    });

    test('when read, it should not include authenticated request handling', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is AuthInterceptor), isFalse);
    });

    test('when read, it should persist Cloudflare transport cookies and convert rate-limit responses', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(dio.interceptors.whereType<CookieManager>(), hasLength(1));
      expect(dio.interceptors.whereType<RateLimitInterceptor>(), hasLength(1));
    });
  });

  group('authenticatedCataquiApiV1DioProvider', () {
    test('when read, it should include authenticated request handling', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final dio = container.read(authenticatedCataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is AuthInterceptor), isTrue);
    });

    test('when read, it should share the unauthenticated API configuration', () async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);
      await container.read(cataquiApiCookieJarProvider.future);

      final authenticatedDio = container.read(authenticatedCataquiApiV1DioProvider);
      final unauthenticatedDio = container.read(unauthenticatedCataquiApiV1DioProvider);

      expect(
        (
          baseUrl: authenticatedDio.options.baseUrl,
          accept: authenticatedDio.options.headers[Headers.acceptHeader],
          contentType: authenticatedDio.options.headers[Headers.contentTypeHeader],
          language: authenticatedDio.options.headers['accept-language'],
          connectTimeout: authenticatedDio.options.connectTimeout,
          sendTimeout: authenticatedDio.options.sendTimeout,
          receiveTimeout: authenticatedDio.options.receiveTimeout,
        ),
        (
          baseUrl: unauthenticatedDio.options.baseUrl,
          accept: unauthenticatedDio.options.headers[Headers.acceptHeader],
          contentType: unauthenticatedDio.options.headers[Headers.contentTypeHeader],
          language: unauthenticatedDio.options.headers['accept-language'],
          connectTimeout: unauthenticatedDio.options.connectTimeout,
          sendTimeout: unauthenticatedDio.options.sendTimeout,
          receiveTimeout: unauthenticatedDio.options.receiveTimeout,
        ),
      );
    });
  });

  group('geosearchDioProvider', () {
    late MockAuthRepository authRepository;

    setUp(() {
      authRepository = MockAuthRepository();
    });

    ProviderContainer buildContainer({String? flavor}) {
      return ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          if (flavor != null) appConfigProvider.overrideWithValue(AppConfig(flavor: flavor)),
        ],
      );
    }

    test('when the flavor is development, it should target the staging geosearch worker', () {
      final container = buildContainer(flavor: 'development');
      addTearDown(container.dispose);

      final dio = container.read(geosearchDioProvider);

      expect(dio.options.baseUrl, 'https://staging.geosearch.cataqui.com');
    });

    test('when the flavor is production, it should target the production geosearch worker', () {
      final container = buildContainer(flavor: 'production');
      addTearDown(container.dispose);

      final dio = container.read(geosearchDioProvider);

      expect(dio.options.baseUrl, 'https://geosearch.cataqui.com');
    });

    test('when read, it should use the active locale and network timeouts', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      final dio = container.read(geosearchDioProvider);

      expect(
        (
          language: dio.options.headers['accept-language'],
          connectTimeout: dio.options.connectTimeout,
          sendTimeout: dio.options.sendTimeout,
          receiveTimeout: dio.options.receiveTimeout,
        ),
        (
          language: 'pt-BR',
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    });

    test('when read, it should authenticate and convert network failures without leaking sensitive traffic', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      final dio = container.read(geosearchDioProvider);
      final accessTokenInterceptor = dio.interceptors.whereType<GeosearchAccessTokenInterceptor>().single;

      expect(
        (
          hasAccessToken: dio.interceptors.any((interceptor) => interceptor is GeosearchAccessTokenInterceptor),
          usesAuthRepository: accessTokenInterceptor.authRepository,
          hasRateLimit: dio.interceptors.any((interceptor) => interceptor is RateLimitInterceptor),
          hasOffline: dio.interceptors.any((interceptor) => interceptor is OfflineErrorDioInterceptor),
          hasCookies: dio.interceptors.any((interceptor) => interceptor is CookieManager),
          hasLogging: dio.interceptors.any((interceptor) => interceptor is LogInterceptor),
        ),
        (
          hasAccessToken: true,
          usesAuthRepository: authRepository,
          hasRateLimit: true,
          hasOffline: true,
          hasCookies: false,
          hasLogging: false,
        ),
      );
    });

    test('when disposed, it should close its geosearch transport', () {
      final container = buildContainer();
      final dio = container.read(geosearchDioProvider);
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      container.dispose();

      verify(() => adapter.close(force: true)).called(1);
    });
  });

  group('geosearchRepositoryProvider', () {
    test('when read, it should use the authenticated geosearch client', () {
      final dio = MockDio();
      final container = ProviderContainer(overrides: [geosearchDioProvider.overrideWithValue(dio)]);
      addTearDown(container.dispose);

      final repository = container.read(geosearchRepositoryProvider);

      expect(repository.geosearchDio, same(dio));
    });
  });

  group('goRouterProvider', () {
    late MockSharedPreferencesAsync prefs;
    late MockFlutterSecureStorage secureStorage;
    late MockFeedRepository feedRepository;

    setUp(() {
      prefs = MockSharedPreferencesAsync();
      secureStorage = MockFlutterSecureStorage();
      when(() => prefs.getBool(any())).thenAnswer((_) async => false);
      when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

      feedRepository = MockFeedRepository();
      when(() => feedRepository.getFeedJobs()).thenThrow(StateError('feed loading is not part of this test'));
    });

    Future<ProviderContainer> buildContainer() async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesAsyncProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(secureStorage),
          feedRepositoryProvider.overrideWithValue(feedRepository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appStorageStateProvider.future);
      return container;
    }

    test('when onboarding is incomplete, it should open onboarding first', () async {
      final providerContainer = await buildContainer();

      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);

      expect(goRouter.routeInformationProvider.value.uri.path, const OnboardingRoute().location);
    });

    test('when onboarding is complete, it should open the feed first', () async {
      when(() => prefs.getBool('completed_onboarding')).thenAnswer((_) async => true);
      final providerContainer = await buildContainer();

      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);

      expect(goRouter.routeInformationProvider.value.uri.path, const FeedRoute().location);
    });

    testWidgets('when onboarding is complete, navigating to onboarding should redirect to the feed', (tester) async {
      when(() => prefs.getBool('completed_onboarding')).thenAnswer((_) async => true);
      final providerContainer = await buildContainer();
      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: providerContainer,
          child: TestApp.router(routerConfig: goRouter, mediaQueryData: const MediaQueryData(disableAnimations: true)),
        ),
      );
      await tester.pumpAndSettle();

      goRouter.go(const OnboardingRoute().location);
      await tester.pumpAndSettle();

      expect(goRouter.routerDelegate.currentConfiguration.uri.path, const FeedRoute().location);
    });

    testWidgets('when login is requested globally, it should present the sheet through the root navigator', (
      tester,
    ) async {
      final providerContainer = await buildContainer();
      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: providerContainer,
          child: TestApp.router(routerConfig: goRouter, mediaQueryData: const MediaQueryData(disableAnimations: true)),
        ),
      );
      await tester.pumpAndSettle();

      final presentation = providerContainer.read(loginSheetControllerProvider).show();
      await tester.pumpAndSettle();

      final sheetCount = find.byType(LoginSheet).evaluate().length;
      Navigator.of(tester.element(find.byType(LoginSheet))).pop();
      await tester.pumpAndSettle();
      await presentation;

      expect(sheetCount, 1);
    });

    test('when onboarding completes after router creation, it should keep the same router instance', () async {
      when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
      final providerContainer = await buildContainer();
      final initialRouter = providerContainer.read(goRouterProvider);
      addTearDown(initialRouter.dispose);

      await providerContainer.read(appStorageStateProvider.notifier).completeOnboarding();

      expect(providerContainer.read(goRouterProvider), same(initialRouter));
    });

    testWidgets(
      'when onboarding completes after router creation, navigating to onboarding should redirect to the feed',
      (tester) async {
        when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
        final providerContainer = await buildContainer();
        final goRouter = providerContainer.read(goRouterProvider);
        addTearDown(goRouter.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: providerContainer,
            child: TestApp.router(
              routerConfig: goRouter,
              mediaQueryData: const MediaQueryData(disableAnimations: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await providerContainer.read(appStorageStateProvider.notifier).completeOnboarding();
        goRouter.go(const FeedRoute().location);
        await tester.pumpAndSettle();

        goRouter.go(const OnboardingRoute().location);
        await tester.pumpAndSettle();

        expect(goRouter.routerDelegate.currentConfiguration.uri.path, const FeedRoute().location);
      },
    );
  });
}
