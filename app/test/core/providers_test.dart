import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/onboarding/onboarding_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../mocks.dart';
import '../utils/test_app.dart';

void main() {
  group('cataquiApiV1DioProvider', () {
    test('when read, it should prefix the configured Cataquí API root URL with v1', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.options.baseUrl, 'https://staging.api.cataqui.com/v1');
    });

    test('when resolving an endpoint, it should keep the v1 API prefix', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(
        RequestOptions(baseUrl: dio.options.baseUrl, path: '/feed').uri.toString(),
        'https://staging.api.cataqui.com/v1/feed',
      );
    });

    test('when read, it should include the accept-language header from the current locale', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );

      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.options.headers['accept-language'], 'pt-BR');
    });

    test('when flavor is development, it should include request logging', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'development'))],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isTrue);
    });

    test('when flavor is production, it should skip request logging', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is LogInterceptor), isFalse);
    });

    test('when flavor is production, it should register the offline error interceptor', () {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: 'production'))],
      );
      addTearDown(container.dispose);

      final dio = container.read(cataquiApiV1DioProvider);

      expect(dio.interceptors.any((interceptor) => interceptor is OfflineErrorDioInterceptor), isTrue);
    });
  });

  group('goRouterProvider', () {
    late MockSharedPreferencesAsync prefs;
    late MockFeedRepository feedRepository;

    setUp(() {
      prefs = MockSharedPreferencesAsync();
      when(() => prefs.getBool(any())).thenAnswer((_) async => false);

      feedRepository = MockFeedRepository();
      when(() => feedRepository.getFeedJobs()).thenThrow(StateError('feed loading is not part of this test'));
    });

    Future<ProviderContainer> buildContainer() async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesAsyncProvider.overrideWithValue(prefs),
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
