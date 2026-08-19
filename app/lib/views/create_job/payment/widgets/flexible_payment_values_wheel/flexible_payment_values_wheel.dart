import 'dart:async';
import 'dart:math' as math;

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

part 'flexible_payment_values_wheel_amount_values.dart';

class FlexiblePaymentValuesWheel extends ConsumerStatefulWidget {
  const FlexiblePaymentValuesWheel({super.key});

  static const _amountStepDuration = Duration(milliseconds: 2000);
  static const _height = 200.0;
  static const _fontSize = 46.0;
  static const _adjacentAmountScale = 0.6;
  static const _stepMotionStrength = 0.35;

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

  double _resolveStepMotion(double stepProgress) {
    return stepProgress -
        FlexiblePaymentValuesWheel._stepMotionStrength * math.sin(stepProgress * math.pi * 2) / (math.pi * 2);
  }

  double _resolveCenteredAmountProgress(double distanceFromCenter) {
    final normalizedDistance = math.min(distanceFromCenter, 1);

    return (1 + math.cos(normalizedDistance * math.pi)) / 2;
  }

  double _resolveAmountScale(double centeredAmountProgress) {
    return FlexiblePaymentValuesWheel._adjacentAmountScale +
        centeredAmountProgress * (1 - FlexiblePaymentValuesWheel._adjacentAmountScale);
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
    const slotExtent = FlexiblePaymentValuesWheel._height / 4;

    return SizedBox(
      key: const ValueKey('flexible_payment_values_wheel'),
      height: FlexiblePaymentValuesWheel._height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final physicalPixel = 1 / View.of(context).devicePixelRatio;
          const adjacentAmountHalfHeight =
              FlexiblePaymentValuesWheel._fontSize * FlexiblePaymentValuesWheel._adjacentAmountScale / 2;
          final transparentEdgeExtent = adjacentAmountHalfHeight + physicalPixel;
          final opaqueCenterStart = slotExtent - adjacentAmountHalfHeight - physicalPixel;
          final edgeMaskColor = context.mateo.colorScheme.background;
          final edgeMaskGradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              edgeMaskColor.withValues(alpha: 0),
              edgeMaskColor.withValues(alpha: 0),
              edgeMaskColor,
              edgeMaskColor,
              edgeMaskColor.withValues(alpha: 0),
              edgeMaskColor.withValues(alpha: 0),
            ],
            stops: [
              0,
              transparentEdgeExtent / FlexiblePaymentValuesWheel._height,
              opaqueCenterStart / FlexiblePaymentValuesWheel._height,
              1 - opaqueCenterStart / FlexiblePaymentValuesWheel._height,
              1 - transparentEdgeExtent / FlexiblePaymentValuesWheel._height,
              1,
            ],
          );
          final amountWidgets = <Widget>[
            for (final amountValue in amountValues)
              SizedBox(
                width: math.max(0, constraints.maxWidth - 40).toDouble(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    i18n.createJob.payment.flexibleCarousel.amount(currencySymbol: currency.symbol, value: amountValue),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: FlexiblePaymentValuesWheel._fontSize,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      height: 1,
                    ),
                  ),
                ),
              ),
          ];

          return Semantics(
            container: true,
            label: i18n.createJob.payment.flexibleCarousel.semanticLabel,
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _wheelController,
                    builder: (context, child) {
                      final amountSequenceProgress = _wheelController.value * amountValues.length;
                      final centeredAmountIndex = amountSequenceProgress.floor() % amountValues.length;
                      final stepProgress = amountSequenceProgress - amountSequenceProgress.floor();
                      final stepMotion = _resolveStepMotion(stepProgress);
                      final amountColors = _amountColors;

                      return ShaderMask(
                        key: const ValueKey('flexible_payment_values_wheel_edge_mask'),
                        blendMode: BlendMode.dstIn,
                        shaderCallback: edgeMaskGradient.createShader,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            for (var relativeIndex = -1; relativeIndex <= (stepMotion == 0 ? 1 : 2); relativeIndex += 1)
                              Align(
                                alignment: Alignment.center,
                                child: Transform.translate(
                                  offset: Offset(0, (relativeIndex - stepMotion) * slotExtent),
                                  child: Builder(
                                    builder: (context) {
                                      final centeredAmountProgress = _resolveCenteredAmountProgress(
                                        (relativeIndex - stepMotion).abs(),
                                      );

                                      return Transform.scale(
                                        scale: _resolveAmountScale(centeredAmountProgress),
                                        child: DefaultTextStyle.merge(
                                          style: TextStyle(
                                            color: Color.lerp(
                                              amountColors.adjacent,
                                              amountColors.centered,
                                              centeredAmountProgress,
                                            ),
                                          ),
                                          child: KeyedSubtree(
                                            key: ValueKey<Object>((
                                              'flexible_payment_values_wheel_amount',
                                              relativeIndex,
                                            )),
                                            child:
                                                amountWidgets[(centeredAmountIndex + relativeIndex) %
                                                    amountValues.length],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
