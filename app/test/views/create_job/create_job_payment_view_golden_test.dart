import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'create_job_view_test_helpers.dart';

void main() {
  late MockJobRepository jobRepository;

  setUp(() {
    jobRepository = MockJobRepository();
    when(
      () => jobRepository.createDraft(description: any(named: 'description')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: JobDraftDto.fixture()));
  });

  group('CreateJobPaymentView Golden Tests', () {
    goldenTest(
      'when the payment view is halfway open, it should show the payment controls appearing with the surface',
      fileName: 'create_job_payment_morph_midpoint',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
    );

    goldenTest(
      'when the payment view opening transition settles, it should show the amount, keypad, and continue action',
      fileName: 'create_job_payment_morph_settled',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        return null;
      },
      builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
    );

    goldenTest(
      'when a payment digit moves a grouping separator, it should show the number regrouping around it',
      fileName: 'create_job_payment_new_digit_mid_slide',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );

    goldenTest(
      'when deleting a payment digit moves a grouping separator, it should show the number regrouping back',
      fileName: 'create_job_payment_separator_moves_left_mid_slide',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );

    goldenTest(
      'when a grouping separator appears, it should show the surrounding digits opening a gap',
      fileName: 'create_job_payment_new_separator_mid_open',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );

    goldenTest(
      'when a payment digit removes a grouping separator, it should show both exiting and closing motions',
      fileName: 'create_job_payment_deleted_digit_mid_slide',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );

    goldenTest(
      'when another grouping separator appears, it should move every existing separator while the new one fades in',
      fileName: 'create_job_payment_multiple_separators_mid_open',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
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

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );

    goldenTest(
      'when one of multiple grouping separators disappears, it should fade out while every remaining separator moves',
      fileName: 'create_job_payment_multiple_separators_mid_close',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
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

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );

    goldenTest(
      'when backspace cannot delete another payment digit, it should shake the amount horizontally',
      fileName: 'create_job_payment_rejected_delete_shake',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      whilePerforming: (tester) async {
        await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
        await tester.pumpAndSettle();
        for (var index = 0; index < 4; index += 1) {
          await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 35));

        return () async {
          await tester.pumpAndSettle();
        };
      },
      builder: () => CreateJobViewTestHelpers.buildApp(
        disableAnimations: false,
        initialCreateJobData: const CreateJobData(currencyHint: 'BRL', paymentAmount: '1200'),
        jobRepository: jobRepository,
      ),
    );
  });
}
