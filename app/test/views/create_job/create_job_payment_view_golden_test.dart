import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_draft_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
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

  final goldenConfig = AlchemistConfig.current();
  final exactMotionGoldenConfig = goldenConfig.copyWith(
    ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false, diffThreshold: 0),
  );
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
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
          'when the payment type selector opens, it should show every localized payment option',
          fileName: 'create_job_payment_type_selector_open',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('mateo_select_source')));
            await tester.pumpAndSettle();
            return null;
          },
          builder: () => CreateJobViewTestHelpers.buildApp(disableAnimations: false, jobRepository: jobRepository),
        );

        goldenTest(
          'when range payment opens, it should show the minimum selected above the dimmed maximum',
          fileName: 'create_job_payment_range_minimum_selected',
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
          builder: () => CreateJobViewTestHelpers.buildApp(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
            jobRepository: jobRepository,
          ),
        );

        goldenTest(
          'when the maximum range amount is tapped, it should brighten the maximum and dim the minimum',
          fileName: 'create_job_payment_range_maximum_selected',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(
                const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
              ),
            );
            await tester.pumpAndSettle();
            return null;
          },
          builder: () => CreateJobViewTestHelpers.buildApp(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
            jobRepository: jobRepository,
          ),
        );

        goldenTest(
          'when the minimum range amount grows, it should show both amount fields moving smoothly left',
          fileName: 'create_job_payment_range_amount_mid_resize',
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
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '999',
              paymentType: JobPaymentType.range,
            ),
            jobRepository: jobRepository,
          ),
        );

        goldenTest(
          'when a full-width range amount grows, it should show the amount smoothly scaling down',
          fileName: 'create_job_payment_range_amount_mid_scale',
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
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '99999999999999',
              paymentType: JobPaymentType.range,
            ),
            jobRepository: jobRepository,
          ),
        );
        goldenTest(
          'when a range digit is deleted, it should leave from its previous position while the fields move right',
          fileName: 'create_job_payment_range_deleted_digit_mid_slide',
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
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '58',
              paymentMaximumAmount: '',
              paymentType: JobPaymentType.range,
            ),
            jobRepository: jobRepository,
          ),
        );

        AlchemistConfig.runWithConfig(
          config: exactMotionGoldenConfig,
          run: () {
            goldenTest(
              'when 50 milliseconds pass after a range width shrinks, it should show the departing digit inside the right fade',
              fileName: 'create_job_payment_range_deletion_inside_fade',
              constraints: const BoxConstraints.tightFor(width: 390, height: 844),
              whilePerforming: (tester) async {
                await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
                await tester.pumpAndSettle();
                await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
                await tester.pumpAndSettle();
                await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
                await tester.pumpAndSettle();
                await tester.tap(
                  find.byKey(
                    const ValueKey<Object>((
                      'create_job_range_amount_field',
                      ValueKey('create_job_range_maximum_amount'),
                    )),
                  ),
                );
                await tester.pumpAndSettle();
                await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 50));

                return () async {
                  await tester.pumpAndSettle();
                };
              },
              builder: () => CreateJobViewTestHelpers.buildApp(
                disableAnimations: false,
                initialCreateJobData: const CreateJobData(
                  currencyCode: 'BRL',
                  paymentMinimumAmount: '65',
                  paymentMaximumAmount: '555',
                  paymentType: JobPaymentType.range,
                ),
                jobRepository: jobRepository,
              ),
            );
          },
        );

        goldenTest(
          'when blank space in the maximum range row is pressed, it should scale the full row while selecting it',
          fileName: 'create_job_payment_range_field_pressed',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await tester.tap(find.byKey(CreateJobViewTestHelpers.openButtonKey));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(EditableText), 'Preciso de uma pessoa para descarregar caixas.');
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('create_job_continue_button')));
            await tester.pumpAndSettle();
            final maximumRow = find.byKey(
              const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
            );
            final gesture = await tester.startGesture(tester.getTopRight(maximumRow) - const Offset(16, -36));
            await tester.pump(const Duration(milliseconds: 75));

            return () async {
              await gesture.up();
              await tester.pumpAndSettle();
            };
          },
          builder: () => CreateJobViewTestHelpers.buildApp(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
            jobRepository: jobRepository,
          ),
        );
      });
    },
  );
}
