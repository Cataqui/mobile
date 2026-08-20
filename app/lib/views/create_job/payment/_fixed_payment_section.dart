part of 'create_job_payment_view.dart';

class _FixedPaymentSection extends ConsumerStatefulWidget {
  const _FixedPaymentSection();

  @override
  ConsumerState<_FixedPaymentSection> createState() => _FixedPaymentSectionState();
}

class _FixedPaymentSectionState extends ConsumerState<_FixedPaymentSection> {
  late final MateoTextController _amountTextController;
  late final MotionController _shakeAmountMotionController;

  void _setAmountText() {
    ref.read(createJobStateProvider.notifier).setPaymentMinimumAmount(_amountTextController.text);
  }

  @override
  void initState() {
    super.initState();
    _amountTextController = MateoTextController(text: ref.read(createJobStateProvider).paymentMinimumAmount)
      ..addListener(_setAmountText);

    _shakeAmountMotionController = MotionController();
  }

  @override
  void dispose() {
    _amountTextController
      ..removeListener(_setAmountText)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = KeyedSubtree(
      key: const ValueKey('create_job_payment_amount'),
      child: CreateJobPaymentAmountText(
        amountController: _amountTextController,
        shakeMotionController: _shakeAmountMotionController,
        textColor: context.mateo.colorScheme.text.primary,
        alignment: Alignment.center,
      ),
    );

    return Column(
      key: const ValueKey('create_job_fixed_payment_content'),
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(width: constraints.maxWidth, child: amount),
                ),
              );
            },
          ),
        ),
        MateoNumericKeypad(
          key: const ValueKey('create_job_payment_keypad'),
          controllers: [_amountTextController],
          variant: MateoNumericKeypadVariant.monetary,
          onChangeRejected: _shakeAmountMotionController.play,
        ),
      ],
    );
  }
}
