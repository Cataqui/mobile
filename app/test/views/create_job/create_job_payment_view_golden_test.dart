import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';
import 'create_job_test_state.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  final exactMotionGoldenConfig = goldenConfig.copyWith(
    ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false, diffThreshold: 0),
  );
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      group('CreateJobPaymentView Golden Tests', () {
        goldenTest(
          'when the payment view renders, it should show the amount, keypad, and continue action',
          fileName: 'create_job_payment_morph_settled',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(disableAnimations: false),
        );
        goldenTest(
          'when the payment type selector opens, it should show every localized payment option',
          fileName: 'create_job_payment_type_selector_open',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            await tester.tap(find.byKey(const Key('mateo_select_source')));
            await tester.pumpAndSettle();
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(disableAnimations: false),
        );

        goldenTest(
          'when flexible payment is selected with reduced motion, it should show three resting BRL amounts',
          fileName: 'create_job_payment_flexible_carousel_resting',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.flexible),
          ),
        );

        AlchemistConfig.runWithConfig(
          config: exactMotionGoldenConfig,
          run: () {
            goldenTest(
              'when flexible BRL amounts are halfway through a step, it should fade the outgoing value at the top edge',
              fileName: 'create_job_payment_flexible_carousel_mid_step',
              constraints: const BoxConstraints.tightFor(width: 390, height: 844),
              whilePerforming: (tester) async {
                await _CreateJobPaymentGoldenTestActions.prepare(tester);
                final container = ProviderScope.containerOf(
                  tester.element(find.byKey(const ValueKey('create_job_payment_view_content'))),
                );
                container.read(createJobStateProvider.notifier).setCurrencyCode('BRL');
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 1000));
                return null;
              },
              builder: () => _CreateJobPaymentGoldenTestActions.buildView(
                disableAnimations: false,
                initialCreateJobData: const CreateJobData(currencyCode: 'ARS', paymentType: JobPaymentType.flexible),
              ),
            );

            goldenTest(
              'when a flexible BRL value enters from the bottom edge, it should begin fully concealed by the fade',
              fileName: 'create_job_payment_flexible_carousel_bottom_edge_entry',
              constraints: const BoxConstraints.tightFor(width: 390, height: 844),
              whilePerforming: (tester) async {
                await _CreateJobPaymentGoldenTestActions.prepare(tester);
                final container = ProviderScope.containerOf(
                  tester.element(find.byKey(const ValueKey('create_job_payment_view_content'))),
                );
                container.read(createJobStateProvider.notifier).setCurrencyCode('BRL');
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 1));
                return null;
              },
              builder: () => _CreateJobPaymentGoldenTestActions.buildView(
                disableAnimations: false,
                initialCreateJobData: const CreateJobData(currencyCode: 'ARS', paymentType: JobPaymentType.flexible),
              ),
            );

            goldenTest(
              'when a flexible BRL value exits through the top edge, it should finish fully concealed by the fade',
              fileName: 'create_job_payment_flexible_carousel_top_edge_exit',
              constraints: const BoxConstraints.tightFor(width: 390, height: 844),
              whilePerforming: (tester) async {
                await _CreateJobPaymentGoldenTestActions.prepare(tester);
                final container = ProviderScope.containerOf(
                  tester.element(find.byKey(const ValueKey('create_job_payment_view_content'))),
                );
                container.read(createJobStateProvider.notifier).setCurrencyCode('BRL');
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 1999));
                return null;
              },
              builder: () => _CreateJobPaymentGoldenTestActions.buildView(
                disableAnimations: false,
                initialCreateJobData: const CreateJobData(currencyCode: 'ARS', paymentType: JobPaymentType.flexible),
              ),
            );
          },
        );

        goldenTest(
          'when range payment opens, it should show the minimum selected above the dimmed maximum',
          fileName: 'create_job_payment_range_minimum_selected',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
          ),
        );

        goldenTest(
          'when range payment opens on a short screen, it should scale both amounts above the keypad',
          fileName: 'create_job_payment_range_short_screen',
          constraints: const BoxConstraints.tightFor(width: 390, height: 640),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            screenSize: const Size(390, 640),
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
          ),
        );

        goldenTest(
          'when the maximum range amount is tapped, it should brighten the maximum and dim the minimum',
          fileName: 'create_job_payment_range_maximum_selected',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            await tester.tap(
              find.byKey(
                const ValueKey<Object>(('create_job_range_amount_field', ValueKey('create_job_range_maximum_amount'))),
              ),
            );
            await tester.pumpAndSettle();
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
          ),
        );

        goldenTest(
          'when the minimum range amount grows, it should show both amount fields moving smoothly left',
          fileName: 'create_job_payment_range_amount_mid_resize',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 70));

            return () async {
              await tester.pumpAndSettle();
            };
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '999',
              paymentType: JobPaymentType.range,
            ),
          ),
        );

        goldenTest(
          'when a full-width range amount grows, it should show the amount smoothly scaling down',
          fileName: 'create_job_payment_range_amount_mid_scale',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            await tester.tap(find.byKey(const Key('mateo_numeric_keypad_one')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 70));

            return () async {
              await tester.pumpAndSettle();
            };
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '99999999999999',
              paymentType: JobPaymentType.range,
            ),
          ),
        );
        goldenTest(
          'when a range digit is deleted, it should leave from its previous position while the fields move right',
          fileName: 'create_job_payment_range_deleted_digit_mid_slide',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            await tester.tap(find.byKey(const Key('mateo_numeric_keypad_backspace')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 70));

            return () async {
              await tester.pumpAndSettle();
            };
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '58',
              paymentMaximumAmount: '',
              paymentType: JobPaymentType.range,
            ),
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
                await _CreateJobPaymentGoldenTestActions.prepare(tester);
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
              builder: () => _CreateJobPaymentGoldenTestActions.buildView(
                disableAnimations: false,
                initialCreateJobData: const CreateJobData(
                  currencyCode: 'BRL',
                  paymentMinimumAmount: '65',
                  paymentMaximumAmount: '555',
                  paymentType: JobPaymentType.range,
                ),
              ),
            );
          },
        );

        goldenTest(
          'when blank space in the maximum range row is pressed, it should scale the full row while selecting it',
          fileName: 'create_job_payment_range_field_pressed',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
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
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentMinimumAmount: '350',
              paymentMaximumAmount: '700',
              paymentType: JobPaymentType.range,
            ),
          ),
        );

        goldenTest(
          'when another payment opens without an explanation, it should show the localized writing prompt',
          fileName: 'create_job_other_payment_empty',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.other),
          ),
        );

        goldenTest(
          'when another payment opens with a saved explanation, it should show the text and character count',
          fileName: 'create_job_other_payment_filled',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(
              currencyCode: 'BRL',
              paymentType: JobPaymentType.other,
              paymentNote: 'Duas cestas básicas',
            ),
          ),
        );

        goldenTest(
          'when another payment reaches its final lines, it should soften the boundary above continue',
          fileName: 'create_job_other_payment_long_note_boundary',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            disableAnimations: false,
            initialCreateJobData: CreateJobData(
              currencyCode: 'BRL',
              paymentType: JobPaymentType.other,
              paymentNote: List<String>.filled(18, 'Pagamento combinado').join('\n'),
            ),
          ),
        );

        goldenTest(
          'when another payment opens with the keyboard, it should keep the continue action above the typing area',
          fileName: 'create_job_other_payment_keyboard_open',
          constraints: const BoxConstraints.tightFor(width: 390, height: 844),
          whilePerforming: (tester) async {
            await _CreateJobPaymentGoldenTestActions.prepare(tester);
            return null;
          },
          builder: () => _CreateJobPaymentGoldenTestActions.buildView(
            keyboardInset: 300,
            disableAnimations: false,
            initialCreateJobData: const CreateJobData(currencyCode: 'BRL', paymentType: JobPaymentType.other),
          ),
        );
      });
    },
  );
}

abstract final class _CreateJobPaymentGoldenTestActions {
  static Future<void> prepare(WidgetTester tester) async {
    await tester.runAsync(() => CreateJobPaymentView.precacheImages(tester.element(find.byType(CreateJobPaymentView))));
    await tester.pumpAndSettle();
  }

  static Widget buildView({
    Size screenSize = const Size(390, 844),
    double keyboardInset = 0,
    bool disableAnimations = true,
    CreateJobData initialCreateJobData = const CreateJobData(currencyCode: 'BRL'),
  }) {
    return TestApp.screen(
      mediaQueryData: MediaQueryData(
        size: screenSize,
        devicePixelRatio: 1,
        padding: EdgeInsets.only(top: 47, bottom: keyboardInset > 0 ? 0 : 34),
        viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
        textScaler: TextScaler.noScaling,
        disableAnimations: disableAnimations,
      ),
      providerOverrides: [
        translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
        createJobStateProvider.overrideWith(() => CreateJobTestState(initialData: initialCreateJobData)),
      ],
      child: const CreateJobPaymentView(jobId: 'draft-job-id'),
    );
  }
}
