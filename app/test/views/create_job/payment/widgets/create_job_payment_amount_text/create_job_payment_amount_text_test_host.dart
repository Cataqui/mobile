import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/payment/widgets/create_job_payment_amount_text/create_job_payment_amount_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../../../utils/test_app.dart';
import '../../../create_job_test_state.dart';

class CreateJobPaymentAmountTextTestHost extends StatefulWidget {
  const CreateJobPaymentAmountTextTestHost({required this.initialAmount, required this.alignment, super.key});

  static Widget buildApp({
    required String initialAmount,
    String currencyCode = 'BRL',
    Alignment alignment = Alignment.center,
    bool disableAnimations = false,
  }) {
    return TestApp(
      mediaQueryData: MediaQueryData(
        size: const Size(390, 80),
        devicePixelRatio: 1,
        textScaler: TextScaler.noScaling,
        disableAnimations: disableAnimations,
      ),
      providerOverrides: [
        translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
        createJobStateProvider.overrideWith(
          () => CreateJobTestState(
            initialData: CreateJobData(currencyCode: currencyCode, paymentMinimumAmount: initialAmount),
          ),
        ),
      ],
      child: CreateJobPaymentAmountTextTestHost(initialAmount: initialAmount, alignment: alignment),
    );
  }

  static Future<void> updateAmount(
    WidgetTester tester, {
    required String amount,
    Duration elapsed = Duration.zero,
  }) async {
    final amountText = tester.widget<CreateJobPaymentAmountText>(find.byType(CreateJobPaymentAmountText));
    amountText.amountController.text = amount;
    await tester.pump();
    if (elapsed == Duration.zero) return;
    await tester.pump(elapsed);
  }

  static void playShake(WidgetTester tester) {
    tester.widget<CreateJobPaymentAmountText>(find.byType(CreateJobPaymentAmountText)).shakeMotionController.play();
  }

  final String initialAmount;
  final Alignment alignment;

  @override
  State<CreateJobPaymentAmountTextTestHost> createState() => _CreateJobPaymentAmountTextTestHostState();
}

class _CreateJobPaymentAmountTextTestHostState extends State<CreateJobPaymentAmountTextTestHost> {
  late final MateoTextInputController _amountController;
  late final MotionController _shakeMotionController;

  @override
  void initState() {
    super.initState();
    _amountController = MateoTextInputController(text: widget.initialAmount);
    _shakeMotionController = MotionController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: CreateJobPaymentAmountText(
        amountController: _amountController,
        shakeMotionController: _shakeMotionController,
        textColor: context.mateo.colorScheme.text.primary,
        alignment: widget.alignment,
      ),
    );
  }
}
