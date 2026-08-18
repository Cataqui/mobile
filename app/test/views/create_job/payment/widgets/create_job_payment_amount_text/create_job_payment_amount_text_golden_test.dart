import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_job_payment_amount_text_test_host.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  final exactMotionGoldenConfig = goldenConfig.copyWith(
    ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false, diffThreshold: 0),
  );
  const scenarios =
      <
        ({
          String description,
          String fileName,
          String initialAmount,
          List<({String amount, Duration elapsed, bool settle})> updates,
          Duration? shakeElapsed,
        })
      >[
        (
          description:
              'when the first payment number replaces zero, it should show the zero deleting through the edge fade before the number enters',
          fileName: 'create_job_payment_zero_replacement_mid_exit',
          initialAmount: '0',
          updates: [(amount: '6', elapsed: Duration(milliseconds: 40), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when zero has faded out, it should show the first payment number continuing through the payment edge fade',
          fileName: 'create_job_payment_zero_replacement_mid_entry',
          initialAmount: '0',
          updates: [(amount: '6', elapsed: Duration(milliseconds: 100), settle: false)],
          shakeElapsed: null,
        ),
        (
          description: 'when half of the zero disappearance passes, it should show the new number beginning to enter',
          fileName: 'create_job_payment_zero_replacement_entry_boundary',
          initialAmount: '0',
          updates: [(amount: '6', elapsed: Duration(milliseconds: 65), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when a payment digit crosses the edge fade, it should blend into the amount without a visible boundary',
          fileName: 'create_job_payment_digit_inside_smooth_edge_fade',
          initialAmount: '99',
          updates: [(amount: '999', elapsed: Duration(milliseconds: 24), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when entering a digit adds a grouping separator, it should rise from below without flashing across a neighboring digit',
          fileName: 'create_job_payment_separator_enters_without_digit_flash',
          initialAmount: '777',
          updates: [(amount: '7,770', elapsed: Duration(milliseconds: 16), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when deleting a digit removes a grouping separator, it should leave through the bottom fade without flashing across a neighboring digit',
          fileName: 'create_job_payment_separator_exits_without_digit_flash',
          initialAmount: '7,770',
          updates: [(amount: '777', elapsed: Duration(milliseconds: 16), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when 64 milliseconds pass after removing a grouping separator, it should already be mostly through the bottom fade',
          fileName: 'create_job_payment_separator_downward_exit_faster',
          initialAmount: '7,770',
          updates: [(amount: '777', elapsed: Duration(milliseconds: 64), settle: false)],
          shakeElapsed: null,
        ),
        (
          description: 'when a full-width payment amount loses a digit, it should show the amount smoothly scaling up',
          fileName: 'create_job_payment_amount_mid_scale_up',
          initialAmount: '5555550000000',
          updates: [(amount: '555,555,000,000', elapsed: Duration(milliseconds: 70), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when a fixed payment amount fills the row, it should keep the entering digit inside a smooth right fade',
          fileName: 'create_job_payment_full_width_digit_inside_fade',
          initialAmount: '86594976977',
          updates: [(amount: '865,949,769,779', elapsed: Duration(milliseconds: 70), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when a payment digit moves a grouping separator, it should show the number regrouping around it',
          fileName: 'create_job_payment_new_digit_mid_slide',
          initialAmount: '1200',
          updates: [(amount: '12,001', elapsed: Duration(milliseconds: 70), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when deleting a payment digit moves a grouping separator, it should show the number regrouping back',
          fileName: 'create_job_payment_separator_moves_left_mid_slide',
          initialAmount: '1200',
          updates: [
            (amount: '12,001', elapsed: Duration.zero, settle: true),
            (amount: '1,200', elapsed: Duration(milliseconds: 70), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description: 'when a grouping separator appears, it should show the surrounding digits opening a gap',
          fileName: 'create_job_payment_new_separator_mid_open',
          initialAmount: '1200',
          updates: [
            (amount: '120', elapsed: Duration.zero, settle: true),
            (amount: '1,201', elapsed: Duration(milliseconds: 70), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description:
              'when a payment digit removes a grouping separator, it should show both exiting and closing motions',
          fileName: 'create_job_payment_deleted_digit_mid_slide',
          initialAmount: '1200',
          updates: [(amount: '120', elapsed: Duration(milliseconds: 70), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when another grouping separator appears, it should move every existing separator while the new one rises from below',
          fileName: 'create_job_payment_multiple_separators_mid_open',
          initialAmount: '1200',
          updates: [
            (amount: '12,000', elapsed: Duration.zero, settle: true),
            (amount: '120,000', elapsed: Duration.zero, settle: true),
            (amount: '1,200,000', elapsed: Duration(milliseconds: 70), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description:
              'when one of multiple grouping separators disappears, it should move below while every remaining separator moves',
          fileName: 'create_job_payment_multiple_separators_mid_close',
          initialAmount: '1200',
          updates: [
            (amount: '12,000', elapsed: Duration.zero, settle: true),
            (amount: '120,000', elapsed: Duration.zero, settle: true),
            (amount: '1,200,000', elapsed: Duration.zero, settle: true),
            (amount: '120,000', elapsed: Duration(milliseconds: 70), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description:
              'when deleting a seven reformats multiple grouping separators, it should keep the seven glyph whole',
          fileName: 'create_job_payment_seven_mid_delete',
          initialAmount: '777777777777777777',
          updates: [(amount: '77,777,777,777,777,777', elapsed: Duration(milliseconds: 16), settle: false)],
          shakeElapsed: null,
        ),
        (
          description:
              'when three payment digits are deleted rapidly, it should keep every departing digit moving out without returning',
          fileName: 'create_job_payment_rapid_deletions_mid_exit',
          initialAmount: '1234567',
          updates: [
            (amount: '123,456', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '12,345', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '1,234', elapsed: Duration(milliseconds: 63), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description: 'when several digits are entered before zero finishes leaving, it should keep zero moving out',
          fileName: 'create_job_payment_zero_exit_during_rapid_input',
          initialAmount: '0',
          updates: [
            (amount: '3', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '31', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '312', elapsed: Duration(milliseconds: 18), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description:
              'when a third digit arrives while a delayed second digit is waiting, it should preserve the typed order',
          fileName: 'create_job_payment_zero_then_two_digits_mid_motion',
          initialAmount: '0',
          updates: [
            (amount: '3', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '35', elapsed: Duration(milliseconds: 190), settle: false),
            (amount: '350', elapsed: Duration(milliseconds: 30), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description:
              'when 4, 6, and 5 are entered before zero finishes leaving, it should keep every digit behind the final fade boundary',
          fileName: 'create_job_payment_rapid_465_inside_final_fade',
          initialAmount: '0',
          updates: [
            (amount: '4', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '46', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '465', elapsed: Duration(milliseconds: 250), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description:
              'when rapid input inserts a grouping separator while another digit enters, it should keep the rising separator outside the fade',
          fileName: 'create_job_payment_rapid_separator_retarget',
          initialAmount: '0',
          updates: [
            (amount: '4', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '45', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '457', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '4,578', elapsed: Duration(milliseconds: 18), settle: false),
            (amount: '45,787', elapsed: Duration(milliseconds: 70), settle: false),
          ],
          shakeElapsed: null,
        ),
        (
          description: 'when deleting cannot remove another payment digit, it should shake the amount horizontally',
          fileName: 'create_job_payment_rejected_delete_shake',
          initialAmount: '0',
          updates: [],
          shakeElapsed: Duration(milliseconds: 35),
        ),
      ];

  AlchemistConfig.runWithConfig(
    config: exactMotionGoldenConfig,
    run: () {
      group('CreateJobPaymentAmountText Golden Tests', () {
        for (final scenario in scenarios) {
          goldenTest(
            scenario.description,
            fileName: scenario.fileName,
            constraints: const BoxConstraints.tightFor(width: 390, height: 80),
            whilePerforming: (tester) async {
              await tester.pumpAndSettle();
              for (final update in scenario.updates) {
                await CreateJobPaymentAmountTextTestHost.updateAmount(
                  tester,
                  amount: update.amount,
                  elapsed: update.elapsed,
                );
                if (update.settle) await tester.pumpAndSettle();
              }
              final shakeElapsed = scenario.shakeElapsed;
              if (shakeElapsed != null) {
                CreateJobPaymentAmountTextTestHost.playShake(tester);
                await tester.pump();
                await tester.pump(shakeElapsed);
              }

              return () async {
                await tester.pumpAndSettle();
              };
            },
            builder: () => CreateJobPaymentAmountTextTestHost.buildApp(initialAmount: scenario.initialAmount),
          );
        }
      });
    },
  );
}
