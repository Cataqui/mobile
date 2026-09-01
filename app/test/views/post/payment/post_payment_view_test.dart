import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/payment/post_payment_view.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'post_payment_view_test_helpers.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  testWidgets('when payment is tapped, it should open on a distinct modal route', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);

    final composerRoute = ModalRoute.of(tester.element(find.byKey(const ValueKey('post_description_input'))));
    final paymentRoute = ModalRoute.of(tester.element(find.byType(PostPaymentView)));

    expect(
      (isDistinct: !identical(composerRoute, paymentRoute), isModal: paymentRoute is PageRouteBuilder<void>),
      (isDistinct: true, isModal: true),
    );
  });

  testWidgets('when the payment chip renders, it should expose one labeled button', (tester) async {
    final semantics = tester.ensureSemantics();
    await PostPaymentViewTestHelpers.pumpPost(tester);

    final tap = find.ancestor(of: find.byKey(const ValueKey('post_payment_chip')), matching: find.byType(MateoTap));
    final data = tester.getSemantics(tap).getSemanticsData();
    final matchingLabels = find.bySemanticsLabel(i18n.post.payment.chipTitle).evaluate().length;
    semantics.dispose();

    expect((button: data.flagsCollection.isButton, matchingLabels: matchingLabels), (button: true, matchingLabels: 1));
  });

  testWidgets('when the payment chip is activated through semantics, it should open the payment overlay', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await PostPaymentViewTestHelpers.pumpPost(tester);

    final node = tester.getSemantics(
      find.ancestor(of: find.byKey(const ValueKey('post_payment_chip')), matching: find.byType(MateoTap)),
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    semantics.dispose();

    expect(find.byType(PostPaymentView), findsOneWidget);
  });

  testWidgets('when payment opens, it should focus its multiline input', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final input = tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input')));

    expect(
      (focused: input.focusNode!.hasFocus, expands: input.expands, maxLines: input.maxLines),
      (focused: true, expands: true, maxLines: null),
    );
  });

  testWidgets('when payment opens, its counter should own length enforcement without an input formatter', (
    tester,
  ) async {
    await PostPaymentViewTestHelpers.openPayment(tester);

    expect(tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input'))).inputFormatters, isNull);
  });

  testWidgets('when payment opens, it should inset the rounded surface by twelve pixels', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final surfaceFinder = find.byKey(const ValueKey('post_payment_view_surface'));
    final decoration = tester.widget<Container>(surfaceFinder).decoration! as BoxDecoration;

    expect(
      (
        topLeft: tester.getTopLeft(surfaceFinder),
        bottomRight: tester.getBottomRight(surfaceFinder),
        radius: decoration.borderRadius,
      ),
      (topLeft: const Offset(12, 12), bottomRight: const Offset(378, 832), radius: BorderRadius.circular(36)),
    );
  });

  testWidgets('when the keyboard is open, it should resize the green surface above it', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, keyboardInset: 300);
    final surfaceFinder = find.byKey(const ValueKey('post_payment_view_surface'));

    expect(tester.getBottomRight(surfaceFinder), const Offset(378, 532));
  });

  testWidgets('when payment opens, it should keep its modal barrier transparent', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final route = ModalRoute.of(tester.element(find.byType(PostPaymentView)))!;

    expect(route.barrierColor!.a, 0);
  });

  testWidgets('when payment transitions, it should use its current asymmetric durations', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, disableAnimations: false);
    final route = ModalRoute.of(tester.element(find.byType(PostPaymentView)))!;

    expect(
      (opening: route.transitionDuration, closing: route.reverseTransitionDuration),
      (opening: const Duration(milliseconds: 270), closing: const Duration(milliseconds: 200)),
    );
  });

  testWidgets('when animations are disabled, it should remove payment route motion', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final route = ModalRoute.of(tester.element(find.byType(PostPaymentView)))!;

    expect(
      (opening: route.transitionDuration, closing: route.reverseTransitionDuration),
      (opening: Duration.zero, closing: Duration.zero),
    );
  });

  testWidgets('when payment is blank, it should keep confirmation enabled', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);

    expect(
      tester.widget<MateoFloatingActionButton>(find.byKey(const ValueKey('post_payment_confirm_button'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('when payment is empty, it should show an empty character count', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);

    expect(
      (value: find.text('0').evaluate().length, suffix: find.text('/50').evaluate().length),
      (value: 1, suffix: 1),
    );
  });

  testWidgets('when payment changes, it should update the character count', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), 'Pagamento');
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const ValueKey('mateo_character_counter_value'))).data, '9');
  });

  testWidgets('when payment exceeds fifty characters, it should limit the input', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), 'a' * 51);
    await tester.pump();

    expect(tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input'))).controller!.text, 'a' * 50);
  });

  testWidgets('when payment is confirmed, it should trim and commit the text', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostPaymentView)));
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), r'  R$ 200 por dia  ');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('post_payment_confirm_button')));
    await tester.pumpAndSettle();

    expect(container.read(postStateProvider).payment, r'R$ 200 por dia');
  });

  testWidgets('when payment is confirmed, it should close and update the chip', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), r'R$ 200 por dia');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('post_payment_confirm_button')));
    await tester.pumpAndSettle();

    expect(
      (view: find.byType(PostPaymentView).evaluate().length, label: find.text(r'R$ 200 por dia').evaluate().length),
      (view: 0, label: 1),
    );
  });

  testWidgets('when an empty payment is confirmed, it should clear it and restore the chip label', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, initialPostData: const PostData(payment: r'R$ 150'));
    final container = ProviderScope.containerOf(tester.element(find.byType(PostPaymentView)));
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), '');
    await tester.tap(find.byKey(const ValueKey('post_payment_confirm_button')));
    await tester.pumpAndSettle();

    expect(
      (
        payment: container.read(postStateProvider).payment,
        labelCount: find.text(i18n.post.payment.chipTitle).evaluate().length,
      ),
      (payment: null, labelCount: 1),
    );
  });

  testWidgets('when A Combinar is confirmed, it should commit and close', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostPaymentView)));
    await tester.tap(find.text(i18n.post.payment.negotiable.toggleTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post_payment_confirm_button')));
    await tester.pumpAndSettle();

    expect(
      (payment: container.read(postStateProvider).payment, view: find.byType(PostPaymentView).evaluate().length),
      (payment: i18n.post.payment.negotiable.inputText, view: 0),
    );
  });

  testWidgets('when A Combinar is selected, it should place the caret at the end and preserve focus', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    await tester.tap(find.text(i18n.post.payment.negotiable.toggleTitle));
    await tester.pumpAndSettle();
    final input = tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input')));

    expect(
      (
        text: input.controller!.text,
        selection: input.controller!.selection,
        readOnly: input.readOnly,
        focused: input.focusNode!.hasFocus,
      ),
      (
        text: i18n.post.payment.negotiable.inputText,
        selection: TextSelection.collapsed(offset: i18n.post.payment.negotiable.inputText.length),
        readOnly: false,
        focused: true,
      ),
    );
  });

  testWidgets('when the toggle changes directly, it should preserve the requested value', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    final toggle = tester.widget<MateoToggle>(find.byKey(const ValueKey('post_payment_negotiable_toggle')));
    final animation = toggle.controller!.setValue(true);

    await toggle.onChanged!(true, animation);
    await tester.pump();

    expect(
      (
        value: toggle.controller!.value,
        text: tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input'))).controller!.text,
      ),
      (value: true, text: i18n.post.payment.negotiable.inputText),
    );
  });

  testWidgets('when A Combinar is typed with different casing, it should enable the toggle automatically', (
    tester,
  ) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), '  a cOmBiNaR  ');
    await tester.pump();
    final input = tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input')));
    final toggle = tester.widget<MateoToggle>(find.byKey(const ValueKey('post_payment_negotiable_toggle')));

    expect((text: input.controller!.text, toggled: toggle.controller!.value), (text: '  a cOmBiNaR  ', toggled: true));
  });

  testWidgets('when A Combinar text is edited, it should preserve the input and disable the toggle', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester);
    await tester.tap(find.text(i18n.post.payment.negotiable.toggleTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), r'R$ 200 por dia');
    await tester.pump();
    final input = tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input')));
    final toggle = tester.widget<MateoToggle>(find.byKey(const ValueKey('post_payment_negotiable_toggle')));

    expect(
      (text: input.controller!.text, toggled: toggle.controller!.value),
      (text: r'R$ 200 por dia', toggled: false),
    );
  });

  testWidgets('when reopening typed payment, it should restore the text', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(
      tester,
      initialPostData: const PostData(payment: 'Duas cestas básicas'),
    );

    expect(
      tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input'))).controller!.text,
      'Duas cestas básicas',
    );
  });

  testWidgets('when reopening A Combinar, it should restore the enabled toggle', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(
      tester,
      initialPostData: PostData(payment: i18n.post.payment.negotiable.inputText),
    );

    expect(
      tester.widget<MateoToggle>(find.byKey(const ValueKey('post_payment_negotiable_toggle'))).controller!.value,
      isTrue,
    );
  });

  testWidgets('when disabling A Combinar, it should focus an empty editable field', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(
      tester,
      initialPostData: PostData(payment: i18n.post.payment.negotiable.inputText),
    );
    await tester.tap(find.byKey(const ValueKey('post_payment_negotiable_toggle')));
    await tester.pump();
    final input = tester.widget<TextField>(find.byKey(const ValueKey('post_payment_input')));

    expect(
      (text: input.controller!.text, readOnly: input.readOnly, focused: input.focusNode!.hasFocus),
      (text: '', readOnly: false, focused: true),
    );
  });

  testWidgets('when closing edited payment, it should discard the edits', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, initialPostData: const PostData(payment: r'R$ 150'));
    final container = ProviderScope.containerOf(tester.element(find.byType(PostPaymentView)));
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), r'R$ 300');
    await tester.tap(find.byKey(const ValueKey('post_payment_close_button')));
    await tester.pumpAndSettle();

    expect(container.read(postStateProvider).payment, r'R$ 150');
  });

  testWidgets('when closing changed A Combinar edits, it should preserve the committed payment', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, initialPostData: const PostData(payment: r'R$ 150'));
    final container = ProviderScope.containerOf(tester.element(find.byType(PostPaymentView)));
    await tester.tap(find.text(i18n.post.payment.negotiable.toggleTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post_payment_close_button')));
    await tester.pumpAndSettle();

    expect(container.read(postStateProvider).payment, r'R$ 150');
  });

  testWidgets('when system back closes edited payment, it should discard the edits', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, initialPostData: const PostData(payment: r'R$ 150'));
    final container = ProviderScope.containerOf(tester.element(find.byType(PostPaymentView)));
    await tester.enterText(find.byKey(const ValueKey('post_payment_input')), r'R$ 300');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(container.read(postStateProvider).payment, r'R$ 150');
  });

  testWidgets('when payment is selected, the chip should use the committed title', (tester) async {
    await PostPaymentViewTestHelpers.pumpPost(tester, initialPostData: const PostData(payment: 'Duas cestas básicas'));

    expect(find.text('Duas cestas básicas'), findsOneWidget);
  });

  testWidgets('when payment opens, the surface morph should use ease out cubic', (tester) async {
    await PostPaymentViewTestHelpers.openPayment(tester, disableAnimations: false);
    final morph = tester.widget<Morph>(
      find.ancestor(of: find.byKey(const ValueKey('post_payment_view_surface')), matching: find.byType(Morph)),
    );

    expect(morph.curve, Curves.easeOutCubic);
  });
}
