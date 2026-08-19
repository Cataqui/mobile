import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/description/create_job_description_view.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'create_job_view_test_helpers.dart';
import 'payment/payment_icons_test_asset_bundle.dart';

void main() {
  late Translations i18n;
  late MockJobRepository jobRepository;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  setUp(() {
    jobRepository = MockJobRepository();
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
  });

  testWidgets('when the creation action is tapped, it should open the job description route', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.byType(CreateJobDescriptionView), findsOneWidget);
  });

  testWidgets('when the job creation route opens, it should host the description on the description route', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.byKey(const ValueKey('create_job_description_view')), findsOneWidget);
  });

  testWidgets('when the job creation route opens, it should use a normal scaffold', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.byKey(const ValueKey('create_job_scaffold')), findsOneWidget);
  });

  testWidgets('when the keyboard is visible, it should keep the description surface at ninety-two percent height', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, keyboardInset: 300);
    final surface = find.byKey(const ValueKey('create_job_description_surface'));
    final surfaceRect = tester.getRect(surface);

    expect(surfaceRect, rectMoreOrLessEquals(const Rect.fromLTRB(3, 67.52, 387, 844), epsilon: 0.001));
  });

  testWidgets('when the keyboard is visible, it should keep the continue action above the keyboard', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, keyboardInset: 300);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    final continueBottom = tester.getBottomRight(find.byKey(const ValueKey('create_job_continue_button'))).dy;

    expect(continueBottom, 516);
  });

  testWidgets('when the keyboard opens and closes, it should keep the continue action within the safe area', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      useViewMediaQuery: true,
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    final continueButton = find.byKey(const ValueKey('create_job_continue_button'));
    final beforeKeyboardOpens = tester.getBottomRight(continueButton).dy;
    addTearDown(tester.view.resetViewInsets);

    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    await tester.pump();
    final whileKeyboardOpens = tester.getBottomRight(continueButton).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    final afterKeyboardOpens = tester.getBottomRight(continueButton).dy;

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    final afterKeyboardCloses = tester.getBottomRight(continueButton).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    await tester.pump();
    final whileKeyboardReopens = tester.getBottomRight(continueButton).dy;

    expect(
      (whileKeyboardOpens, afterKeyboardOpens, afterKeyboardCloses, whileKeyboardReopens),
      (666, 516, beforeKeyboardOpens, 666),
    );
  });

  testWidgets(
    'when continuing while the keyboard is visible, it should mount payment at its keyboard-independent size',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        keyboardInset: 300,
        disableAnimations: false,
        jobRepository: jobRepository,
      );
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pump();
      await tester.pump();
      final paymentView = find.byKey(const ValueKey('create_job_payment_view'));
      final paymentSurface = find.descendant(
        of: paymentView,
        matching: find.byKey(const ValueKey('create_job_payment_surface')),
      );
      final paymentState = (
        paymentView.evaluate().length,
        tester.getSize(paymentSurface),
        MediaQuery.viewInsetsOf(tester.element(paymentSurface)).bottom,
      );
      await tester.pumpAndSettle();

      expect(paymentState, (1, const Size(390, 844), 0.0));
    },
  );

  testWidgets('when the job creation route opens, it should leave the previous route visible around the surface', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final route = ModalRoute.of(tester.element(find.byType(CreateJobDescriptionView)))!;

    expect(route.opaque, isFalse);
  });

  testWidgets('when the job creation route starts opening, it should slide the description upward from the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final transition = tester.widget<SlideTransition>(
      find.ancestor(of: find.byType(CreateJobDescriptionView), matching: find.byType(SlideTransition)).first,
    );

    expect(transition.position.value.dy, greaterThan(0));
  });

  testWidgets('when reduced motion is enabled, it should open the job creation route without a slide duration', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final route = ModalRoute.of(tester.element(find.byType(CreateJobDescriptionView)))!;

    expect(route.transitionDuration, Duration.zero);
  });

  testWidgets('when the description view opens, it should leave three pixels beside the writing surface', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final surface = find.byKey(const ValueKey('create_job_description_surface'));

    expect((tester.getTopLeft(surface).dx, tester.getTopRight(surface).dx), (3, 387));
  });

  testWidgets('when the top fade reaches the surface edge, it should remain inside the rounded surface', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final surface = tester.widget<Container>(find.byKey(const ValueKey('create_job_description_surface')));

    expect(surface.clipBehavior, Clip.antiAlias);
  });

  testWidgets('when the description surface opens, it should describe the continue action', (tester) async {
    final semantics = tester.ensureSemantics();
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), 'Preciso de ajuda');
    await tester.pumpAndSettle();

    try {
      expect(find.bySemanticsLabel(i18n.createJob.continueButtonSemanticLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when the description is empty, it should keep the continue action hidden', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.byKey(const ValueKey('create_job_continue_button')), findsNothing);
  });

  testWidgets('when the description contains only whitespace, it should keep the continue action hidden', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), '   \n  ');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_continue_button')), findsNothing);
  });

  testWidgets('when meaningful description text is entered, it should reveal a tappable continue action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), 'Curto');
    await tester.pumpAndSettle();

    try {
      expect(find.bySemanticsLabel(i18n.createJob.continueButtonSemanticLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when description text is entered, it should store the exact text in create-job state', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), '  Preciso de ajuda  ');
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobDescriptionView)));

    expect(container.read(createJobStateProvider).descriptionText, '  Preciso de ajuda  ');
  });

  testWidgets('when the description view mounts with saved create-job data, it should restore the description text', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyCode: 'BRL', descriptionText: 'Descrição já preenchida'),
    );
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, 'Descrição já preenchida');
  });

  testWidgets('when a 9-character description is continued, it should show the translated error toast', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(9, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(i18n.createJob.description.tooShortError), findsOneWidget);
  });

  testWidgets(
    'when surrounding whitespace pushes a 9-character description past the limit, it should remain too short',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(tester);
      await tester.enterText(find.byType(TextField), '  ${List<String>.filled(9, 'a').join()}  ');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(i18n.createJob.description.tooShortError), findsOneWidget);
    },
  );

  testWidgets('when a 10-character description is continued, it should open the payment view', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_payment_view')), findsOneWidget);
  });

  testWidgets('when draft creation succeeds, it should dismiss the keyboard before showing payment', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    final immediatelyAfterSuccess = (
      tester.testTextInput.isVisible,
      find.byKey(const ValueKey('create_job_payment_view')).evaluate().length,
    );
    await tester.pumpAndSettle();

    expect(immediatelyAfterSuccess, (false, 1));
  });

  testWidgets(
    'when continuing again after returning from payment, it should dismiss the restored keyboard before showing payment',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pump();
      final immediatelyAfterSecondSuccess = (
        tester.testTextInput.isVisible,
        find.byKey(const ValueKey('create_job_payment_view')).evaluate().length,
      );
      await tester.pumpAndSettle();

      expect(immediatelyAfterSecondSuccess, (false, 1));
    },
  );

  testWidgets('when returning from payment, it should reopen the description keyboard as the pop starts', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    await tester.pump();
    final keyboardVisibleAsPopStarts = tester.testTextInput.isVisible;
    await tester.pumpAndSettle();

    expect(keyboardVisibleAsPopStarts, isTrue);
  });

  testWidgets(
    'when returning from payment before keyboard insets arrive, it should keep the continue action above the keyboard',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        disableAnimations: false,
        useViewMediaQuery: true,
        jobRepository: jobRepository,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
      await tester.pump();
      final continueBottomBeforeKeyboardInsetsArrive = tester
          .getBottomRight(find.byKey(const ValueKey('create_job_continue_button')))
          .dy;
      await tester.pumpAndSettle();

      expect(continueBottomBeforeKeyboardInsetsArrive, 516);
    },
  );

  testWidgets('when returning to a long description, it should keep one live description scroll position', (
    tester,
  ) async {
    final longDescription = List<String>.filled(100, _CreateJobDescriptionViewTestData.validDescription).join('\n');
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), longDescription);
    await tester.pumpAndSettle();
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('create_job_prompt_scroll_view')),
    );
    scrollView.controller!.jumpTo(600);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    final attachedPositionCounts = <int>[];
    for (final keyboardInset in [0.0, 50.0, 100.0, 150.0, 200.0, 250.0, 300.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
      await tester.pump(const Duration(milliseconds: 60));
      attachedPositionCounts.add(scrollView.controller!.positions.length);
    }
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    attachedPositionCounts.add(scrollView.controller!.positions.length);

    expect(attachedPositionCounts, everyElement(1));
  });

  testWidgets(
    'when continuing after the focused description scrolls, it should preserve that position for the return snapshot',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        keyboardInset: 300,
        disableAnimations: false,
        jobRepository: jobRepository,
      );
      await tester.enterText(
        find.byType(TextField),
        List<String>.filled(30, _CreateJobDescriptionViewTestData.validDescription).join('\n'),
      );
      await tester.pumpAndSettle();
      final scrollController = tester
          .widget<SingleChildScrollView>(find.byKey(const ValueKey('create_job_prompt_scroll_view')))
          .controller!;
      final capturedOffset = (scrollController..jumpTo(10)).offset;
      final focusNode = tester.widget<TextField>(find.byType(TextField)).focusNode!;
      void simulatePlatformUnfocusScroll() {
        if (!focusNode.hasFocus) scrollController.jumpTo(0);
      }

      focusNode.addListener(simulatePlatformUnfocusScroll);
      addTearDown(() => focusNode.removeListener(simulatePlatformUnfocusScroll));
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();

      expect(scrollController.offset, capturedOffset);
    },
  );

  testWidgets('when focus reveals a hidden caret, it should place the caret near the visible prompt center', (
    tester,
  ) async {
    final longDescription = List<String>.filled(100, _CreateJobDescriptionViewTestData.validDescription).join('\n');
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), longDescription);
    await tester.pumpAndSettle();
    final promptScrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('create_job_prompt_scroll_view')),
    );
    promptScrollView.controller!.jumpTo(600);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final renderEditableFinder = find.descendant(
      of: find.byType(EditableText),
      matching: find.byElementPredicate((element) => element.renderObject is RenderEditable),
    );
    final renderEditable = tester.renderObject<RenderEditable>(renderEditableFinder);
    final caretRect = renderEditable.getLocalRectForCaret(renderEditable.selection!.extent);
    final caretCenter = renderEditable.localToGlobal(caretRect.center).dy;
    final visiblePromptCenter =
        (tester.getBottomLeft(find.byKey(const ValueKey('create_job_top_edge_fade'))).dy +
            tester.getTopLeft(find.byKey(const ValueKey('create_job_bottom_edge_fade'))).dy) /
        2;

    expect((caretCenter - visiblePromptCenter).abs(), lessThanOrEqualTo(renderEditable.preferredLineHeight));
  });

  testWidgets('when payment advances to another page, it should not focus the hidden description', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final paymentContext = tester.element(find.byKey(const ValueKey('create_job_payment_view')));

    unawaited(
      Navigator.of(paymentContext).pushReplacement<void, void>(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SizedBox(key: ValueKey('create_job_page_after_payment')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final descriptionTextField = tester.widget<TextField>(find.byType(TextField, skipOffstage: false));

    expect(
      (
        find.byKey(const ValueKey('create_job_page_after_payment')).evaluate().length,
        descriptionTextField.focusNode?.hasFocus,
        tester.testTextInput.isVisible,
      ),
      (1, false, false),
    );
  });

  testWidgets('when a valid description is continued, it should not show the short-description error', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    expect(find.text(i18n.createJob.description.tooShortError), findsNothing);
  });

  testWidgets('when a 10000-character description is continued, it should create the draft', (tester) async {
    final description = List<String>.filled(10000, 'a').join();
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), description);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    verify(() => jobRepository.createDraft(description: description)).called(1);
  });

  testWidgets('when a 10001-character description is continued, it should show the translated length error', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10001, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(i18n.createJob.description.tooLongError(characterCount: 10001)), findsOneWidget);
  });

  testWidgets('when a 10001-character description is continued, it should not create a draft', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10001, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    verifyNever(() => jobRepository.createDraft(description: any(named: 'description')));
  });

  testWidgets('when draft creation remains pending, it should show the Mateo loader', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('mateo_floating_action_button_loading_indicator')), findsOneWidget);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending, it should disable description editing', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    final textInput = tester.widget<MateoTextInput>(find.byType(MateoTextInput));

    expect(textInput.editable, isFalse);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending and delete is pressed, it should preserve the description', (
    tester,
  ) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, _CreateJobDescriptionViewTestData.validDescription);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation finishes, it should show the payment amount', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    expect(find.bySemanticsLabel(r'R$ 0'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('when payment opens, it should show fixed payment as the selected option', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final selector = tester.widget<Semantics>(find.byKey(const Key('mateo_select_source_semantics')));

    expect(selector.properties.label, i18n.createJob.payment.typeSelector.fixed.title);
  });

  testWidgets('when payment opens with a saved range type, it should restore the range option', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.range),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final selector = tester.widget<Semantics>(find.byKey(const Key('mateo_select_source_semantics')));

    expect(selector.properties.label, i18n.createJob.payment.typeSelector.range.title);
  });

  testWidgets(
    'when range payment opens from the keyboard-shortened description surface, it should fit throughout the surface transition',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        keyboardInset: 300,
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.range),
        jobRepository: jobRepository,
      );
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      final transitionExceptions = <Object>[];
      for (var elapsedMilliseconds = 0; elapsedMilliseconds < 300; elapsedMilliseconds += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        final Object? exception = tester.takeException();
        if (exception != null) transitionExceptions.add(exception);
      }
      await tester.pumpAndSettle();

      expect(transitionExceptions, isEmpty);
    },
  );

  testWidgets('when opening the payment type selector, it should show every localized option in order', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_select_source')));
    await tester.pumpAndSettle();
    const paymentTypes = [JobPaymentType.fixed, JobPaymentType.range, JobPaymentType.flexible, JobPaymentType.other];
    final options = [
      for (final paymentType in paymentTypes)
        tester.widget<Semantics>(find.byKey(ValueKey<Object>(('mateo_select_option_semantics', paymentType)))),
    ];
    final optionTops = [
      for (final paymentType in paymentTypes)
        tester.getTopLeft(find.byKey(ValueKey<Object>(('mateo_select_option_semantics', paymentType)))).dy,
    ];

    expect(
      <Object>[
        for (final option in options) ...[option.properties.label!, option.properties.hint!],
        for (var index = 1; index < optionTops.length; index += 1) optionTops[index - 1] < optionTops[index],
      ],
      <Object>[
        i18n.createJob.payment.typeSelector.fixed.title,
        i18n.createJob.payment.typeSelector.fixed.description,
        i18n.createJob.payment.typeSelector.range.title,
        i18n.createJob.payment.typeSelector.range.description,
        i18n.createJob.payment.typeSelector.flexible.title,
        i18n.createJob.payment.typeSelector.flexible.description,
        i18n.createJob.payment.typeSelector.other.title,
        i18n.createJob.payment.typeSelector.other.description,
        true,
        true,
        true,
      ],
    );
  });

  testWidgets('when selecting range payment, it should save the type and show both localized amount fields', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentMinimumAmount: '350'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_select_source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<Object>(('mateo_select_option_semantics', JobPaymentType.range))));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));
    final semantics = tester.ensureSemantics();
    final minimum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_minimum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.minimumLabel),
      ),
    );
    final maximum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_maximum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.maximumLabel),
      ),
    );

    expect(
      (container.read(createJobStateProvider).paymentType, minimum.label, minimum.value, maximum.label, maximum.value),
      (JobPaymentType.range, 'de', r'R$ 350', 'até', r'R$ 0'),
    );
    semantics.dispose();
  });

  testWidgets('when range payment opens, it should select the minimum amount first', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.range),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    final minimum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_minimum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.minimumLabel),
      ),
    );
    final maximum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_maximum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.maximumLabel),
      ),
    );

    expect(
      (minimum.flagsCollection.isSelected.toBoolOrNull(), maximum.flagsCollection.isSelected.toBoolOrNull()),
      (true, false),
    );
    semantics.dispose();
  });

  testWidgets('when range payment opens, it should center the amount fields within the payment content', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(
        currencyCode: 'BRL',
        paymentMinimumAmount: '350',
        paymentMaximumAmount: '700',
        paymentType: JobPaymentType.range,
      ),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final paymentContentRect = tester.getRect(find.byKey(const ValueKey('create_job_range_payment_content')));
    final minimumLabelLeft = tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(
              const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_minimum_amount'))),
            ),
            matching: find.byType(Text),
          ),
        )
        .dx;
    final maximumLabelLeft = tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(
              const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
            ),
            matching: find.byType(Text),
          ),
        )
        .dx;

    expect(
      (minimumLabelLeft > paymentContentRect.left + 40, (minimumLabelLeft - maximumLabelLeft).abs() < 0.01),
      (true, true),
    );
  });

  testWidgets('when the maximum range amount is tapped, keypad input should update only the maximum draft amount', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(
        currencyCode: 'BRL',
        paymentMinimumAmount: '350',
        paymentType: JobPaymentType.range,
      ),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));
    final semantics = tester.ensureSemantics();
    final minimum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_minimum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.minimumLabel),
      ),
    );
    final maximum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_maximum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.maximumLabel),
      ),
    );

    expect(
      (
        container.read(createJobStateProvider).paymentMinimumAmount,
        container.read(createJobStateProvider).paymentMaximumAmount,
        minimum.flagsCollection.isSelected.toBoolOrNull(),
        maximum.flagsCollection.isSelected.toBoolOrNull(),
      ),
      ('350', '5', false, true),
    );
    semantics.dispose();
  });

  testWidgets('when blank space in the maximum range row is tapped, keypad input should update the maximum amount', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(
        currencyCode: 'BRL',
        paymentMinimumAmount: '3',
        paymentType: JobPaymentType.range,
      ),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final maximumAmountRow = find.byKey(
      const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
    );
    final maximumAmountCenter = tester.getCenter(maximumAmountRow);

    await tester.tapAt(
      Offset(tester.view.physicalSize.width / tester.view.devicePixelRatio - 30, maximumAmountCenter.dy),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));

    expect(
      (
        container.read(createJobStateProvider).paymentMinimumAmount,
        container.read(createJobStateProvider).paymentMaximumAmount,
      ),
      ('3', '5'),
    );
  });

  testWidgets('when the minimum range amount is tapped again, keypad input should return to the minimum amount', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(
        currencyCode: 'BRL',
        paymentMinimumAmount: '350',
        paymentMaximumAmount: '700',
        paymentType: JobPaymentType.range,
      ),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_minimum_amount'))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));

    expect(
      (
        container.read(createJobStateProvider).paymentMinimumAmount,
        container.read(createJobStateProvider).paymentMaximumAmount,
      ),
      ('3,505', '700'),
    );
  });

  testWidgets(
    'when a digit widens a range amount, it should keep the amount paint boundary stable while moving horizontally',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(
          currencyCode: 'BRL',
          paymentMinimumAmount: '999',
          paymentType: JobPaymentType.range,
        ),
        jobRepository: jobRepository,
      );
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();
      final minimumAmount = find.byKey(const ValueKey('create_job_range_minimum_amount'));
      final widthBeforeInput = tester.getSize(minimumAmount).width;

      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
      await tester.pump();
      final widthWhenMotionBegins = tester.getSize(minimumAmount).width;
      await tester.pumpAndSettle();
      final settledWidth = tester.getSize(minimumAmount).width;

      expect(
        ((widthWhenMotionBegins - widthBeforeInput).abs() < 0.01, (settledWidth - widthBeforeInput).abs() < 0.01),
        (true, true),
      );
    },
  );

  testWidgets('when deleting a range digit, it should keep a stable paint boundary while the digit leaves', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(
        currencyCode: 'BRL',
        paymentMinimumAmount: '555',
        paymentType: JobPaymentType.range,
      ),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final minimumAmount = find.byKey(const ValueKey('create_job_range_minimum_amount'));
    final widthBeforeDeletion = tester.getSize(minimumAmount).width;

    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    final widthWhenMotionBegins = tester.getSize(minimumAmount).width;
    await tester.pump(const Duration(milliseconds: 70));
    final widthWhileDigitLeaves = tester.getSize(minimumAmount).width;
    await tester.pumpAndSettle();
    final settledWidth = tester.getSize(minimumAmount).width;

    expect(
      (
        (widthWhenMotionBegins - widthBeforeDeletion).abs() < 0.01,
        (widthWhileDigitLeaves - widthBeforeDeletion).abs() < 0.01,
        (settledWidth - widthBeforeDeletion).abs() < 0.01,
      ),
      (true, true, true),
    );
  });

  testWidgets(
    'when fixed payment changes to range then the minimum receives another digit, it should keep both fields vertically stable',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(
          currencyCode: 'BRL',
          paymentMinimumAmount: '23',
          paymentType: JobPaymentType.fixed,
        ),
        jobRepository: jobRepository,
      );
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mateo_select_source')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<Object>(('mateo_select_option_semantics', JobPaymentType.range))));
      await tester.pumpAndSettle();
      final minimumAmount = find.byKey(const ValueKey('create_job_range_minimum_amount'));
      final maximumAmount = find.byKey(const ValueKey('create_job_range_maximum_amount'));
      final before = (tester.getTopLeft(minimumAmount).dy, tester.getTopLeft(maximumAmount).dy);

      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
      await tester.pump();
      final start = (tester.getTopLeft(minimumAmount).dy, tester.getTopLeft(maximumAmount).dy);
      await tester.pump(const Duration(milliseconds: 70));
      final middle = (tester.getTopLeft(minimumAmount).dy, tester.getTopLeft(maximumAmount).dy);
      await tester.pumpAndSettle();
      final settled = (tester.getTopLeft(minimumAmount).dy, tester.getTopLeft(maximumAmount).dy);

      expect(
        (
          (start.$1 - before.$1).abs() < 0.01,
          (start.$2 - before.$2).abs() < 0.01,
          (middle.$1 - before.$1).abs() < 0.01,
          (middle.$2 - before.$2).abs() < 0.01,
          (settled.$1 - before.$1).abs() < 0.01,
          (settled.$2 - before.$2).abs() < 0.01,
        ),
        (true, true, true, true, true, true),
      );
    },
  );

  testWidgets('when returning to range after another payment type, it should restore both entered amounts', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(
        currencyCode: 'BRL',
        paymentMinimumAmount: '350',
        paymentMaximumAmount: '700',
        paymentType: JobPaymentType.range,
      ),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_select_source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<Object>(('mateo_select_option_semantics', JobPaymentType.fixed))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_select_source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<Object>(('mateo_select_option_semantics', JobPaymentType.range))));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    final minimum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_minimum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.minimumLabel),
      ),
    );
    final maximum = tester.getSemantics(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_range_maximum_amount')),
        matching: find.bySemanticsLabel(i18n.createJob.payment.range.maximumLabel),
      ),
    );

    expect((minimum.value, maximum.value), (r'R$ 350', r'R$ 700'));
    semantics.dispose();
  });

  for (final paymentType in [JobPaymentType.flexible, JobPaymentType.other]) {
    testWidgets(
      'when selecting ${paymentType.name} payment, it should save the type and leave its unfinished content empty',
      (tester) async {
        await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
        await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_select_source')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey<Object>(('mateo_select_option_semantics', paymentType))));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));

        expect(
          (
            container.read(createJobStateProvider).paymentType,
            find.byKey(const ValueKey('create_job_fixed_payment_content')).evaluate().length,
            find.byKey(ValueKey<Object>(('create_job_empty_payment_content', paymentType))).evaluate().length,
          ),
          (paymentType, 0, 1),
        );
      },
    );
  }

  testWidgets('when selecting fixed payment, it should save the type and show the fixed payment controls', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.range),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_select_source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<Object>(('mateo_select_option_semantics', JobPaymentType.fixed))));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));

    expect(
      (
        container.read(createJobStateProvider).paymentType,
        find.byKey(const ValueKey('create_job_fixed_payment_content')).evaluate().length,
      ),
      (JobPaymentType.fixed, 1),
    );
  });

  testWidgets('when draft creation finishes, it should open payment for the created job', (tester) async {
    const jobId = 'created-draft-job-id';
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture().copyWith(jobId: jobId)));
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final paymentView = tester.widget<CreateJobPaymentView>(find.byType(CreateJobPaymentView));

    expect(paymentView.jobId, jobId);
  });

  testWidgets('when a payment digit is entered, it should store the amount in create-job state', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));

    expect(container.read(createJobStateProvider).paymentMinimumAmount, isNot('0'));
  });

  testWidgets('when a default zero is rapidly replaced then restored, it should retain only the restored zero', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));
    final semantics = tester.ensureSemantics();

    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_zero')));
    await tester.pumpAndSettle();

    try {
      expect(
        (container.read(createJobStateProvider).paymentMinimumAmount, find.bySemanticsLabel(r'R$ 0').evaluate().length),
        ('0', 1),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when the amount is cleared then a decimal separator is entered, it should restore the leading zero', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(CreateJobPaymentView)));
    final semantics = tester.ensureSemantics();

    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator')));
    await tester.pumpAndSettle();
    final separator = tester.widget<Text>(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator_label'))).data!;

    try {
      expect(
        (
          container.read(createJobStateProvider).paymentMinimumAmount,
          find.bySemanticsLabel('R\$ 0$separator').evaluate().length,
        ),
        ('0$separator', 1),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when draft creation finishes, it should expand the payment surface to the full screen', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('create_job_payment_surface'));

    expect(tester.getSize(surface), const Size(390, 844));
  });

  testWidgets('when moving to payment, it should keep ordinary forms out of the moving surface', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final overlay = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphOverlay');
    int movingCount(Type type) => find
        .descendant(of: overlay, matching: find.byWidgetPredicate((widget) => widget.runtimeType == type))
        .evaluate()
        .length;
    final departingCounts = (movingCount(MateoTextInput), movingCount(MateoNumericKeypad));

    await tester.pump(const Duration(milliseconds: 90));
    final arrivingCounts = (movingCount(MateoTextInput), movingCount(MateoNumericKeypad));

    expect((departingCounts, arrivingCounts), ((0, 0), (0, 0)));
  });

  testWidgets('when moving to payment, it should fade the snapshot surface content out and in', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final overlay = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphOverlay');
    List<double> transitionOpacities() {
      return find
          .descendant(of: overlay, matching: find.byType(FadeTransition))
          .evaluate()
          .map((element) => element.widget as FadeTransition)
          .map((transition) => transition.opacity.value)
          .where((opacity) => opacity > 0 && opacity < 1)
          .toList();
    }

    final departingOpacities = transitionOpacities();
    await tester.pump(const Duration(milliseconds: 90));
    final arrivingOpacities = transitionOpacities();

    expect((departingOpacities.isNotEmpty, arrivingOpacities.isNotEmpty), (true, true));
  });

  testWidgets('when moving to payment, it should keep both views mounted until the surface transition settles', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    await tester.pump();
    final mountedDuringHandoff = (
      find.byKey(const ValueKey('create_job_description_view')).evaluate().length,
      find.byKey(const ValueKey('create_job_payment_view')).evaluate().length,
    );
    await tester.pumpAndSettle();

    expect(mountedDuringHandoff, (1, 1));
  });

  testWidgets('when the payment back action is tapped, it should return to the saved description', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    await tester.pumpAndSettle();
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, _CreateJobDescriptionViewTestData.validDescription);
  });

  testWidgets(
    'when returning while keyboard insets appear, it should keep the snapshot surface aimed at the description',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final descriptionSurface = find.byKey(const ValueKey('create_job_description_surface'));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final endpointTop = tester.getTopLeft(descriptionSurface).dy;
      final flightBoundaries = find
          .byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphFlightBoundary')
          .evaluate()
          .map((element) => element.renderObject! as RenderBox);
      final surfaceBoundary = flightBoundaries.reduce((largest, candidate) {
        return largest.size.longestSide >= candidate.size.longestSide ? largest : candidate;
      });
      final flightTop = surfaceBoundary.localToGlobal(Offset.zero).dy;
      await tester.pumpAndSettle();

      expect(flightTop, greaterThan(endpointTop * 0.7));
    },
  );

  testWidgets('when Android back is pressed from payment, it should return to the saved description', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, _CreateJobDescriptionViewTestData.validDescription);
  });

  testWidgets('when payment returns after expanding, it should settle with one visible continue action', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_continue_button')), findsOneWidget);
  });

  testWidgets('when draft creation remains pending, it should keep the keyboard visible', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.testTextInput.isVisible, isTrue);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending and continue is tapped again, it should submit only once', (
    tester,
  ) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();

    verify(() => jobRepository.createDraft(description: _CreateJobDescriptionViewTestData.validDescription)).called(1);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending and Android back is pressed, it should close the modal', (
    tester,
  ) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CreateJobDescriptionView), findsNothing);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending and the close button is tapped, it should close the modal', (
    tester,
  ) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('create_job_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateJobDescriptionView), findsNothing);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pump();
  });

  testWidgets('when returning after draft creation succeeds, it should restore the continue icon', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_continue_icon')), findsOneWidget);
  });

  testWidgets(
    'when draft creation succeeds while payment icons are decoding, it should keep the payment view closed until they are ready',
    (tester) async {
      final assetBundle = PaymentIconsTestAssetBundle();
      addTearDown(assetBundle.release);
      await CreateJobViewTestHelpers.pumpDescription(
        tester,
        assetBundle: assetBundle,
        shouldPrecachePaymentIcons: false,
        jobRepository: jobRepository,
      );
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CreateJobPaymentView), findsNothing);

      assetBundle.release();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('when draft creation fails, it should show the translated request error', (tester) async {
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenThrow(Exception('request failed'));
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(i18n.createJob.createDraftError), findsOneWidget);
  });

  testWidgets('when draft creation fails, it should preserve the entered description', (tester) async {
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenThrow(Exception('request failed'));
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, _CreateJobDescriptionViewTestData.validDescription);
  });

  testWidgets('when all meaningful description text is removed, it should hide the continue action', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), 'Preciso de ajuda');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_continue_button')), findsNothing);
  });

  testWidgets('when animations are enabled and typing starts, it should pop the continue action into view', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false);

    await tester.enterText(find.byType(TextField), 'Preciso');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final scaleTransition = tester.widget<ScaleTransition>(
      find.byKey(const ValueKey('create_job_continue_show_scale')),
    );

    expect(scaleTransition.scale.value, isNot(1));
  });

  testWidgets('when the description surface opens, it should show what the person needs as its title', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.text(i18n.createJob.description.title), findsOneWidget);
  });

  testWidgets('when the description view opens, it should show the localized writing prompt', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.text(i18n.createJob.description.placeholder), findsOneWidget);
  });

  testWidgets('when the description surface opens, it should not show the removed help action', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(find.byKey(const ValueKey('create_job_help_button')), findsNothing);
  });

  testWidgets('when the description surface opens, it should align the title with the close button', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final titleCenter = tester.getCenter(find.byKey(const ValueKey('create_job_title'))).dy;
    final closeButtonCenter = tester.getCenter(find.byKey(const Key('create_job_close_button'))).dy;

    expect(titleCenter, closeButtonCenter);
  });

  testWidgets('when the description surface opens, it should center the title horizontally', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(tester.getCenter(find.byKey(const ValueKey('create_job_title'))).dx, 195);
  });

  testWidgets('when the description surface opens, it should place the close button on the left', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);

    expect(tester.getCenter(find.byKey(const Key('create_job_close_button'))).dx, 45);
  });

  testWidgets('when the description surface opens, it should soften the top content boundary', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final topEdgeFade = tester.widget<MateoEdgeFade>(find.byKey(const ValueKey('create_job_top_edge_fade')));

    expect(topEdgeFade.style.mainAxisExtent, CreateJobDescriptionView.topEdgeFadeHeight);
  });

  testWidgets('when the description surface opens, it should start the top fade at the surface edge', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final surfaceTop = tester.getTopLeft(find.byKey(const ValueKey('create_job_description_surface'))).dy;
    final topEdgeFadeTop = tester.getTopLeft(find.byKey(const ValueKey('create_job_top_edge_fade'))).dy;

    expect(topEdgeFadeTop, surfaceTop);
  });

  testWidgets('when the description surface opens, it should keep the title background transparent', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final title = tester.widget<Text>(find.byKey(const ValueKey('create_job_title')));

    expect(title.style?.backgroundColor, isNull);
  });

  testWidgets('when the description is scrollable, it should let the scroll viewport reach the surface edges', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final surface = find.byKey(const ValueKey('create_job_description_surface'));
    final promptScrollView = find.byKey(const ValueKey('create_job_prompt_scroll_view'));

    expect(
      (tester.getTopLeft(promptScrollView).dy, tester.getBottomLeft(promptScrollView).dy),
      (tester.getTopLeft(surface).dy, tester.getBottomLeft(surface).dy),
    );
  });

  testWidgets('when a long description scrolls beneath the heading, it should keep the heading visible', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(30, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('create_job_prompt_scroll_view')), const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_title_scroll_opacity')), findsNothing);
  });

  testWidgets('when a scrolled description is cleared, it should return the editor to the start', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(30, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();
    final scrollController =
        tester.widget<SingleChildScrollView>(find.byKey(const ValueKey('create_job_prompt_scroll_view'))).controller!
          ..jumpTo(100);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0);
  });

  testWidgets('when the description surface opens, it should place the editor lower below the header', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final promptContent = tester.widget<Padding>(find.byKey(const ValueKey('create_job_description_view_content')));

    expect(promptContent.padding.resolve(TextDirection.ltr).top, 91);
  });

  testWidgets('when the description surface opens, it should pad the content above the bottom fade', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final bottomEdgeFadeFinder = find.byKey(const ValueKey('create_job_bottom_edge_fade'));
    final bottomEdgeFade = tester.widget<MateoEdgeFade>(bottomEdgeFadeFinder);
    final bottomEdgeFadeHeight = bottomEdgeFade.style
        .resolve(tester.element(bottomEdgeFadeFinder), position: MateoEdgeFadePosition.bottom)
        .mainAxisExtent!;
    final promptContent = tester.widget<Padding>(find.byKey(const ValueKey('create_job_description_view_content')));

    expect(
      promptContent.padding.resolve(TextDirection.ltr).bottom,
      greaterThanOrEqualTo(bottomEdgeFadeHeight + CreateJobDescriptionView.surfaceContentPadding),
    );
  });

  testWidgets('when typing the final prompt line, it should keep the caret above the bottom fade', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(20, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();
    final renderEditableFinder = find.descendant(
      of: find.byType(EditableText),
      matching: find.byElementPredicate((element) => element.renderObject is RenderEditable),
    );
    final renderEditable = tester.renderObject<RenderEditable>(renderEditableFinder);
    final caretRect = renderEditable.getLocalRectForCaret(renderEditable.selection!.extent);
    final caretBottom = renderEditable.localToGlobal(caretRect.bottomLeft).dy;
    final bottomEdgeFadeTop = tester.getTopLeft(find.byKey(const ValueKey('create_job_bottom_edge_fade'))).dy;

    expect(caretBottom, lessThanOrEqualTo(bottomEdgeFadeTop));
  });

  testWidgets('when the prompt grows across many lines, it should keep the description surface within its bounds', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(20, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('when the backdrop is tapped, it should keep the protected job creation route open', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byType(CreateJobDescriptionView), findsOneWidget);
  });

  testWidgets('when the close button is tapped, it should close the job creation route', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.tap(find.byKey(const Key('create_job_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateJobDescriptionView), findsNothing);
  });
}

abstract final class _CreateJobDescriptionViewTestData {
  static const validDescription = 'Preciso de uma pessoa para descarregar caixas.';
}
