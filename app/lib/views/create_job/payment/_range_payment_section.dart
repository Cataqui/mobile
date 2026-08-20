part of 'create_job_payment_view.dart';

class _RangePaymentSection extends ConsumerStatefulWidget {
  const _RangePaymentSection();

  @override
  ConsumerState<_RangePaymentSection> createState() => _RangePaymentSectionState();
}

class _RangePaymentSectionState extends ConsumerState<_RangePaymentSection> with TickerProviderStateMixin {
  static const _minimumAmountKey = ValueKey('create_job_range_minimum_amount');
  static const _maximumAmountKey = ValueKey('create_job_range_maximum_amount');

  late final MateoTextController _minimumAmountTextController;
  late final MateoTextController _maximumAmountTextController;
  late final MotionController _minimumShakeMotionController;
  late final MotionController _maximumShakeMotionController;
  late MateoTextController _selectedAmountTextController;
  late final AnimationController _amountSectionWidthMotionController;
  late final ValueNotifier<double> _animatedAmountSectionWidth;
  double _amountSectionWidth = 0;
  double _amountSectionWidthMotionStart = 0;
  double _amountSectionWidthMotionEnd = 0;
  double _minimumAmountWidth = 0;
  double _maximumAmountWidth = 0;
  CreateJobPaymentAmountTextMetrics? _amountTextMetrics;

  MotionController get _selectedShakeMotionController {
    return identical(_selectedAmountTextController, _minimumAmountTextController)
        ? _minimumShakeMotionController
        : _maximumShakeMotionController;
  }

  void _selectAmount(MateoTextController amountTextController) {
    if (identical(_selectedAmountTextController, amountTextController)) return;
    setState(() => _selectedAmountTextController = amountTextController);
  }

  void _setMinimumAmountText() {
    ref.read(createJobStateProvider.notifier).setPaymentMinimumAmount(_minimumAmountTextController.text);
  }

  void _setMaximumAmountText() {
    ref.read(createJobStateProvider.notifier).setPaymentMaximumAmount(_maximumAmountTextController.text);
  }

  void _updateAmountWidthsFromMetrics() {
    final amountTextMetrics = _amountTextMetrics;
    if (amountTextMetrics == null) return;

    final i18n = ref.read(translationProvider);
    final currencySymbol = ref.read(createJobStateProvider).currencySymbol(i18n);
    _minimumAmountWidth = amountTextMetrics.amountWidth(
      i18n.createJob.payment.amount(currencySymbol: currencySymbol, value: _minimumAmountTextController.text),
    );
    _maximumAmountWidth = amountTextMetrics.amountWidth(
      i18n.createJob.payment.amount(currencySymbol: currencySymbol, value: _maximumAmountTextController.text),
    );
  }

  void _setMinimumAmountWidth(double amountWidth) {
    if (_minimumAmountWidth == amountWidth) return;
    _minimumAmountWidth = amountWidth;
    _updateAmountSectionWidth();
  }

  void _setMaximumAmountWidth(double amountWidth) {
    if (_maximumAmountWidth == amountWidth) return;
    _maximumAmountWidth = amountWidth;
    _updateAmountSectionWidth();
  }

  void _updateAmountSectionWidth() {
    if (!mounted) return;
    final amountTextMetrics = _amountTextMetrics;
    if (amountTextMetrics == null) return;

    final amountSectionWidth = math.min(
      math.max(_minimumAmountWidth, _maximumAmountWidth) + CreateJobPaymentAmountText.contentPadding.horizontal,
      MediaQuery.sizeOf(context).width,
    );
    _setAmountSectionWidth(amountSectionWidth);
  }

  void _setAmountSectionWidth(double amountSectionWidth) {
    if (_amountSectionWidth == amountSectionWidth) return;

    _amountSectionWidth = amountSectionWidth;
    if (_animatedAmountSectionWidth.value == 0 || MediaQuery.disableAnimationsOf(context)) {
      _amountSectionWidthMotionController.stop();
      _animatedAmountSectionWidth.value = amountSectionWidth;
      return;
    }

    _amountSectionWidthMotionStart = _animatedAmountSectionWidth.value;
    _amountSectionWidthMotionEnd = amountSectionWidth;
    _amountSectionWidthMotionController.forward(from: 0);
  }

  void _handleAmountSectionWidthMotion() {
    final progress = Curves.easeOutCubic.transform(_amountSectionWidthMotionController.value);
    _animatedAmountSectionWidth.value =
        _amountSectionWidthMotionStart + (_amountSectionWidthMotionEnd - _amountSectionWidthMotionStart) * progress;
  }

