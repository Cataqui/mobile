import 'dart:async';

import 'package:cataqui_app/app.dart';
import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/dtos/auth_credentials_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/network/auth_interceptor/auth_interceptor.dart';
import 'package:cataqui_app/core/network/rate_limit/rate_limit_interceptor.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/feed/feed_view.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:cataqui_app/views/welcome/welcome_route.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_sheet/whatsapp_connection_sheet.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../fakes.dart';
import '../mocks.dart';
import '../utils/test_app.dart';
import '../views/me/fake_app_auth_state.dart';

void main() {
  group('translationProvider', () {
    test('Portuguese day plurals keep their wording without a missing-resolver warning', () {
      final printedMessages = <String>[];
      final dayLabels = runZoned(() {
        final container = ProviderContainer();
        try {
          final translations = container.read(translationProvider);
          return [
            for (final count in [0, 1, 2]) translations.feedJob.timeAgo.days(count: count),
          ];
        } finally {
          container.dispose();
        }
      }, zoneSpecification: ZoneSpecification(print: (_, _, _, message) => printedMessages.add(message)));

      expect(dayLabels, ['0 dias atrás', '1 dia atrás', '2 dias atrás']);
      expect(printedMessages, isEmpty);
    });
  });

  group('deviceCornerRadiiProvider', () {
    test('when first read, it should not assume display corner radii', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(deviceCornerRadiiProvider), isNull);
    });

    testWidgets('when preloaded, it should publish the detected display corner radii', (tester) async {
      const detectedRadii = BorderRadius.only(
        topLeft: Radius.circular(48),
        topRight: Radius.circular(49),
        bottomLeft: Radius.circular(50),
        bottomRight: Radius.circular(51),
      );
      final display = FakeDeviceDisplay(value: detectedRadii);
      final container = ProviderContainer(overrides: [deviceProvider.overrideWithValue(Device(display: display))]);
      addTearDown(container.dispose);
      late BuildContext lookupContext;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              lookupContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await container.read(deviceCornerRadiiProvider.notifier).preload(lookupContext);

      expect(container.read(deviceCornerRadiiProvider), detectedRadii);
    });

    testWidgets('when display detection fails, it should retain an unavailable value', (tester) async {
      final display = FakeDeviceDisplay(error: StateError('Display lookup failed'));
      final container = ProviderContainer(overrides: [deviceProvider.overrideWithValue(Device(display: display))]);
      addTearDown(container.dispose);
      late BuildContext lookupContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            lookupContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      await container.read(deviceCornerRadiiProvider.notifier).preload(lookupContext);

      expect(container.read(deviceCornerRadiiProvider), isNull);
    });

    testWidgets('when display detection returns no measurement, it should retain an unavailable value', (tester) async {
      final display = FakeDeviceDisplay();
      final container = ProviderContainer(overrides: [deviceProvider.overrideWithValue(Device(display: display))]);
      addTearDown(container.dispose);
      late BuildContext lookupContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            lookupContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      await container.read(deviceCornerRadiiProvider.notifier).preload(lookupContext);

      expect(container.read(deviceCornerRadiiProvider), isNull);
    });

    testWidgets('when preload is requested repeatedly, it should perform one display lookup', (tester) async {
      final display = FakeDeviceDisplay(value: BorderRadius.zero);
      final container = ProviderContainer(overrides: [deviceProvider.overrideWithValue(Device(display: display))]);
      addTearDown(container.dispose);
      late BuildContext lookupContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            lookupContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      await Future.wait([
        container.read(deviceCornerRadiiProvider.notifier).preload(lookupContext),
        container.read(deviceCornerRadiiProvider.notifier).preload(lookupContext),
      ]);

      expect(display.requestCount, 1);
    });

    testWidgets('when the app root builds, it should start preloading display corner radii', (tester) async {
      final display = FakeDeviceDisplay(value: BorderRadius.zero);
      final router = GoRouter(
        observers: [MateoNavigatorObserver()],
        routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink())],
      );
      final container = ProviderContainer(
        overrides: [
          deviceProvider.overrideWithValue(Device(display: display)),
          goRouterProvider.overrideWithValue(router),
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
        ],
      );
      addTearDown(() {
        router.dispose();
        container.dispose();
      });

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const CataquiApp()));
      await tester.pump();

      expect(display.requestCount, 1);
    });
  });

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

  group('authV1DioProvider', () {
    for (final environment in [
      (flavor: 'development', host: 'staging.auth.cataqui.com'),
      (flavor: 'production', host: 'auth.cataqui.com'),
    ]) {
      test(
        'when using ${environment.flavor}, it should send login requests directly to Auth with the v1 prefix',
        () async {
          final container = ProviderContainer(
            overrides: [appConfigProvider.overrideWithValue(AppConfig(flavor: environment.flavor))],
          );
          addTearDown(container.dispose);
          await container.read(cataquiApiCookieJarProvider.future);
          final dio = container.read(authV1DioProvider);

          expect(
            (
              url: RequestOptions(baseUrl: dio.options.baseUrl, path: '/notp/intents').uri.toString(),
              language: dio.options.headers['accept-language'],
              authenticates: dio.interceptors.any((interceptor) => interceptor is AuthInterceptor),
            ),
            (url: 'https://${environment.host}/v1/notp/intents', language: 'pt-BR', authenticates: false),
          );
        },
      );
    }
  });

  group('mapsDioProvider', () {
    late MockAuthRepository authRepository;
    late MockHttpClientAdapter adapter;

    setUp(() {
      authRepository = MockAuthRepository();
      adapter = MockHttpClientAdapter();
    });

    test(
      'when searching places, it should send the session bearer token without exchanging it for a Maps token',
      () async {
        registerFallbackValue(RequestOptions(path: '/places/search'));
        final session = AuthSessionDto.fixture().copyWith(
          accessToken: 'session-access-token',
          accessTokenExpiresAt: DateTime.utc(2100),
        );
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production')),
            appAuthStateProvider.overrideWith(() => FakeAppAuthState(session)),
          ],
        );
        addTearDown(container.dispose);
        final dio = container.read(mapsDioProvider)..httpClientAdapter = adapter;
        late RequestOptions request;
        when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
          request = invocation.positionalArguments.first as RequestOptions;
          return ResponseBody.fromString(
            '{}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        await dio.query<Map<String, Object?>>(
          '/places/search',
          data: {'query': 'Paulista', 'sessionToken': 'places-session'},
        );

        expect(
          {
            'method': request.method,
            'url': request.uri.toString(),
            'authorization': request.headers['Authorization'],
            'data': request.data,
          },
          {
            'method': 'QUERY',
            'url': 'https://maps.cataqui.com/places/search',
            'authorization': 'Bearer session-access-token',
            'data': {'query': 'Paulista', 'sessionToken': 'places-session'},
          },
        );
      },
    );

    ProviderContainer buildContainer({String? flavor}) {
      return ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          if (flavor != null) appConfigProvider.overrideWithValue(AppConfig(flavor: flavor)),
        ],
      );
    }

    test('when the flavor is development, it should target the staging maps worker', () {
      final container = buildContainer(flavor: 'development');
      addTearDown(container.dispose);

      final dio = container.read(mapsDioProvider);

      expect(dio.options.baseUrl, 'https://staging.maps.cataqui.com');
    });

    test('when the flavor is production, it should target the production maps worker', () {
      final container = buildContainer(flavor: 'production');
      addTearDown(container.dispose);

      final dio = container.read(mapsDioProvider);

      expect(dio.options.baseUrl, 'https://maps.cataqui.com');
    });

    test('when read, it should use the active locale and network timeouts', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      final dio = container.read(mapsDioProvider);

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

    test('when read in production, it should authenticate and convert failures without logging sensitive traffic', () {
      final container = buildContainer(flavor: 'production');
      addTearDown(container.dispose);

      final dio = container.read(mapsDioProvider);

      expect(
        (
          hasAccessToken: dio.interceptors.any((interceptor) => interceptor is AuthInterceptor),
          hasRateLimit: dio.interceptors.any((interceptor) => interceptor is RateLimitInterceptor),
          hasOffline: dio.interceptors.any((interceptor) => interceptor is OfflineErrorDioInterceptor),
          hasCookies: dio.interceptors.any((interceptor) => interceptor is CookieManager),
          hasLogging: dio.interceptors.any((interceptor) => interceptor is LogInterceptor),
        ),
        (hasAccessToken: true, hasRateLimit: true, hasOffline: true, hasCookies: false, hasLogging: false),
      );
    });

    test('when read in development, it should include request logging', () {
      final container = buildContainer(flavor: 'development');
      addTearDown(container.dispose);

      final dio = container.read(mapsDioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isTrue);
    });

    test('when disposed, it should close its maps transport', () {
      final container = buildContainer();
      final dio = container.read(mapsDioProvider);
      final adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      container.dispose();

      verify(() => adapter.close(force: true)).called(1);
    });
  });

  group('mapsRepositoryProvider', () {
    test('when read, it should use the authenticated maps client', () {
      final dio = MockDio();
      final container = ProviderContainer(overrides: [mapsDioProvider.overrideWithValue(dio)]);
      addTearDown(container.dispose);

      final repository = container.read(mapsRepositoryProvider);

      expect(repository.mapsDio, same(dio));
    });
  });

  group('goRouterProvider', () {
    const routerMediaQueryData = MediaQueryData(size: Size(390, 844), disableAnimations: true);

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

    Future<ProviderContainer> buildContainer({List<Override> providerOverrides = const []}) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesAsyncProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(secureStorage),
          feedRepositoryProvider.overrideWithValue(feedRepository),
          ...providerOverrides,
        ],
      );
      addTearDown(container.dispose);
      await container.read(appStorageStateProvider.future);
      return container;
    }

    Future<(ProviderContainer, GoRouter)> pumpFeedRouter(
      WidgetTester tester, {
      List<Override> providerOverrides = const [],
    }) async {
      final providerContainer = await buildContainer(providerOverrides: providerOverrides);
      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);
      goRouter.go(const FeedRoute().location);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: providerContainer,
          child: TestApp.router(routerConfig: goRouter, mediaQueryData: routerMediaQueryData),
        ),
      );
      await tester.pumpAndSettle();

      return (providerContainer, goRouter);
    }

    AuthSessionDto authenticatedSession() {
      return AuthSessionDto.fixture().copyWith(
        accessTokenExpiresAt: DateTime.utc(2100),
        refreshTokenExpiresAt: DateTime.utc(2100),
      );
    }

    test('when no credentials are saved, it should open welcome first', () async {
      when(() => prefs.getBool('completed_onboarding')).thenAnswer((_) async => true);
      final providerContainer = await buildContainer();

      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);

      expect(goRouter.routeInformationProvider.value.uri.path, '/welcome');
      verifyNever(() => prefs.getBool('completed_onboarding'));
    });

    test('when completed progress exists without credentials, it should open welcome first', () async {
      when(
        () => prefs.getString('onboarding_data'),
      ).thenAnswer((_) async => '{"account-a":{"serverConfirmedCompleted":true}}');
      final providerContainer = await buildContainer();
      final router = providerContainer.read(goRouterProvider);
      addTearDown(router.dispose);

      expect(router.routeInformationProvider.value.uri.path, '/welcome');
    });

    test('when saved credentials are malformed, it should open Welcome', () async {
      when(() => secureStorage.read(key: 'auth_credentials')).thenAnswer((_) async => 'invalid-json');
      when(() => secureStorage.delete(key: 'auth_credentials')).thenAnswer((_) async {});
      final providerContainer = await buildContainer();
      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);

      expect(goRouter.routeInformationProvider.value.uri.path, '/welcome');
    });

    for (final expiresAt in [DateTime.utc(2000), DateTime.utc(2100)]) {
      test(
        'when credentials expiring in ${expiresAt.year} are saved without onboarding progress, it should open welcome first',
        () async {
          final credentials = AuthCredentialsDto.fixture().copyWith(refreshTokenExpiresAt: expiresAt);
          when(
            () => secureStorage.read(key: 'auth_credentials'),
          ).thenAnswer((_) async => credentials.toSecureStorageValue());
          final providerContainer = await buildContainer();

          final goRouter = providerContainer.read(goRouterProvider);
          addTearDown(goRouter.dispose);

          expect(goRouter.routeInformationProvider.value.uri.path, '/welcome');
        },
      );
    }

    for (final scenario in [
      (
        accountId: 'account-a',
        expiresAt: DateTime.utc(2100),
        progress: '{"account-a":{"serverConfirmedCompleted":true}}',
        destination: '/feed',
      ),
      (
        accountId: 'account-a',
        expiresAt: DateTime.utc(2100),
        progress: '{"account-a":{"name":" Ana "}}',
        destination: '/feed',
      ),
      (
        accountId: 'account-a',
        expiresAt: DateTime.utc(2000),
        progress: '{"account-a":{"serverConfirmedCompleted":true}}',
        destination: '/welcome',
      ),
      (
        accountId: 'account-a',
        expiresAt: DateTime.utc(2100),
        progress: '{"account-b":{"serverConfirmedCompleted":true}}',
        destination: '/welcome',
      ),
      (
        accountId: 'account-a',
        expiresAt: DateTime.utc(2100),
        progress: '{"account-a":{"name":" "}}',
        destination: '/welcome',
      ),
      (accountId: 'account-a', expiresAt: DateTime.utc(2100), progress: '{invalid', destination: '/welcome'),
      (
        accountId: null,
        expiresAt: DateTime.utc(2100),
        progress: '{"account-a":{"serverConfirmedCompleted":true}}',
        destination: '/welcome',
      ),
    ]) {
      test(
        'when starting as ${scenario.accountId} with credentials expiring in ${scenario.expiresAt.year} and progress ${scenario.progress}, it should open ${scenario.destination}',
        () async {
          final credentials = AuthCredentialsDto.fixture().copyWith(
            accountId: scenario.accountId,
            refreshTokenExpiresAt: scenario.expiresAt,
          );
          when(
            () => secureStorage.read(key: 'auth_credentials'),
          ).thenAnswer((_) async => credentials.toSecureStorageValue());
          when(() => prefs.getString('onboarding_data')).thenAnswer((_) async => scenario.progress);
          final providerContainer = await buildContainer();
          final router = providerContainer.read(goRouterProvider);
          addTearDown(router.dispose);

          expect(router.routeInformationProvider.value.uri.path, scenario.destination);
        },
      );
    }

    test('when building app routes, it should register welcome without legacy onboarding routes', () async {
      final providerContainer = await buildContainer();

      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);
      final routePaths = goRouter.configuration.routes.whereType<GoRoute>().map((route) => route.path).toSet();

      expect(
        (
          hasWelcome: routePaths.contains(const WelcomeRoute().location),
          hasOnboarding: routePaths.contains('/onboarding'),
          hasPosterOnboarding: routePaths.contains('/poster-onboarding'),
        ),
        (hasWelcome: true, hasOnboarding: false, hasPosterOnboarding: false),
      );
    });

    test('when building app routes, it should register post without legacy create-job routes', () async {
      final providerContainer = await buildContainer();

      final goRouter = providerContainer.read(goRouterProvider);
      addTearDown(goRouter.dispose);
      final routePaths = goRouter.configuration.routes.whereType<GoRoute>().map((route) => route.path).toSet();

      expect(
        (
          hasPost: routePaths.contains('/post'),
          hasPayment: routePaths.contains('/create-job/:jobId/payment'),
          hasDescription: routePaths.contains('/create-job/description'),
          hasLocation: routePaths.contains('/create-job/:jobId/location'),
        ),
        (hasPost: true, hasPayment: false, hasDescription: false, hasLocation: false),
      );
    });

    testWidgets('when credentials are saved, explicit Welcome navigation should stay on Welcome', (tester) async {
      when(
        () => secureStorage.read(key: 'auth_credentials'),
      ).thenAnswer((_) async => AuthCredentialsDto.fixture().toSecureStorageValue());
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

      goRouter.go(const WelcomeRoute().location);
      await tester.pumpAndSettle();

      expect(goRouter.routerDelegate.currentConfiguration.uri.path, '/welcome');
    });

    testWidgets('when unauthenticated, navigating to protected app route should present connection', (tester) async {
      final (providerContainer, _) = await pumpFeedRouter(tester);

      unawaited(
        providerContainer
            .read(appRouterProvider.notifier)
            .push(tester.element(find.byType(FeedView)), const PostRoute()),
      );
      await tester.pumpAndSettle();
      final whatsappConnectionSheetCount = find.byType(WhatsappConnectionSheet).evaluate().length;
      Navigator.of(tester.element(find.byType(WhatsappConnectionSheet))).pop();
      await tester.pumpAndSettle();

      expect(whatsappConnectionSheetCount, 1);
    });

    testWidgets('when the session is expired, navigating to protected app route should present connection', (
      tester,
    ) async {
      final (providerContainer, _) = await pumpFeedRouter(tester);
      await providerContainer
          .read(appAuthStateProvider.notifier)
          .setSession(
            authenticatedSession().copyWith(
              accessTokenExpiresAt: DateTime.utc(2000),
              refreshTokenExpiresAt: DateTime.utc(2000),
            ),
          );

      unawaited(
        providerContainer
            .read(appRouterProvider.notifier)
            .push(tester.element(find.byType(FeedView)), const PostRoute()),
      );
      await tester.pumpAndSettle();
      final whatsappConnectionSheetCount = find.byType(WhatsappConnectionSheet).evaluate().length;
      Navigator.of(tester.element(find.byType(WhatsappConnectionSheet))).pop();
      await tester.pumpAndSettle();

      expect(whatsappConnectionSheetCount, 1);
    });

    testWidgets('when connection is dismissed, navigating to protected app route should keep the feed open', (
      tester,
    ) async {
      final (providerContainer, goRouter) = await pumpFeedRouter(tester);

      unawaited(
        providerContainer
            .read(appRouterProvider.notifier)
            .push(tester.element(find.byType(FeedView)), const PostRoute()),
      );
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(WhatsappConnectionSheet))).pop();
      await tester.pumpAndSettle();

      expect(goRouter.routerDelegate.currentConfiguration.uri.path, const FeedRoute().location);
    });

    testWidgets('when authenticated, going to protected app route should open the post flow', (tester) async {
      final (providerContainer, _) = await pumpFeedRouter(tester);
      await providerContainer.read(appAuthStateProvider.notifier).setSession(authenticatedSession());

      await providerContainer
          .read(appRouterProvider.notifier)
          .go(tester.element(find.byType(FeedView)), const PostRoute());
      await tester.pumpAndSettle();

      expect(
        (
          postCount: find.byType(PostView).evaluate().length,
          connectionCount: find.byType(WhatsappConnectionSheet).evaluate().length,
        ),
        (postCount: 1, connectionCount: 0),
      );
    });

    testWidgets('when connection succeeds, navigating to protected app route should resume the post flow', (
      tester,
    ) async {
      final whatsappConnectionSheetController = MockWhatsappConnectionSheetController();
      late ProviderContainer providerContainer;
      when(whatsappConnectionSheetController.show).thenAnswer((_) async {
        await providerContainer.read(appAuthStateProvider.notifier).setSession(authenticatedSession());
        return true;
      });
      (providerContainer, _) = await pumpFeedRouter(
        tester,
        providerOverrides: [
          whatsappConnectionSheetControllerProvider.overrideWithValue(whatsappConnectionSheetController),
        ],
      );

      unawaited(
        providerContainer
            .read(appRouterProvider.notifier)
            .push(tester.element(find.byType(FeedView)), const PostRoute()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PostView), findsOneWidget);
    });

    testWidgets('when authentication fails, navigating to protected app route should show the connection error', (
      tester,
    ) async {
      final whatsappConnectionSheetController = MockWhatsappConnectionSheetController();
      when(whatsappConnectionSheetController.show).thenThrow(StateError('connection unavailable'));
      final (providerContainer, goRouter) = await pumpFeedRouter(
        tester,
        providerOverrides: [
          whatsappConnectionSheetControllerProvider.overrideWithValue(whatsappConnectionSheetController),
        ],
      );

      unawaited(
        providerContainer
            .read(appRouterProvider.notifier)
            .push(tester.element(find.byType(FeedView)), const PostRoute()),
      );
      await tester.pumpAndSettle();

      expect(
        (
          path: goRouter.routerDelegate.currentConfiguration.uri.path,
          errorCount: find
              .text(providerContainer.read(translationProvider).whatsappConnectionButton.error)
              .evaluate()
              .length,
        ),
        (path: const FeedRoute().location, errorCount: 1),
      );
    });

    testWidgets('when unauthenticated navigation is requested twice, it should open only one post route', (
      tester,
    ) async {
      final whatsappConnectionSheetController = MockWhatsappConnectionSheetController();
      final connectionCompleter = Completer<bool>();
      var connectionRequestCount = 0;
      late ProviderContainer providerContainer;
      when(whatsappConnectionSheetController.show).thenAnswer((_) async {
        connectionRequestCount += 1;
        final didConnect = await connectionCompleter.future;
        if (!didConnect) return false;

        await providerContainer.read(appAuthStateProvider.notifier).setSession(authenticatedSession());
        return true;
      });
      (providerContainer, _) = await pumpFeedRouter(
        tester,
        providerOverrides: [
          whatsappConnectionSheetControllerProvider.overrideWithValue(whatsappConnectionSheetController),
        ],
      );

      final appRouter = providerContainer.read(appRouterProvider.notifier);
      final context = tester.element(find.byType(FeedView));
      unawaited(appRouter.push(context, const PostRoute()));
      unawaited(appRouter.push(context, const PostRoute()));
      await tester.pump();
      connectionCompleter.complete(true);
      await tester.pumpAndSettle();

      expect(
        (connectionRequestCount: connectionRequestCount, postCount: find.byType(PostView).evaluate().length),
        (connectionRequestCount: 1, postCount: 1),
      );
    });

    testWidgets('when connection is requested globally, it should present the sheet through the root navigator', (
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

      final presentation = providerContainer.read(whatsappConnectionSheetControllerProvider).show();
      await tester.pumpAndSettle();

      final sheetCount = find.byType(WhatsappConnectionSheet).evaluate().length;
      Navigator.of(tester.element(find.byType(WhatsappConnectionSheet))).pop();
      await tester.pumpAndSettle();
      await presentation;

      expect(sheetCount, 1);
    });

    test(
      'when credentials are saved after router creation, it should keep the same router instance and initial location',
      () async {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        final providerContainer = await buildContainer();
        final initialRouter = providerContainer.read(goRouterProvider);
        addTearDown(initialRouter.dispose);

        await providerContainer
            .read(appStorageStateProvider.notifier)
            .setAuthCredentials(credentials: AuthCredentialsDto.fixture());

        expect(providerContainer.read(goRouterProvider), same(initialRouter));
        expect(initialRouter.routeInformationProvider.value.uri.path, '/welcome');
      },
    );

    testWidgets(
      'when credentials are saved after router creation, explicit Welcome navigation should stay on Welcome',
      (tester) async {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
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
        await providerContainer
            .read(appStorageStateProvider.notifier)
            .setAuthCredentials(credentials: AuthCredentialsDto.fixture());
        goRouter.go(const FeedRoute().location);
        await tester.pumpAndSettle();

        goRouter.go(const WelcomeRoute().location);
        await tester.pumpAndSettle();

        expect(goRouter.routerDelegate.currentConfiguration.uri.path, '/welcome');
      },
    );
  });
}
