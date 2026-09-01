import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/location/post_location_view.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';
import 'post_test_state.dart';

void main() {
  late Translations i18n;

  setUpAll(() async {
    i18n = await AppLocale.ptBr.build();
  });

  test('when reading the post route location, it should use the post path', () {
    expect(const PostRoute().location, '/post');
  });

  testWidgets('when opening the post route, it should use a Mateo page', (tester) async {
    final goRouter = GoRouter(initialLocation: const PostRoute().location, routes: [$postRoute]);
    addTearDown(goRouter.dispose);

    await tester.pumpWidget(TestApp.router(routerConfig: goRouter));
    await tester.pumpAndSettle();

    expect(tester.widget<Navigator>(find.byType(Navigator)).pages.single, isA<MateoPage<void>>());
  });

  testWidgets('when opening the post route, it should use an explicit Mateo transition', (tester) async {
    final goRouter = GoRouter(initialLocation: const PostRoute().location, routes: [$postRoute]);
    addTearDown(goRouter.dispose);

    await tester.pumpWidget(TestApp.router(routerConfig: goRouter));
    await tester.pumpAndSettle();
    final page = tester.widget<Navigator>(find.byType(Navigator)).pages.single as MateoPage<void>;

    expect(page.transition, isNotNull);
  });

  testWidgets('when the post composer opens, it should show the localized title', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);

    expect(
      find.descendant(of: find.byKey(const ValueKey('post_header')), matching: find.text(i18n.post.title)),
      findsOneWidget,
    );
  });

  testWidgets('when the post composer opens, it should show the localized description placeholder', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);

    expect(find.text(i18n.post.description.placeholder), findsOneWidget);
  });

  testWidgets('when the post composer opens, it should show all post detail chips', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);

    expect(
      (
        location: find.text(i18n.post.location.chipTitle).evaluate().length,
        payment: find.text(i18n.post.payment.chipTitle).evaluate().length,
        contact: find.text(i18n.post.contact.chipTitle).evaluate().length,
      ),
      (location: 1, payment: 1, contact: 1),
    );
  });

  testWidgets('when the post details rest above the keyboard, they should use their requested insets', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    final postViewContext = tester.element(find.byType(PostView));
    final keyboardTop = MediaQuery.sizeOf(postViewContext).height - MediaQuery.viewInsetsOf(postViewContext).bottom;

    expect(
      (
        descriptionLeft: tester.getTopLeft(find.byKey(const ValueKey('post_description_input'))).dx,
        chipLeft: tester.getTopLeft(find.byKey(const ValueKey('post_location_chip'))).dx,
        chipBottom: keyboardTop - tester.getBottomLeft(find.byKey(const ValueKey('post_contact_chip'))).dy,
      ),
      (descriptionLeft: 20, chipLeft: 16, chipBottom: 16),
    );
  });

  testWidgets('when tapping location, it should open location without changing the post route', (tester) async {
    final goRouter = GoRouter(initialLocation: const PostRoute().location, routes: [$postRoute]);
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: goRouter,
        providerOverrides: PostViewTestHelpers.providerOverrides(i18n: i18n),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('post_location_chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      (location: goRouter.state.matchedLocation, locationViewCount: find.byType(PostLocationView).evaluate().length),
      (location: '/post', locationViewCount: 1),
    );
  });

  testWidgets('when post state contains a location label, the location chip should display it', (tester) async {
    await PostViewTestHelpers.pump(
      tester,
      i18n: i18n,
      initialPostData: const PostData(locationTitle: 'Avenida Paulista'),
    );

    expect(find.text('Avenida Paulista'), findsOneWidget);
  });

  testWidgets('when the post composer opens, it should keep publishing disabled', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);

    expect(tester.widget<MateoButton>(find.byKey(const ValueKey('post_publish_button'))).onPressed, isNull);
  });

  testWidgets('when entering a description, it should preserve the text in post state', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostView)));

    await tester.enterText(find.byKey(const ValueKey('post_description_input')), '  Preciso de uma pessoa  ');
    await tester.pumpAndSettle();

    expect(container.read(postStateProvider).descriptionText, '  Preciso de uma pessoa  ');
  });

  testWidgets('when editing lines changes the input height, it should preserve the active text input', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n, disableAnimations: false);
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    final elevenLines = List.generate(11, (index) => 'Linha ${index + 1} do trampo').join('\n');
    final tenLines = List.generate(10, (index) => 'Linha ${index + 1} do trampo').join('\n');
    final continuedDescription = '$tenLines\nNova linha';
    await tester.enterText(descriptionInput, elevenLines);
    await tester.pumpAndSettle();
    final initialEditableState = tester.state<EditableTextState>(find.byType(EditableText));

    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: tenLines,
        selection: TextSelection.collapsed(offset: tenLines.length),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final contractedEditableState = tester.state<EditableTextState>(find.byType(EditableText));
    final keptTextInputClient = tester.testTextInput.hasAnyClients;

    if (keptTextInputClient) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: continuedDescription,
          selection: TextSelection.collapsed(offset: continuedDescription.length),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    final continuedEditableState = tester.state<EditableTextState>(find.byType(EditableText));

    expect(
      (
        keptEditableDuringContraction: identical(contractedEditableState, initialEditableState),
        keptEditableForNextLine: identical(continuedEditableState, initialEditableState),
        keptFocus: continuedEditableState.widget.focusNode.hasFocus,
        keptTextInputClient: keptTextInputClient && tester.testTextInput.hasAnyClients,
        acceptedNextLine: tester.widget<TextField>(descriptionInput).controller!.text == continuedDescription,
      ),
      (
        keptEditableDuringContraction: true,
        keptEditableForNextLine: true,
        keptFocus: true,
        keptTextInputClient: true,
        acceptedNextLine: true,
      ),
    );
  });

  testWidgets('when tapping the blank area above the detail chips, it should focus the description input', (
    tester,
  ) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('post_description_focus_area')));
    await tester.pump();

    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });

  testWidgets('when entering multiple lines, it should grow the description input', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    final initialHeight = tester.getSize(find.byKey(const ValueKey('post_description_input'))).height;

    await tester.enterText(
      find.byKey(const ValueKey('post_description_input')),
      List.generate(20, (index) => 'Linha ${index + 1} do trampo').join('\n'),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('post_description_input'))).height, greaterThan(initialHeight));
  });

  testWidgets('when a new line fits without outer scrolling, it should keep existing text fixed', (tester) async {
    await PostViewTestHelpers.pump(
      tester,
      i18n: i18n,
      disableAnimations: false,
      size: const Size(360, 800),
      devicePixelRatio: 3,
    );
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    const initialDescription = 'Primeira linha\nSegunda linha\nTerceira linha';
    await tester.enterText(descriptionInput, initialDescription);
    await tester.pumpAndSettle();
    final outerScrollPosition = Scrollable.of(tester.element(descriptionInput)).position;
    final initialOuterScrollOffset = outerScrollPosition.pixels;
    var renderEditable = tester.allRenderObjects.whereType<RenderEditable>().single;
    final initialFirstGlyphTop = renderEditable
        .localToGlobal(
          renderEditable
              .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
              .single
              .toRect()
              .topLeft,
        )
        .dy;

    await tester.enterText(descriptionInput, '$initialDescription\n');
    await tester.pump();
    renderEditable = tester.allRenderObjects.whereType<RenderEditable>().single;
    final firstChangedFrameGlyphTop = renderEditable
        .localToGlobal(
          renderEditable
              .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
              .single
              .toRect()
              .topLeft,
        )
        .dy;
    await tester.pump(const Duration(milliseconds: 50));
    renderEditable = tester.allRenderObjects.whereType<RenderEditable>().single;
    final animatedGlyphTop = renderEditable
        .localToGlobal(
          renderEditable
              .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
              .single
              .toRect()
              .topLeft,
        )
        .dy;

    expect(
      (
        outerScrollOffset: outerScrollPosition.pixels,
        firstChangedFrameGlyphTop: firstChangedFrameGlyphTop,
        animatedGlyphTop: animatedGlyphTop,
      ),
      (
        outerScrollOffset: initialOuterScrollOffset,
        firstChangedFrameGlyphTop: initialFirstGlyphTop,
        animatedGlyphTop: initialFirstGlyphTop,
      ),
    );
  });

  testWidgets('when a new line needs outer scrolling, it should move the composition smoothly', (tester) async {
    await PostViewTestHelpers.pump(
      tester,
      i18n: i18n,
      disableAnimations: false,
      size: const Size(360, 800),
      devicePixelRatio: 3,
    );
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    final initialDescription = List.generate(24, (index) => 'Linha ${index + 1} do trampo').join('\n');
    await tester.enterText(descriptionInput, initialDescription);
    await tester.pumpAndSettle();
    final outerScrollPosition = Scrollable.of(tester.element(descriptionInput)).position;
    final initialOuterScrollOffset = outerScrollPosition.pixels;

    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '$initialDescription\n',
        selection: TextSelection.collapsed(offset: initialDescription.length + 1),
      ),
    );
    await tester.pump();
    final firstChangedFrameOuterScrollOffset = outerScrollPosition.pixels;
    final animatedOuterScrollOffsets = <double>[];
    final innerScrollOffsets = <double>[];
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      animatedOuterScrollOffsets.add(outerScrollPosition.pixels);
      innerScrollOffsets.add(tester.allRenderObjects.whereType<RenderEditable>().single.offset.pixels);
    }
    await tester.pumpAndSettle();
    final settledOuterScrollOffset = outerScrollPosition.pixels;
    innerScrollOffsets.add(tester.allRenderObjects.whereType<RenderEditable>().single.offset.pixels);
    final outerScrollOffsets = <double>[
      initialOuterScrollOffset,
      ...animatedOuterScrollOffsets,
      settledOuterScrollOffset,
    ];

    expect(
      (
        noFirstFrameJump: firstChangedFrameOuterScrollOffset == initialOuterScrollOffset,
        moves: settledOuterScrollOffset > initialOuterScrollOffset,
        hasIntermediatePositions:
            animatedOuterScrollOffsets
                .where((offset) => offset > initialOuterScrollOffset && offset < settledOuterScrollOffset)
                .toSet()
                .length >=
            2,
        movesForwardContinuously: outerScrollOffsets.indexed
            .skip(1)
            .every((entry) => entry.$2 >= outerScrollOffsets[entry.$1 - 1]),
        keepsInnerEditableFixed: innerScrollOffsets.every((offset) => offset == 0),
      ),
      (
        noFirstFrameJump: true,
        moves: true,
        hasIntermediatePositions: true,
        movesForwardContinuously: true,
        keepsInnerEditableFixed: true,
      ),
    );
  });

  testWidgets('when returning from a detail view, it should preserve the user selected scroll position', (
    tester,
  ) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n, size: const Size(360, 800), devicePixelRatio: 3);
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    await tester.enterText(descriptionInput, List.generate(24, (index) => 'Linha ${index + 1} do trampo').join('\n'));
    await tester.pumpAndSettle();
    final outerScrollPosition = Scrollable.of(tester.element(descriptionInput)).position;
    outerScrollPosition.jumpTo(outerScrollPosition.maxScrollExtent);
    await tester.pump();
    final paymentChip = find.byKey(const ValueKey('post_payment_chip'));
    final scrollOffsetBeforeNavigation = outerScrollPosition.pixels;
    final chipTopBeforeNavigation = tester.getTopLeft(paymentChip).dy;

    await tester.tap(paymentChip);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post_payment_close_button')));
    await tester.pumpAndSettle();

    expect(
      (scrollOffset: outerScrollPosition.pixels, chipTop: tester.getTopLeft(paymentChip).dy),
      (scrollOffset: scrollOffsetBeforeNavigation, chipTop: chipTopBeforeNavigation),
    );
  });

  testWidgets('when text wraps beside the caret, it should keep the inner editable at its natural height', (
    tester,
  ) async {
    const description = 'sbbdbd dndnsnsnsnsnndndbdnsnsnsnsns nnsnsbsnsb';
    await PostViewTestHelpers.pump(tester, i18n: i18n, disableAnimations: false);

    await tester.enterText(find.byKey(const ValueKey('post_description_input')), description);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final renderEditable = tester.allRenderObjects.whereType<RenderEditable>().single;
    final animatedMaxScrollExtent = renderEditable.maxScrollExtent;
    final animatedScrollOffset = renderEditable.offset.pixels;
    await tester.pumpAndSettle();
    final settledCaretRect = renderEditable.getLocalRectForCaret(renderEditable.selection!.extent);
    final settledDescriptionHeight = tester.getSize(find.byKey(const ValueKey('post_description_layout'))).height;

    expect(
      (
        animatedScrollExtent: animatedMaxScrollExtent,
        animatedScrollOffset: animatedScrollOffset,
        settledCaretIsVisible: settledCaretRect.top >= 0 && settledCaretRect.bottom <= settledDescriptionHeight,
        settledScrollExtent: renderEditable.maxScrollExtent,
        settledScrollOffset: renderEditable.offset.pixels,
      ),
      (
        animatedScrollExtent: 0,
        animatedScrollOffset: 0,
        settledCaretIsVisible: true,
        settledScrollExtent: 0,
        settledScrollOffset: 0,
      ),
    );
  });

  testWidgets('when multiline text settles, it should keep bottom glyphs inside the editable viewport', (tester) async {
    await PostViewTestHelpers.pump(
      tester,
      i18n: i18n,
      disableAnimations: false,
      size: const Size(360, 800),
      devicePixelRatio: 3,
    );
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    await tester.enterText(descriptionInput, List.generate(12, (index) => 'gypqj linha ${index + 1}').join('\n'));
    await tester.pumpAndSettle();

    await tester.enterText(
      descriptionInput,
      '${List.generate(10, (index) => 'gypqj linha ${index + 1}').join('\n')}\n',
    );
    await tester.pumpAndSettle();

    final renderEditable = tester.allRenderObjects.whereType<RenderEditable>().single;

    expect(
      (scrollExtent: renderEditable.maxScrollExtent, scrollOffset: renderEditable.offset.pixels),
      (scrollExtent: 0, scrollOffset: 0),
    );
  });

  testWidgets('when a new line consumes the remaining space, it should move the detail chips smoothly', (tester) async {
    await PostViewTestHelpers.pump(
      tester,
      i18n: i18n,
      disableAnimations: false,
      size: const Size(360, 800),
      devicePixelRatio: 3,
    );
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    final locationChip = find.byKey(const ValueKey('post_location_chip'));
    final initialDescription = List.generate(10, (index) => 'Linha ${index + 1} do trampo').join('\n');
    await tester.enterText(descriptionInput, initialDescription);
    await tester.pumpAndSettle();
    final outerScrollPosition = Scrollable.of(tester.element(descriptionInput)).position;
    final initialChipTopInContent = tester.getTopLeft(locationChip).dy + outerScrollPosition.pixels;

    await tester.enterText(descriptionInput, '$initialDescription\nNova linha do trampo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final animatedChipTopInContent = tester.getTopLeft(locationChip).dy + outerScrollPosition.pixels;
    final animatedChipGap =
        tester.getTopLeft(locationChip).dy -
        tester.getBottomLeft(find.byKey(const ValueKey('post_description_layout'))).dy;
    final renderEditable = tester.allRenderObjects.whereType<RenderEditable>().single;
    final animatedCaretRect = renderEditable.getLocalRectForCaret(renderEditable.selection!.extent);
    final animatedEditableHeight = renderEditable.size.height;
    await tester.pumpAndSettle();
    final settledChipTopInContent = tester.getTopLeft(locationChip).dy + outerScrollPosition.pixels;

    expect(
      (
        movesBetweenEndpoints:
            animatedChipTopInContent > initialChipTopInContent && animatedChipTopInContent < settledChipTopInContent,
        chipGap: animatedChipGap,
        caretIsVisible: animatedCaretRect.top >= 0 && animatedCaretRect.bottom <= animatedEditableHeight,
        settledScrollExtent: renderEditable.maxScrollExtent,
        settledScrollOffset: renderEditable.offset.pixels,
      ),
      (movesBetweenEndpoints: true, chipGap: 20, caretIsVisible: true, settledScrollExtent: 0, settledScrollOffset: 0),
    );
  });

  testWidgets('when text scaling changes the content sizes, it should preserve the 20 pixel chip spacing', (
    tester,
  ) async {
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    final locationChip = find.byKey(const ValueKey('post_location_chip'));
    await PostViewTestHelpers.pump(tester, i18n: i18n, textScaler: const TextScaler.linear(1.5));

    await tester.enterText(descriptionInput, List.generate(14, (index) => 'Linha ${index + 1} do trampo').join('\n'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(locationChip).dy - tester.getBottomLeft(descriptionInput).dy, 20);
  });

  testWidgets('when the description still has free space, it should keep the detail chips anchored', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n, disableAnimations: false);
    final locationChip = find.byKey(const ValueKey('post_location_chip'));
    final initialChipTop = tester.getTopLeft(locationChip).dy;

    await tester.enterText(find.byKey(const ValueKey('post_description_input')), 'Primeira linha\nSegunda linha');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.getTopLeft(locationChip).dy, initialChipTop);
  });

  testWidgets('when deleting a line, it should shrink smoothly without clipping or changing the chip gap', (
    tester,
  ) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n, disableAnimations: false);
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    final initialDescription = List.generate(11, (index) => 'Linha ${index + 1} do trampo').join('\n');
    await tester.enterText(descriptionInput, initialDescription);
    await tester.pumpAndSettle();
    final descriptionLayout = find.byKey(const ValueKey('post_description_layout'));
    final initialDescriptionHeight = tester.getSize(descriptionInput).height;

    await tester.enterText(descriptionInput, List.generate(10, (index) => 'Linha ${index + 1} do trampo').join('\n'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final animatedDescriptionHeight = tester.getSize(descriptionLayout).height;
    final animatedChipGap =
        tester.getTopLeft(find.byKey(const ValueKey('post_location_chip'))).dy -
        tester.getBottomLeft(descriptionLayout).dy;
    final animatedEditableScrollExtent = tester.allRenderObjects.whereType<RenderEditable>().single.maxScrollExtent;
    await tester.pumpAndSettle();
    final settledDescriptionHeight = tester.getSize(descriptionLayout).height;

    expect(
      (
        isBetweenEndpoints:
            animatedDescriptionHeight < initialDescriptionHeight &&
            animatedDescriptionHeight > settledDescriptionHeight,
        chipGap: animatedChipGap,
        editableScrollExtent: animatedEditableScrollExtent,
      ),
      (isBetweenEndpoints: true, chipGap: 20, editableScrollExtent: 0),
    );
  });

  testWidgets('when animations are disabled, deleting lines should immediately reduce the scroll extent', (
    tester,
  ) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    await tester.enterText(descriptionInput, List.generate(30, (index) => 'Linha ${index + 1} do trampo').join('\n'));
    await tester.pumpAndSettle();
    final scrollPosition = Scrollable.of(tester.element(descriptionInput)).position;
    final initialScrollExtent = scrollPosition.maxScrollExtent;

    await tester.enterText(descriptionInput, List.generate(10, (index) => 'Linha ${index + 1} do trampo').join('\n'));
    await tester.pumpAndSettle();

    expect(scrollPosition.maxScrollExtent, lessThan(initialScrollExtent));
  });

  testWidgets('when typing extends past the viewport, it should not force the outer scroll to the detail chips', (
    tester,
  ) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    final descriptionInput = find.byKey(const ValueKey('post_description_input'));
    final outerScrollPosition = Scrollable.of(tester.element(descriptionInput)).position;

    await tester.enterText(descriptionInput, List.generate(30, (index) => 'Linha ${index + 1} do trampo').join('\n'));
    await tester.pumpAndSettle();

    expect(outerScrollPosition.pixels, lessThan(outerScrollPosition.maxScrollExtent));
  });

  testWidgets('when scrolling backward after typing, it should move chips while the publish action stays fixed', (
    tester,
  ) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);
    await tester.enterText(
      find.byKey(const ValueKey('post_description_input')),
      List.generate(30, (index) => 'Linha ${index + 1} do trampo').join('\n'),
    );
    await tester.pumpAndSettle();
    final initialChipTop = tester.getTopLeft(find.byKey(const ValueKey('post_location_chip'))).dy;
    final initialPublishTop = tester.getTopLeft(find.byKey(const ValueKey('post_publish_button'))).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 250));
    await tester.pumpAndSettle();

    expect(
      (
        chipMovedDown: tester.getTopLeft(find.byKey(const ValueKey('post_location_chip'))).dy > initialChipTop,
        publishStayedFixed:
            tester.getTopLeft(find.byKey(const ValueKey('post_publish_button'))).dy == initialPublishTop,
      ),
      (chipMovedDown: true, publishStayedFixed: true),
    );
  });

  testWidgets('when long content reaches the top, it should travel behind the header', (tester) async {
    await PostViewTestHelpers.pump(tester, i18n: i18n);

    await tester.enterText(
      find.byKey(const ValueKey('post_description_input')),
      List.generate(30, (index) => 'Linha ${index + 1} do trampo').join('\n'),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('post_description_input'))).dy,
      lessThan(tester.getBottomLeft(find.byKey(const ValueKey('post_header'))).dy),
    );
  });

  testWidgets('when tapping the passive contact chip, it should leave post state unchanged', (tester) async {
    const initialPostData = PostData(descriptionText: 'Preciso de uma pessoa');
    await PostViewTestHelpers.pump(tester, i18n: i18n, initialPostData: initialPostData);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostView)));

    await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
    await tester.pumpAndSettle();

    expect(container.read(postStateProvider), initialPostData);
  });

  testWidgets('when the contact chip renders, it should expose one labeled button', (tester) async {
    final semantics = tester.ensureSemantics();
    await PostViewTestHelpers.pump(tester, i18n: i18n);

    final tap = find.ancestor(of: find.byKey(const ValueKey('post_contact_chip')), matching: find.byType(MateoTap));
    final data = tester.getSemantics(tap).getSemanticsData();
    final matchingLabels = find.bySemanticsLabel(i18n.post.contact.chipTitle).evaluate().length;
    semantics.dispose();

    expect((button: data.flagsCollection.isButton, matchingLabels: matchingLabels), (button: true, matchingLabels: 1));
  });

  testWidgets('when tapping close, it should leave the post composer', (tester) async {
    final goRouter = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
        $postRoute,
      ],
    );
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: goRouter,
        providerOverrides: PostViewTestHelpers.providerOverrides(i18n: i18n),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(const PostRoute().push<void>(goRouter.routerDelegate.navigatorKey.currentContext!));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('post_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PostView), findsNothing);
  });
}

abstract final class PostViewTestHelpers {
  static List<Override> providerOverrides({required Translations i18n, PostData initialPostData = const PostData()}) {
    return [
      translationProvider.overrideWithValue(i18n),
      postStateProvider.overrideWith(() => PostTestState(initialData: initialPostData)),
    ];
  }

  static Future<void> pump(
    WidgetTester tester, {
    required Translations i18n,
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
    TextScaler textScaler = TextScaler.noScaling,
    Size size = const Size(390, 844),
    double devicePixelRatio = 1,
  }) async {
    tester.view
      ..devicePixelRatio = devicePixelRatio
      ..physicalSize = size * devicePixelRatio;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          viewInsets: const EdgeInsets.only(bottom: 300),
          disableAnimations: disableAnimations,
          textScaler: textScaler,
        ),
        providerOverrides: providerOverrides(i18n: i18n, initialPostData: initialPostData),
        child: const PostView(),
      ),
    );
    await tester.pumpAndSettle();
  }
}