  @override
  void initState() {
    super.initState();
    final createJobData = ref.read(createJobStateProvider);

    _minimumAmountTextController = MateoTextController(text: createJobData.paymentMinimumAmount)
      ..addListener(_setMinimumAmountText);

    _maximumAmountTextController = MateoTextController(text: createJobData.paymentMaximumAmount)
      ..addListener(_setMaximumAmountText);

    _minimumShakeMotionController = MotionController();
    _maximumShakeMotionController = MotionController();

    _selectedAmountTextController = _minimumAmountTextController;
    _amountSectionWidthMotionController = AnimationController(
      duration: CreateJobPaymentAmountText.transitionDuration,
      vsync: this,
    )..addListener(_handleAmountSectionWidthMotion);
    _animatedAmountSectionWidth = ValueNotifier(0);

    ref
      ..listenManual<String>(createJobStateProvider.select((createJobData) => createJobData.currencyCode), (_, _) {
        _updateAmountWidthsFromMetrics();
        _updateAmountSectionWidth();
      })
      ..listenManual(translationProvider, (_, _) {
        _updateAmountWidthsFromMetrics();
        _updateAmountSectionWidth();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _amountSectionWidthMotionController.isAnimating) {
      _amountSectionWidthMotionController.stop();
      _animatedAmountSectionWidth.value = _amountSectionWidth;
    }
    _amountTextMetrics = CreateJobPaymentAmountTextMetrics(
      context: context,
      style: const TextStyle(
        fontSize: CreateJobPaymentAmountText.fontSize,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
        height: 1,
      ),
    );
    _updateAmountWidthsFromMetrics();
    _updateAmountSectionWidth();
  }

  @override
  void dispose() {
    _minimumAmountTextController
      ..removeListener(_setMinimumAmountText)
      ..dispose();

    _maximumAmountTextController
      ..removeListener(_setMaximumAmountText)
      ..dispose();

    _amountSectionWidthMotionController
      ..removeListener(_handleAmountSectionWidthMotion)
      ..dispose();
    _animatedAmountSectionWidth.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);

    final isMinimumSelected = identical(_selectedAmountTextController, _minimumAmountTextController);
    final isMaximumSelected = identical(_selectedAmountTextController, _maximumAmountTextController);

    final amountFields = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAmountField(
          label: i18n.createJob.payment.range.minimumLabel,
          amountTextController: _minimumAmountTextController,
          rejectedChangeController: _minimumShakeMotionController,
          key: _minimumAmountKey,
          selected: isMinimumSelected,
        ),
        const SizedBox(height: 16),
        _buildAmountField(
          label: i18n.createJob.payment.range.maximumLabel,
          amountTextController: _maximumAmountTextController,
          rejectedChangeController: _maximumShakeMotionController,
          key: _maximumAmountKey,
          selected: isMaximumSelected,
        ),
      ],
    );

    return Column(
      key: const ValueKey('create_job_range_payment_content'),
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(width: constraints.maxWidth, child: amountFields),
                ),
              );
            },
          ),
        ),
        MateoNumericKeypad(
          key: const ValueKey('create_job_payment_keypad'),
          controllers: [_selectedAmountTextController],
          variant: MateoNumericKeypadVariant.monetary,
          onChangeRejected: _selectedShakeMotionController.play,
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required String label,
    required MateoTextController amountTextController,
    required MotionController rejectedChangeController,
    required Key key,
    required bool selected,
  }) {
    final amountText = CreateJobPaymentAmountText(
      amountController: amountTextController,
      shakeMotionController: rejectedChangeController,
      textColor: selected ? context.mateo.colorScheme.text.primary : context.mateo.colorScheme.text.tertiary,
      alignment: Alignment.centerLeft,
      onAmountWidthChanged: identical(amountTextController, _minimumAmountTextController)
          ? _setMinimumAmountWidth
          : _setMaximumAmountWidth,
      semanticLabel: label,
      semanticSelected: selected,
    );

    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: CreateJobPaymentAmountText.contentPadding,
          child: Text(
            label,
            style: TextStyle(
              color: context.mateo.colorScheme.text.tertiary,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),

        KeyedSubtree(key: key, child: amountText),
      ],
    );

    return MateoTap(
      key: ValueKey<Object>(('create_job_range_amount_field', key)),
      animation: MateoTapAnimationType.scale,
      onPressed: (animation) async {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _selectAmount(amountTextController);
        });
        WidgetsBinding.instance.scheduleFrame();
      },
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ValueListenableBuilder<double>(
              valueListenable: _animatedAmountSectionWidth,
              child: field,
              builder: (context, animatedWidth, child) {
                final availableWidth = constraints.hasBoundedWidth ? constraints.maxWidth : animatedWidth;
                final positionedWidth = math.min(animatedWidth, availableWidth);
                return Transform.translate(
                  offset: Offset((availableWidth - positionedWidth) / 2, 0),
                  child: SizedBox(width: availableWidth, child: child),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
