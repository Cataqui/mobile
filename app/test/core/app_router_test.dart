import 'package:cataqui_app/core/app_router.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouter', () {
    late AppRouter appRouter;

    setUp(() {
      appRouter = AppRouter();
    });

    test('when created, it should expose a non-null router config', () {
      expect(appRouter.routerConfig, isNotNull);
      expect(appRouter.routerConfig, isA<RouterConfig<Object>>());
    });

    test('when resolved from the provider, it should return an AppRouter instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      expect(router, isA<AppRouter>());
    });

    test('when watching the provider twice, it should return the same instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(appRouterProvider);
      final second = container.read(appRouterProvider);

      expect(identical(first, second), isTrue);
    });
  });
}
