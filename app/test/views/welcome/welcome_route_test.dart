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
import '../../widgets/whatsapp_connection_button/whatsapp_connection_button_test_helpers.dart';

abstract final class WelcomeRouteTestHelpers {
  static Future<({ProviderContainer container, GoRouter router})> pumpRoute({
    required WidgetTester tester,
    MockSharedPreferencesAsync? sharedPreferences,
    MockAuthRepository? authRepository,
    MockWhatsapp? whatsapp,
  }) async {
    final resolvedSharedPreferences = sharedPreferences ?? MockSharedPreferencesAsync();
    when(() => resolvedSharedPreferences.getBool(any())).thenAnswer((_) async => null);
    when(() => resolvedSharedPreferences.setBool(any(), any())).thenAnswer((_) async {});
    final router = GoRouter(
      observers: [MateoNavigatorObserver()],
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
          if (authRepository != null) authRepositoryProvider.overrideWithValue(authRepository),
          if (whatsapp != null)
            whatsappProvider(identifier: WhatsappConnectionButtonTestHelpers.codeReceiver).overrideWithValue(whatsapp),
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

  for (final hasSession in [false, true]) {
    testWidgets('connecting WhatsApp stays on Welcome with an existing session: $hasSession', (tester) async {
      final authRepository = MockAuthRepository();
      final whatsapp = MockWhatsapp();
      WhatsappConnectionButtonTestHelpers.stubSuccessfulRegistration(
        authRepository: authRepository,
        whatsapp: whatsapp,
      );
      WhatsappConnectionButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
      final (:container, :router) = await WelcomeRouteTestHelpers.pumpRoute(
        tester: tester,
        authRepository: authRepository,
        whatsapp: whatsapp,
      );
      if (hasSession) {
        await container
            .read(appAuthStateProvider.notifier)
            .setSession(
              AuthSessionDto.fixture().copyWith(
                accessTokenExpiresAt: DateTime.utc(2100),
                refreshTokenExpiresAt: DateTime.utc(2100),
              ),
            );
      }
      expect(find.text('Conectar WhatsApp'), findsOneWidget);
      expect(find.byType(MateoMenuButton), findsNothing);
      await WhatsappConnectionButtonTestHelpers.startConnection(tester: tester);
      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await tester.pumpAndSettle();

      expect(container.read(appAuthStateProvider), WhatsappConnectionButtonTestHelpers.authSession);
      expect(find.byType(WelcomeView), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, const WelcomeRoute().location);
    });
  }

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
