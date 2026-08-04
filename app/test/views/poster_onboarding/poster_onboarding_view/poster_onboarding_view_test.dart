import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/poster_onboarding/poster_onboarding_view/poster_onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'poster_onboarding_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  testWidgets('when the poster onboarding opens, it should show the poster promise', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester);
    final headlineMotion = tester.widget<TextMotion>(find.byKey(const ValueKey('poster_onboarding_headline_motion')));

    expect(headlineMotion.child.data, i18n.posterOnboarding.headline);
  });

  testWidgets('when the poster promise is shown, it should use 28 pixel semibold text', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester);
    final headline = tester.widget<TextMotion>(find.byKey(const ValueKey('poster_onboarding_headline_motion'))).child;

    expect((size: headline.style!.fontSize, weight: headline.style!.fontWeight), (size: 28, weight: FontWeight.w600));
  });

  testWidgets('when the poster onboarding opens, it should label the example scene for accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester);

    try {
      expect(find.bySemanticsLabel(i18n.posterOnboarding.sceneAccessibilityLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when the poster onboarding opens, it should keep the WhatsApp draft action enabled', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester);
    final button = tester.widget<MateoButton>(find.byKey(const ValueKey('poster_onboarding_whatsapp_button')));

    expect(button.onPressed, isNotNull);
  });

  testWidgets('when tapping the WhatsApp login draft button, it should remain on poster onboarding', (tester) async {
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester);
    await tester.ensureVisible(find.byKey(const ValueKey('poster_onboarding_whatsapp_button')));
    await tester.tap(find.byKey(const ValueKey('poster_onboarding_whatsapp_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PosterOnboardingView), findsOneWidget);
  });

  testWidgets('when text is enlarged on a compact phone, it should remain scrollable without layout errors', (
    tester,
  ) async {
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester, width: 320, height: 568, textScaler: 2);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('poster_onboarding_whatsapp_button')), 300);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('when the poster onboarding opens, its top edge fade should remain above the scrolling content', (
    tester,
  ) async {
    await PosterOnboardingViewTestHelpers.pumpView(tester: tester);
    final stack = tester.widget<Stack>(find.descendant(of: find.byType(Scaffold), matching: find.byType(Stack)).first);

    expect(stack.children.last.key, const ValueKey('poster_onboarding_top_edge_fade_layer'));
  });
}
