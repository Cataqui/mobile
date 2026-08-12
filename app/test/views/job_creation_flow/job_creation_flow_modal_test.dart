import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_modal.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../mocks.dart';
import 'job_creation_flow_modal_test_helpers.dart';

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

  testWidgets('when the creation action is tapped, it should open the job creation bottom sheet', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);

    expect(find.byType(JobCreationFlowModal), findsOneWidget);
  });

  testWidgets('when the job creation sheet opens, it should host the description in a sequence', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final descriptionStep = find.descendant(
      of: find.byType(Sequence),
      matching: find.byKey(const ValueKey('job_creation_flow_description_step')),
    );

    expect(descriptionStep, findsOneWidget);
  });

  testWidgets('when the job creation sheet opens, it should not nest another scaffold inside the sheet', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final nestedScaffold = find.descendant(
      of: find.byKey(const Key('mateo_bottom_sheet_surface')),
      matching: find.byType(Scaffold),
    );

    expect(nestedScaffold, findsNothing);
  });

  testWidgets('when the keyboard is visible, it should keep the sheet above the keyboard', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, keyboardInset: 300);
    final sheetBottom = tester.getBottomRight(find.byKey(const Key('mateo_bottom_sheet_surface'))).dy;

    expect(sheetBottom, lessThanOrEqualTo(532));
  });

  testWidgets('when the job creation sheet opens, it should describe the continue action', (tester) async {
    final semantics = tester.ensureSemantics();
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), 'Preciso de ajuda');
    await tester.pumpAndSettle();

    try {
      expect(find.bySemanticsLabel(i18n.jobCreationFlow.continueButtonSemanticLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when the description is empty, it should keep the continue action hidden', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);

    expect(find.byKey(const ValueKey('job_creation_flow_continue_button')), findsNothing);
  });

  testWidgets('when the description contains only whitespace, it should keep the continue action hidden', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '   \n  ');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job_creation_flow_continue_button')), findsNothing);
  });

  testWidgets('when meaningful description text is entered, it should reveal a tappable continue action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), 'Curto');
    await tester.pumpAndSettle();

    try {
      expect(find.bySemanticsLabel(i18n.jobCreationFlow.continueButtonSemanticLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('when description text is entered, it should store the exact text in the shared flow state', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '  Preciso de ajuda  ');
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(JobCreationFlowModal)));

    expect(container.read(jobCreationFlowStateProvider).descriptionText, '  Preciso de ajuda  ');
  });

  testWidgets('when the description step mounts with saved flow data, it should restore the description text', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(
      tester,
      initialFlowData: const JobCreationFlowData(descriptionText: 'Descrição já preenchida'),
    );
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, 'Descrição já preenchida');
  });

  testWidgets('when a 9-character description is continued, it should show the translated error toast', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(9, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(i18n.jobCreationFlow.steps.description.tooShortError), findsOneWidget);
  });

  testWidgets(
    'when surrounding whitespace pushes a 9-character description past the limit, it should remain too short',
    (tester) async {
      await JobCreationFlowModalTestHelpers.pumpSheet(tester);
      await tester.enterText(find.byType(TextField), '  ${List<String>.filled(9, 'a').join()}  ');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(i18n.jobCreationFlow.steps.description.tooShortError), findsOneWidget);
    },
  );

  testWidgets('when a 10-character description is continued, it should keep the description step active', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job_creation_flow_description_step')), findsOneWidget);
  });

  testWidgets('when a valid description is continued, it should not show the short-description error', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pumpAndSettle();

    expect(find.text(i18n.jobCreationFlow.steps.description.tooShortError), findsNothing);
  });

  testWidgets('when a 10000-character description is continued, it should create the draft', (tester) async {
    final description = List<String>.filled(10000, 'a').join();
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), description);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pumpAndSettle();

    verify(() => jobRepository.createDraft(description: description)).called(1);
  });

  testWidgets('when a 10001-character description is continued, it should show the translated length error', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10001, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(i18n.jobCreationFlow.steps.description.tooLongError(characterCount: 10001)), findsOneWidget);
  });

  testWidgets('when a 10001-character description is continued, it should not create a draft', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), List<String>.filled(10001, 'a').join());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    verifyNever(() => jobRepository.createDraft(description: any(named: 'description')));
  });

  testWidgets('when draft creation remains pending, it should show the Mateo loader', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('mateo_floating_action_button_loading_indicator')), findsOneWidget);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending, it should disable description editing', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
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
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, _JobCreationFlowModalTestData.validDescription);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation finishes, it should restore description editing', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
    final textInput = tester.widget<MateoTextInput>(find.byType(MateoTextInput));

    expect(textInput.editable, isTrue);
  });

  testWidgets('when draft creation remains pending, it should keep the keyboard visible', (tester) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
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
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump();

    verify(() => jobRepository.createDraft(description: _JobCreationFlowModalTestData.validDescription)).called(1);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending and Android back is pressed, it should keep the modal open', (
    tester,
  ) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(JobCreationFlowModal), findsOneWidget);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pumpAndSettle();
  });

  testWidgets('when draft creation remains pending and the close button is tapped, it should close the modal', (
    tester,
  ) async {
    final response = Completer<ApiEnvelopeDto<JobDraftDto>>();
    when(() => jobRepository.createDraft(description: any(named: 'description'))).thenAnswer((_) => response.future);
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('mateo_bottom_sheet_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(JobCreationFlowModal), findsNothing);
    response.complete(ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
    await tester.pump();
  });

  testWidgets('when draft creation succeeds, it should restore the continue icon', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job_creation_flow_continue_icon')), findsOneWidget);
  });

  testWidgets('when draft creation fails, it should show the translated request error', (tester) async {
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenThrow(Exception('request failed'));
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(i18n.jobCreationFlow.createDraftError), findsOneWidget);
  });

  testWidgets('when draft creation fails, it should preserve the entered description', (tester) async {
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenThrow(Exception('request failed'));
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, jobRepository: jobRepository);
    await tester.enterText(find.byType(TextField), _JobCreationFlowModalTestData.validDescription);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job_creation_flow_continue_button')));
    await tester.pumpAndSettle();
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, _JobCreationFlowModalTestData.validDescription);
  });

  testWidgets('when all meaningful description text is removed, it should hide the continue action', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), 'Preciso de ajuda');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job_creation_flow_continue_button')), findsNothing);
  });

  testWidgets('when animations are enabled and typing starts, it should pop the continue action into view', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester, disableAnimations: false);

    await tester.enterText(find.byType(TextField), 'Preciso');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final scaleTransition = tester.widget<ScaleTransition>(
      find.byKey(const ValueKey('job_creation_flow_continue_show_scale')),
    );

    expect(scaleTransition.scale.value, isNot(1));
  });

  testWidgets('when the job creation sheet opens, it should show what the person needs as its title', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);

    expect(find.text(i18n.jobCreationFlow.steps.description.title), findsOneWidget);
  });

  testWidgets('when the description step opens, it should show the localized writing prompt', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);

    expect(find.text(i18n.jobCreationFlow.steps.description.placeholder), findsOneWidget);
  });

  testWidgets('when the job creation sheet opens, it should not show the removed help action', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);

    expect(find.byKey(const ValueKey('job_creation_flow_help_button')), findsNothing);
  });

  testWidgets('when the job creation sheet opens, it should align the title with the close button', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final titleCenter = tester.getCenter(find.byKey(const ValueKey('job_creation_flow_title'))).dy;
    final closeButtonCenter = tester.getCenter(find.byKey(const Key('mateo_bottom_sheet_close_button'))).dy;

    expect(titleCenter, closeButtonCenter);
  });

  testWidgets('when the job creation sheet opens, it should paint the title above the top edge fade', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final stepStack = tester.widget<Stack>(find.byKey(const ValueKey('job_creation_flow_description_step_stack')));
    final topEdgeFadeIndex = stepStack.children.indexWhere(
      (child) => child.key == const ValueKey('job_creation_flow_top_edge_fade_layer'),
    );
    final titleIndex = stepStack.children.indexWhere(
      (child) => child.key == const ValueKey('job_creation_flow_title_layer'),
    );

    expect(titleIndex, greaterThan(topEdgeFadeIndex));
  });

  testWidgets('when the job creation sheet opens, it should soften the top content boundary', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final topEdgeFade = tester.widget<MateoEdgeFade>(find.byKey(const ValueKey('job_creation_flow_top_edge_fade')));

    expect(topEdgeFade.style.height, JobCreationFlowModal.topEdgeFadeHeight);
  });

  testWidgets('when the prompt scrolls, it should move behind the top fade before reaching the sheet boundary', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final promptViewportTop = tester.getTopLeft(find.byKey(const ValueKey('job_creation_flow_prompt_scroll_view'))).dy;
    final topEdgeFadeTop = tester.getTopLeft(find.byKey(const ValueKey('job_creation_flow_top_edge_fade'))).dy;

    expect(promptViewportTop, topEdgeFadeTop);
  });

  testWidgets('when the prompt is empty, it should reserve the configured top spacing before its content', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final promptScrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('job_creation_flow_prompt_scroll_view')),
    );

    expect(promptScrollView.padding?.resolve(TextDirection.ltr).top, JobCreationFlowModal.topEdgeFadeHeight - 35);
  });

  testWidgets('when the job creation sheet opens, it should keep the prompt content above the bottom fade', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    final bottomEdgeFadeFinder = find.byKey(const ValueKey('job_creation_flow_bottom_edge_fade'));
    final bottomEdgeFade = tester.widget<MateoEdgeFade>(bottomEdgeFadeFinder);
    final bottomEdgeFadeHeight = bottomEdgeFade.style.resolve(tester.element(bottomEdgeFadeFinder)).height!;
    final promptScrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('job_creation_flow_prompt_scroll_view')),
    );

    expect(promptScrollView.padding?.resolve(TextDirection.ltr).bottom, bottomEdgeFadeHeight);
  });

  testWidgets('when typing the final prompt line, it should keep the caret above the bottom fade', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(20, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();
    final renderEditableFinder = find.descendant(
      of: find.byType(EditableText),
      matching: find.byElementPredicate((element) => element.renderObject is RenderEditable),
    );
    final renderEditable = tester.renderObject<RenderEditable>(renderEditableFinder);
    final caretRect = renderEditable.getLocalRectForCaret(renderEditable.selection!.extent);
    final caretBottom = renderEditable.localToGlobal(caretRect.bottomLeft).dy;
    final bottomEdgeFadeTop = tester.getTopLeft(find.byKey(const ValueKey('job_creation_flow_bottom_edge_fade'))).dy;

    expect(caretBottom, lessThanOrEqualTo(bottomEdgeFadeTop));
  });

  testWidgets('when the prompt grows across many lines, it should keep the sheet layout within its bounds', (
    tester,
  ) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.enterText(find.byType(TextField), List<String>.filled(20, 'Preciso de ajuda hoje').join('\n'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('when the backdrop is tapped, it should keep the protected job creation sheet open', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byType(JobCreationFlowModal), findsOneWidget);
  });

  testWidgets('when the close button is tapped, it should close the job creation sheet', (tester) async {
    await JobCreationFlowModalTestHelpers.pumpSheet(tester);
    await tester.tap(find.byKey(const Key('mateo_bottom_sheet_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(JobCreationFlowModal), findsNothing);
  });
}

abstract final class _JobCreationFlowModalTestData {
  static const validDescription = 'Preciso de uma pessoa para descarregar caixas.';
}
