import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'flexible_payment_values_wheel_amount_values.dart';
part 'flexible_payment_values_wheel_painter_cache.dart';
part 'flexible_payment_values_wheel_render_box.dart';
part 'flexible_payment_values_wheel_renderer.dart';

class FlexiblePaymentValuesWheel extends ConsumerStatefulWidget {
  const FlexiblePaymentValuesWheel({super.key});

  static const _amountStepDuration = Duration(milliseconds: 2000);
  static const _height = 200.0;
  static const _fontSize = 46.0;
  static const _adjacentAmountScale = 0.6;
  static const _stepMotionStrength = 0.35;
  static const _horizontalContentPadding = 40.0;
  static const _slotExtent = _height / 4;

  @override
  ConsumerState<FlexiblePaymentValuesWheel> createState() => _FlexiblePaymentValuesWheelState();
}

class _FlexiblePaymentValuesWheelState extends ConsumerState<FlexiblePaymentValuesWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wheelController;
  List<int>? _amountValues;
  bool? _disableAnimations;
  Animation<double>? _primaryRouteAnimation;
  Animation<double>? _secondaryRouteAnimation;

  ({Color adjacent, Color centered}) get _amountColors => switch (Theme.of(context).brightness) {
    Brightness.light => (adjacent: context.mateo.palette.orange[3], centered: context.mateo.palette.orange[5]),
    Brightness.dark => throw UnsupportedError('FlexiblePaymentValuesWheel does not support dark mode.'),
  };

  bool get _isRouteSettled {
    final primaryRouteAnimation = _primaryRouteAnimation;
    final secondaryRouteAnimation = _secondaryRouteAnimation;

    return (primaryRouteAnimation == null || primaryRouteAnimation.status == AnimationStatus.completed) &&
        (secondaryRouteAnimation == null || secondaryRouteAnimation.status == AnimationStatus.dismissed);
  }

  void _handleRouteAnimationStatus(AnimationStatus _) {
    if (_isRouteSettled) {
      Timer.run(() {
        if (mounted) _syncWheel(reset: false);
      });
      return;
    }

    _syncWheel(reset: false);
  }

  void _updateRouteAnimations() {
    final route = ModalRoute.of(context);
    final primaryRouteAnimation = route?.animation;
    final secondaryRouteAnimation = route?.secondaryAnimation;
    if (_primaryRouteAnimation == primaryRouteAnimation && _secondaryRouteAnimation == secondaryRouteAnimation) return;

    _primaryRouteAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _secondaryRouteAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _primaryRouteAnimation = primaryRouteAnimation;
    _secondaryRouteAnimation = secondaryRouteAnimation;
    _primaryRouteAnimation?.addStatusListener(_handleRouteAnimationStatus);
    _secondaryRouteAnimation?.addStatusListener(_handleRouteAnimationStatus);
  }

  void _updateAmountValues(String currencyCode) {
    _amountValues = _resolveAmountValues(currencyCode);
    _wheelController.duration = Duration(
      microseconds: FlexiblePaymentValuesWheel._amountStepDuration.inMicroseconds * (_amountValues?.length ?? 1),
    );
  }

  void _syncWheel({required bool reset}) {
    final shouldAnimate = _amountValues != null && !(_disableAnimations ?? true) && _isRouteSettled;
    if (!shouldAnimate) {
      _wheelController.stop();
      if (reset) _wheelController.value = 0;
      return;
    }

    if (reset) _wheelController.value = 0;
    if (_wheelController.isAnimating) return;
    _wheelController.repeat();
  }

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(duration: FlexiblePaymentValuesWheel._amountStepDuration, vsync: this);
    _updateAmountValues(ref.read(createJobStateProvider).currencyCode);
    ref.listenManual<String>(createJobStateProvider.select((data) => data.currencyCode), (_, currencyCode) {
      setState(() => _updateAmountValues(currencyCode));
      _syncWheel(reset: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateRouteAnimations();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final shouldReset = _disableAnimations != disableAnimations && disableAnimations;
    _disableAnimations = disableAnimations;
    _syncWheel(reset: shouldReset);
  }

  @override
  void dispose() {
    _primaryRouteAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _secondaryRouteAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountValues = _amountValues;
    if (amountValues == null) {
      return const SizedBox(height: FlexiblePaymentValuesWheel._height, width: double.infinity);
    }

    final i18n = ref.watch(translationProvider);
    final currency = ref.watch(
      createJobStateProvider.select((data) => (code: data.currencyCode, symbol: data.currencySymbol(i18n))),
    );
    final amountColors = _amountColors;
    final defaultTextStyle = DefaultTextStyle.of(context);
    var amountTextStyle = defaultTextStyle.style.merge(
      TextStyle(
        color: amountColors.centered,
        fontSize: FlexiblePaymentValuesWheel._fontSize,
        fontWeight: FontWeight.w600,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        height: 1,
      ),
    );
    if (MediaQuery.boldTextOf(context)) {
      amountTextStyle = amountTextStyle.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    amountTextStyle = amountTextStyle.merge(
      TextStyle(
        height: MediaQuery.maybeLineHeightScaleFactorOverrideOf(context),
        letterSpacing: MediaQuery.maybeLetterSpacingOverrideOf(context),
        wordSpacing: MediaQuery.maybeWordSpacingOverrideOf(context),
      ),
    );

    return SizedBox(
      key: const ValueKey('flexible_payment_values_wheel'),
      height: FlexiblePaymentValuesWheel._height,
      width: double.infinity,
      child: _FlexiblePaymentValuesWheelRenderer(
        key: const ValueKey('flexible_payment_values_wheel_renderer'),
        animation: _wheelController,
        amounts: [
          for (final amountValue in amountValues)
            i18n.createJob.payment.flexibleCarousel.amount(currencySymbol: currency.symbol, value: amountValue),
        ],
        semanticLabel: i18n.createJob.payment.flexibleCarousel.semanticLabel,
        adjacentColor: amountColors.adjacent,
        centeredColor: amountColors.centered,
        backgroundColor: context.mateo.colorScheme.background,
        devicePixelRatio: View.of(context).devicePixelRatio,
        locale: Localizations.localeOf(context),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        textStyle: amountTextStyle,
        textHeightBehavior: defaultTextStyle.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context),
        textWidthBasis: defaultTextStyle.textWidthBasis,
      ),
    );
  }
}
