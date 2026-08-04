import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_route.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../utils/test_app.dart';

abstract final class PosterOnboardingRouteTestHelpers {
  static Future<void> pumpRoute({required WidgetTester tester}) async {
    final router = GoRouter(initialLocation: const PosterOnboardingRoute().location, routes: [$posterOnboardingRoute]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationProvider.overrideWithValue(AppLocale.ptBr.buildSync())],
        child: TestApp.router(routerConfig: router, mediaQueryData: const MediaQueryData(disableAnimations: true)),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('when opening the poster onboarding route, it should show the poster onboarding screen', (tester) async {
    await PosterOnboardingRouteTestHelpers.pumpRoute(tester: tester);

    expect(find.byType(PosterOnboardingView), findsOneWidget);
  });
}
