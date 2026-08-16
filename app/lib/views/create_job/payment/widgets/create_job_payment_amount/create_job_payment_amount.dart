part of '../../create_job_payment_view.dart';

class _CreateJobPaymentAmount extends ConsumerStatefulWidget {
  const _CreateJobPaymentAmount({required this.amountController, required this.shakeMotionController});

  final MateoTextInputController amountController;
  final MotionController shakeMotionController;

  @override
  ConsumerState<_CreateJobPaymentAmount> createState() => _CreateJobPaymentAmountState();
}

class _CreateJobPaymentAmountState extends ConsumerState<_CreateJobPaymentAmount> {
  late String _amountText;
  late String _previousAmountText;
  late String _previousDigits;
  String? _newTrailingDigit;
  String? _deletedTrailingDigit;
  int _amountAnimationRevision = 0;
  bool _amountInputReady = false;

  void _handleAmountChanged() {
    final amountText = widget.amountController.text;
    if (amountText == _amountText) return;

    final digits = _CreateJobPaymentAmountTransitionSpec.digitsOf(amountText);
    if (!_amountInputReady) {
      _amountText = amountText;
      _previousAmountText = amountText;
      _previousDigits = digits;
      return;
    }

    final newTrailingDigit = digits.length == _previousDigits.length + 1 && digits.startsWith(_previousDigits)
        ? digits.substring(digits.length - 1)
        : null;
    final deletedTrailingDigit = _previousDigits.length == digits.length + 1 && _previousDigits.startsWith(digits)
        ? _previousDigits.substring(_previousDigits.length - 1)
        : null;
    final insertedTrailingSeparator =
        amountText.length == _amountText.length + 1 &&
        amountText.startsWith(_amountText) &&
        _CreateJobPaymentAmountTransitionSpec.isNonDigit(amountText[amountText.length - 1]);
    final replacedDigit = _CreateJobPaymentAmountTransitionSpec.findReplacedDigit(_amountText, amountText);
    if (newTrailingDigit == null &&
        deletedTrailingDigit == null &&
        !insertedTrailingSeparator &&
        replacedDigit == null) {
      setState(_synchronizeAmountWithoutAnimation);
      return;
    }

    setState(() {
      _previousAmountText = _amountText;
      _amountText = amountText;
      _previousDigits = digits;
      _newTrailingDigit = newTrailingDigit;
      _deletedTrailingDigit = deletedTrailingDigit;
      _amountAnimationRevision += 1;
    });
  }

  void _synchronizeAmountWithoutAnimation() {
    _amountText = widget.amountController.text;
    _previousAmountText = _amountText;
    _previousDigits = _CreateJobPaymentAmountTransitionSpec.digitsOf(_amountText);
    _newTrailingDigit = null;
    _deletedTrailingDigit = null;
  }

  @override
  void initState() {
    super.initState();
    _synchronizeAmountWithoutAnimation();
    widget.amountController.addListener(_handleAmountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _synchronizeAmountWithoutAnimation();
        _amountInputReady = true;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _CreateJobPaymentAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amountController != widget.amountController) {
      oldWidget.amountController.removeListener(_handleAmountChanged);
      widget.amountController.addListener(_handleAmountChanged);
      _synchronizeAmountWithoutAnimation();
    }
  }

  @override
  void dispose() {
    widget.amountController.removeListener(_handleAmountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    final currencySymbol = ref.watch(
      createJobStateProvider.select((createJobData) => createJobData.currencySymbol(i18n)),
    );
    return _CreateJobPaymentAmountTransition(
      amount: i18n.createJob.payment.amount(currencySymbol: currencySymbol, value: _amountText),
      previousAmount: i18n.createJob.payment.amount(currencySymbol: currencySymbol, value: _previousAmountText),
      newTrailingDigit: _newTrailingDigit,
      deletedTrailingDigit: _deletedTrailingDigit,
      animationRevision: _amountAnimationRevision,
      rejectedChangeController: widget.shakeMotionController,
    );
  }
}
