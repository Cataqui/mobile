import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/test_app.dart';
import '../post_test_state.dart';

abstract final class PostPaymentViewTestHelpers {
  static Future<void> openPayment(
    WidgetTester tester, {
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
    double keyboardInset = 0,
  }) async {
    await pumpPost(
      tester,
      initialPostData: initialPostData,
      disableAnimations: disableAnimations,
      keyboardInset: keyboardInset,
    );
    await tester.tap(find.byKey(const ValueKey('post_payment_chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  static Future<void> pumpPost(
    WidgetTester tester, {
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
    double keyboardInset = 0,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844)
      ..viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: MediaQueryData(
          size: const Size(390, 844),
          devicePixelRatio: 1,
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
          textScaler: TextScaler.noScaling,
          disableAnimations: disableAnimations,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          postStateProvider.overrideWith(() => PostTestState(initialData: initialPostData)),
        ],
        child: const PostView(),
      ),
    );
    await tester.pumpAndSettle();
  }
}
