import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks.dart';
import '../../../utils/test_app.dart';
import '../../../widgets/whatsapp_connection_button/whatsapp_connection_button_test_helpers.dart';

abstract final class WelcomeLoginTestHelpers {
  static GoRouter createRouter() => GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeView()),
      GoRoute(
        path: '/feed',
        builder: (_, _) => const Scaffold(body: Text('Feed destination')),
      ),
    ],
  );

  static Widget app({
    required GoRouter router,
    required MockAuthRepository authRepository,
    required MockMeRepository meRepository,
    required MockWhatsapp whatsapp,
  }) => TestApp.router(
    routerConfig: router,
    mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    providerOverrides: [
      translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
      authRepositoryProvider.overrideWithValue(authRepository),
      meRepositoryProvider.overrideWithValue(meRepository),
      whatsappProvider(identifier: WhatsappConnectionButtonTestHelpers.codeReceiver).overrideWithValue(whatsapp),
    ],
  );

  static Future<void> login(WidgetTester tester) async {
    await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
  }
}
