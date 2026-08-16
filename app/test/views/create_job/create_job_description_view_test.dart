import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
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
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import 'create_job_view_test_helpers.dart';

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

  testWidgets('when the keyboard is visible, it should keep the description surface above the keyboard', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, keyboardInset: 300);
    final surfaceBottom = tester.getBottomRight(find.byKey(const ValueKey('create_job_description_surface'))).dy;

    expect(surfaceBottom, lessThanOrEqualTo(532));
  });

  testWidgets('when the keyboard is visible, it should keep the continue action above the keyboard', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, keyboardInset: 300);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    final continueBottom = tester.getBottomRight(find.byKey(const ValueKey('create_job_continue_button'))).dy;

    expect(continueBottom, lessThanOrEqualTo(544));
  });

  testWidgets('when the keyboard first opens then closes, it should move the continue action only upward', (
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
      (
        whileKeyboardOpens < beforeKeyboardOpens,
        afterKeyboardOpens < whileKeyboardOpens,
        afterKeyboardCloses,
        whileKeyboardReopens,
      ),
      (true, true, afterKeyboardOpens, afterKeyboardOpens),
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

  testWidgets('when the description view opens, it should inset the writing surface on both sides', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    final surface = find.byKey(const ValueKey('create_job_description_surface'));

    expect((tester.getTopLeft(surface).dx, tester.getTopRight(surface).dx), (12, 378));
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
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', descriptionText: 'Descrição já preenchida'),
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
    final visibleAmount = tester
        .widgetList<Text>(
          find.descendant(of: find.byKey(const ValueKey('create_job_payment_amount')), matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .join();

    expect(visibleAmount, r'R$ 0');
  });

  testWidgets('when payment opens with a US dollar hint, it should show the localized US dollar symbol', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyHint: 'USD', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final amount = tester.widget<Semantics>(find.byKey(const ValueKey('create_job_payment_amount')));

    expect(amount.properties.label, r'$ 1,200');
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

    expect(container.read(createJobStateProvider).paymentAmount, isNot('0'));
  });

  testWidgets(
    'when entering the first non-zero payment digit, it should replace the displayed default zero immediately',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
      await tester.pumpAndSettle();
      final amount = tester.widget<Semantics>(find.byKey(const ValueKey('create_job_payment_amount')));

      expect(amount.properties.label, r'R$ 5');
    },
  );

  testWidgets(
    'when entering the first non-zero payment digit, it should move the default zero right before moving the entered digit in',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_five')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      final replacement = find.byKey(const ValueKey('create_job_payment_replaced_digit_animation'));
      final motions = find
          .descendant(of: replacement, matching: find.byType(Motion))
          .evaluate()
          .map((element) => element.widget as Motion)
          .map((motion) => motion.effect! as MoveMotionEffect)
          .toList();
      await tester.pumpAndSettle();

      expect(motions.map((motion) => (motion.begin, motion.end, motion.delay)).toList(), [
        (Offset.zero, const Offset(56, 0), Duration.zero),
        (const Offset(56, 0), Offset.zero, const Duration(milliseconds: 140)),
      ]);
    },
  );

  testWidgets('when a payment digit is entered, it should slide only the new digit inward from the right', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final animation = find.byKey(const ValueKey('create_job_payment_new_digit_animation'));
    final newDigit = find.descendant(of: animation, matching: find.text('1'));
    final digitMotion = tester.widget<Motion>(find.descendant(of: animation, matching: find.byType(Motion)));
    final stationaryAmount = find.descendant(
      of: find.byKey(const ValueKey('create_job_payment_amount')),
      matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.startsWith(r'R$') ?? false)),
    );

    expect(
      (
        find.descendant(of: animation, matching: find.byType(Motion)).evaluate().length,
        (digitMotion.effect! as MoveMotionEffect).begin,
        find.descendant(of: animation, matching: find.byType(MateoEdgeFade)).evaluate().length,
        tester.getTopLeft(newDigit).dx > tester.getTopRight(stationaryAmount).dx,
      ),
      (1, const Offset(56, 0), 1, true),
    );
  });

  testWidgets('when a payment digit is entered, it should animate the existing amount toward its new center', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final centeringMotion = find.byKey(const ValueKey(('create_job_payment_amount_centering', 1)));
    final stationaryAmount = find.descendant(
      of: centeringMotion,
      matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.startsWith(r'R$') ?? false)),
    );
    final midpointLeft = tester.getTopLeft(stationaryAmount).dx;
    await tester.pumpAndSettle();

    expect(midpointLeft, greaterThan(tester.getTopLeft(stationaryAmount).dx));
  });

  testWidgets('when a grouping separator appears, it should open a gap between the surrounding digits', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final separator = find.byKey(const ValueKey('create_job_payment_new_separator_animation'));
    final separatorVisibility = tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: separator,
        matching: find.byWidgetPredicate((widget) => widget is TweenAnimationBuilder<double>),
      ),
    );
    final rightGroupMotion = tester.widget<Motion>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_separator_right_group_animation')),
        matching: find.byType(Motion),
      ),
    );

    expect(
      (
        separator.evaluate().length,
        separatorVisibility.tween.begin,
        separatorVisibility.tween.end,
        separatorVisibility.curve,
        rightGroupMotion.effect is MoveMotionEffect,
        (rightGroupMotion.effect! as MoveMotionEffect).begin.dx < 0,
      ),
      (1, 0, 1, Curves.easeOutCubic, true, true),
    );
  });

  testWidgets('when a grouping separator disappears, it should close the gap between the surrounding digits', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final separator = find.byKey(const ValueKey('create_job_payment_removed_separator_animation'));
    final separatorVisibility = tester.widget<TweenAnimationBuilder<double>>(separator);
    final rightGroupMotion = tester.widget<Motion>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_removed_separator_right_group_animation')),
        matching: find.byType(Motion),
      ),
    );

    expect(
      (
        separator.evaluate().length,
        separatorVisibility.tween.begin,
        separatorVisibility.tween.end,
        separatorVisibility.curve,
        rightGroupMotion.effect is MoveMotionEffect,
        (rightGroupMotion.effect! as MoveMotionEffect).begin.dx > 0,
      ),
      (1, 1, 0, Curves.easeInCubic, true, true),
    );
  });

  testWidgets('when a grouping separator moves right, it should close its old gap and open its new gap', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final crossedGroupMotion = tester.widget<Motion>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_moved_separator_crossed_group_animation')),
        matching: find.byType(Motion),
      ),
    );
    final rightGroupMotion = tester.widget<Motion>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_moved_separator_right_group_animation')),
        matching: find.byType(Motion),
      ),
    );

    expect(
      (
        find.byKey(const ValueKey('create_job_payment_moved_separator_new_position')).evaluate().length,
        (crossedGroupMotion.effect! as MoveMotionEffect).begin.dx > 0,
        (rightGroupMotion.effect! as MoveMotionEffect).begin.dx < 0,
      ),
      (1, true, true),
    );
  });

  testWidgets('when a grouping separator moves left, it should open its new gap and close its old gap', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final crossedGroupMotion = tester.widget<Motion>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_moved_separator_crossed_group_animation')),
        matching: find.byType(Motion),
      ),
    );

    expect((crossedGroupMotion.effect! as MoveMotionEffect).begin.dx, lessThan(0));
  });

  testWidgets('when another grouping separator appears, it should animate every affected separator smoothly', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index += 1) {
      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_zero')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_zero')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    expect(
      (
        find.byKey(const ValueKey('create_job_payment_multi_separator_new_animation')).evaluate().length,
        find.byKey(const ValueKey('create_job_payment_multi_separator_existing_animation')).evaluate().length,
      ),
      (1, 1),
    );
  });

  testWidgets('when one of multiple grouping separators disappears, it should animate every affected separator', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 3; index += 1) {
      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_zero')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    expect(
      (
        find.byKey(const ValueKey('create_job_payment_multi_separator_removed_animation')).evaluate().length,
        find.byKey(const ValueKey('create_job_payment_multi_separator_existing_animation')).evaluate().length,
      ),
      (1, 1),
    );
  });

  testWidgets('when a decimal separator is added beside a grouping separator, it should animate each one in place', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final decimalSeparator = tester
        .widget<Text>(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator_label')))
        .data;
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final newSeparator = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_multi_separator_new_animation')),
        matching: find.byType(Text),
      ),
    );
    final existingSeparator = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('create_job_payment_multi_separator_existing_animation')),
        matching: find.byType(Text),
      ),
    );

    expect((newSeparator.data, existingSeparator.data == decimalSeparator), (decimalSeparator, false));
  });

  testWidgets('when reduced motion is enabled, it should place a newly entered payment digit immediately', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pump();
    final animation = find.byKey(const ValueKey('create_job_payment_new_digit_animation'));
    final newDigit = find.descendant(of: animation, matching: find.text('1'));
    final initialLeft = tester.getTopLeft(newDigit).dx;
    await tester.pump(const Duration(milliseconds: 70));

    expect(tester.getTopLeft(newDigit).dx, closeTo(initialLeft, 0.1));
  });

  testWidgets('when a payment digit settles, it should keep padding before the right edge fade', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
    await tester.pumpAndSettle();
    final animation = find.byKey(const ValueKey('create_job_payment_new_digit_animation'));
    final newDigit = find.descendant(of: animation, matching: find.text('1'));
    final edgeFade = find.descendant(
      of: animation,
      matching: find.byWidgetPredicate(
        (widget) => widget is MateoEdgeFade && widget.position == MateoEdgeFadePosition.right,
      ),
    );

    expect(tester.getTopLeft(edgeFade).dx, greaterThanOrEqualTo(tester.getTopRight(newDigit).dx));
  });

  testWidgets('when a payment digit is deleted, it should slide only the removed digit outward to the right', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final animation = find.byKey(const ValueKey('create_job_payment_deleted_digit_animation'));
    final deletedDigit = find.descendant(of: animation, matching: find.text('0'));
    final digitMotion = tester.widget<Motion>(find.descendant(of: animation, matching: find.byType(Motion)));
    final stationaryAmount = find.descendant(
      of: find.byKey(const ValueKey('create_job_payment_amount')),
      matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.startsWith(r'R$') ?? false)),
    );
    final exitEffect = digitMotion.effects![1] as MoveMotionEffect;

    expect(
      (
        find.descendant(of: animation, matching: find.byType(Motion)).evaluate().length,
        digitMotion.effects?.length,
        digitMotion.effects?.every((effect) => effect is MoveMotionEffect),
        exitEffect.end,
        find.descendant(of: animation, matching: find.byType(MateoEdgeFade)).evaluate().length,
        tester.getTopLeft(deletedDigit).dx > tester.getTopRight(stationaryAmount).dx,
      ),
      (1, 2, true, const Offset(56, 0), 1, true),
    );
  });

  testWidgets('when a payment digit starts deleting, it should remain at its previous horizontal position', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    final restingAmount = find.descendant(
      of: find.byKey(const ValueKey('create_job_payment_amount')),
      matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.startsWith(r'R$') ?? false)),
    );
    final restingText = tester.widget<Text>(restingAmount).data!;
    final restingParagraph = tester.renderObject<RenderParagraph>(restingAmount);
    final restingDigitBox = restingParagraph
        .getBoxesForSelection(TextSelection(baseOffset: restingText.length - 1, extentOffset: restingText.length))
        .single;
    final restingDigitLeft = restingParagraph.localToGlobal(Offset(restingDigitBox.left, 0)).dx;
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    final deletedDigit = find.descendant(
      of: find.byKey(const ValueKey('create_job_payment_deleted_digit_animation')),
      matching: find.text('0'),
    );
    final deletedDigitParagraph = tester.renderObject<RenderParagraph>(deletedDigit);
    final deletedDigitBox = deletedDigitParagraph
        .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
        .single;
    final deletedDigitLeft = deletedDigitParagraph.localToGlobal(Offset(deletedDigitBox.left, 0)).dx;

    expect(deletedDigitLeft, closeTo(restingDigitLeft, 0.1));
  });

  testWidgets('when backspace cannot delete another payment digit, it should shake the amount horizontally', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
      await tester.pumpAndSettle();
    }
    final stationaryAmount = find.descendant(
      of: find.byKey(const ValueKey('create_job_payment_amount')),
      matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.startsWith(r'R$') ?? false)),
    );
    final restingLeft = tester.getTopLeft(stationaryAmount).dx;
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 35));
    final shake = find.byKey(const ValueKey('create_job_payment_rejected_change'));

    expect(shake.evaluate().length == 1 && (tester.getTopLeft(stationaryAmount).dx - restingLeft).abs() > 0.5, isTrue);
  });

  testWidgets('when a payment change is rejected after entering a digit, it should not replay that digit animation', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(
      tester,
      disableAnimations: false,
      initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
      jobRepository: jobRepository,
    );
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index += 1) {
      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
      await tester.pumpAndSettle();
    }
    final digitAnimation = find.byKey(const ValueKey('create_job_payment_new_digit_animation'));
    final animatedDigit = find.descendant(of: digitAnimation, matching: find.text('1'));
    final stationaryAmount = find.descendant(
      of: find.byKey(const ValueKey('create_job_payment_amount')),
      matching: find.byWidgetPredicate((widget) => widget is Text && (widget.data?.startsWith(r'R$') ?? false)),
    );
    final restingVerticalOffset = tester.getTopLeft(animatedDigit).dy - tester.getTopLeft(stationaryAmount).dy;
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_two')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 35));

    expect(
      tester.getTopLeft(animatedDigit).dy - tester.getTopLeft(stationaryAmount).dy,
      closeTo(restingVerticalOffset, 0.1),
    );
  });

  testWidgets('when the separator is entered without an amount, it should show one zero followed by the separator', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator')));
    await tester.pumpAndSettle();
    final separator = tester.widget<Text>(find.byKey(const Key('mateo_numeric_keypad_decimalSeparator_label'))).data;
    final visibleAmount = tester
        .widgetList<Text>(
          find.descendant(of: find.byKey(const ValueKey('create_job_payment_amount')), matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .join();

    expect(visibleAmount, 'R\$ 0$separator');
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

  testWidgets(
    'when keyboard insets appear during return, it should keep the moving continue action at its remembered position',
    (tester) async {
      await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
      await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final flightButton = CreateJobViewTestHelpers.continueFlightButton(tester);
      final beforeInsetCenter = tester.getCenter(flightButton.first).dy;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump();
      final afterInsetCenter = tester.getCenter(flightButton.first).dy;
      await tester.pumpAndSettle();

      expect(afterInsetCenter, beforeInsetCenter);
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

  testWidgets('when returning from payment, it should keep the continue action size smooth throughout the transition', (
    tester,
  ) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, disableAnimations: false, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_payment_back_button')));
    await tester.pump();
    await tester.pump();
    final sampledSizes = <Size>[];
    for (
      var elapsed = Duration.zero;
      elapsed <= const Duration(milliseconds: 300);
      elapsed += const Duration(milliseconds: 30)
    ) {
      final flightButton = CreateJobViewTestHelpers.continueFlightButton(tester);
      if (flightButton.evaluate().isNotEmpty) sampledSizes.add(tester.getSize(flightButton.first));
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(sampledSizes.map((size) => size.shortestSide), everyElement(53));
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

  testWidgets('when draft creation succeeds, it should restore the continue icon', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _CreateJobDescriptionViewTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create_job_continue_icon')).hitTestable(), findsOneWidget);
  });

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

  testWidgets('when a long description scrolls beneath the heading, it should fade the heading out', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(30, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('create_job_prompt_scroll_view')), const Offset(0, -100));
    await tester.pumpAndSettle();
    final titleOpacity = tester.widget<Opacity>(find.byKey(const ValueKey('create_job_title_scroll_opacity')));

    expect(titleOpacity.opacity, lessThan(1));
  });

  testWidgets('when a scrolled description is cleared, it should restore the heading', (tester) async {
    await CreateJobViewTestHelpers.pumpDescription(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(30, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('create_job_prompt_scroll_view')), const Offset(0, -100));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    final titleOpacity = tester.widget<Opacity>(find.byKey(const ValueKey('create_job_title_scroll_opacity')));

    expect(titleOpacity.opacity, 1);
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
