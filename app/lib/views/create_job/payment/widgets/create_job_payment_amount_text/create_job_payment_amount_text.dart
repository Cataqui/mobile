import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'create_job_payment_amount_text_layout.dart';
part 'create_job_payment_amount_text_metrics.dart';
part 'create_job_payment_amount_text_painter_cache.dart';
part 'create_job_payment_amount_text_render_box.dart';
part 'create_job_payment_amount_text_renderer.dart';
part 'create_job_payment_amount_text_transition_spec.dart';

class CreateJobPaymentAmountText extends ConsumerStatefulWidget {
  const CreateJobPaymentAmountText({
    required this.amountController,
    required this.shakeMotionController,
    required this.textColor,
    required this.alignment,
    super.key,
    this.onAmountWidthChanged,
    this.semanticLabel,
    this.semanticSelected,
  });

  static const fontSize = 46.0;
  static const contentPadding = EdgeInsets.symmetric(horizontal: 40);
  static const transitionDuration = Duration(milliseconds: 160);

  static const _shakeMotionEffect = ShakeMotionEffect(
    offset: Offset(6, 0),
    duration: Duration(milliseconds: 1300),
    curve: Curves.easeOutBack,
  );

  final MateoTextController amountController;
  final MotionController shakeMotionController;
  final Color textColor;
  final Alignment alignment;
  final ValueChanged<double>? onAmountWidthChanged;
  final String? semanticLabel;
  final bool? semanticSelected;

  @override
  ConsumerState<CreateJobPaymentAmountText> createState() => _CreateJobPaymentAmountTextState();
}

class _CreateJobPaymentAmountTextState extends ConsumerState<CreateJobPaymentAmountText> with TickerProviderStateMixin {
  final GlobalKey _rendererKey = GlobalKey();

  late String _amountText;
  late String _currencySymbol;
  bool _amountInputReady = false;

  void _handleAmountChanged() {
    final amountText = widget.amountController.text;
    if (amountText == _amountText) return;

    _amountText = amountText;
    final renderObject = _rendererKey.currentContext?.findRenderObject();
    if (renderObject is! _RenderCreateJobPaymentAmountText) {
      setState(() {});
      return;
    }

    renderObject.updateAmount(
      amountText: amountText,
      amount: ref
          .read(translationProvider)
          .createJob
          .payment
          .amount(currencySymbol: _currencySymbol, value: amountText),
      animate: _amountInputReady && !MediaQuery.disableAnimationsOf(context),
    );
    widget.onAmountWidthChanged?.call(renderObject.amountLayoutWidth);
  }

  void _reportAmountWidth() {
    final renderObject = _rendererKey.currentContext?.findRenderObject();
    if (renderObject is! _RenderCreateJobPaymentAmountText) return;
    widget.onAmountWidthChanged?.call(renderObject.amountLayoutWidth);
  }

  @override
  void initState() {
    super.initState();
    _amountText = widget.amountController.text;
    _currencySymbol = ref.read(createJobStateProvider).currencySymbol(ref.read(translationProvider));
    widget.amountController.addListener(_handleAmountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _amountInputReady = true;
      _reportAmountWidth();
    });
  }

  @override
  void didUpdateWidget(covariant CreateJobPaymentAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amountController != widget.amountController) {
      oldWidget.amountController.removeListener(_handleAmountChanged);
      widget.amountController.addListener(_handleAmountChanged);
      _amountText = widget.amountController.text;
      _amountInputReady = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _amountInputReady = true;
        _reportAmountWidth();
      });
    }
    if (oldWidget.onAmountWidthChanged != widget.onAmountWidthChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reportAmountWidth();
      });
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
    _currencySymbol = currencySymbol;
    final amount = i18n.createJob.payment.amount(currencySymbol: currencySymbol, value: _amountText);
    final textStyle = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: widget.textColor,
        fontSize: CreateJobPaymentAmountText.fontSize,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1,
      ),
    );

    return Motion(
      controller: widget.shakeMotionController,
      startup: MotionStartup.skip,
      effect: CreateJobPaymentAmountText._shakeMotionEffect,
      child: _CreateJobPaymentAmountTextRenderer(
        key: _rendererKey,
        amountText: _amountText,
        amount: amount,
        semanticLabel: widget.semanticLabel,
        semanticSelected: widget.semanticSelected,
        alignment: widget.alignment,
        animate: _amountInputReady && !MediaQuery.disableAnimationsOf(context),
        edgeFadeColor: context.mateo.colorScheme.background,
        devicePixelRatio: View.of(context).devicePixelRatio,
        locale: Localizations.localeOf(context),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        textStyle: textStyle,
        vsync: this,
      ),
    );
  }
}
