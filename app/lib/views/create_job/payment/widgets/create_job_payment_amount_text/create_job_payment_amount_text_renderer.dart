part of 'create_job_payment_amount_text.dart';

class _CreateJobPaymentAmountTextRenderer extends LeafRenderObjectWidget {
  const _CreateJobPaymentAmountTextRenderer({
    required this.amountText,
    required this.amount,
    required this.semanticLabel,
    required this.semanticSelected,
    required this.alignment,
    required this.animate,
    required this.devicePixelRatio,
    required this.edgeFadeColor,
    required this.locale,
    required this.textDirection,
    required this.textScaler,
    required this.textStyle,
    required this.vsync,
    super.key,
  });

  final String amountText;
  final String amount;
  final String? semanticLabel;
  final bool? semanticSelected;
  final Alignment alignment;
  final bool animate;
  final double devicePixelRatio;
  final Color edgeFadeColor;
  final Locale locale;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextStyle textStyle;
  final TickerProvider vsync;

  @override
  _RenderCreateJobPaymentAmountText createRenderObject(BuildContext context) {
    return _RenderCreateJobPaymentAmountText(
      initialAmountText: amountText,
      initialAmount: amount,
      initialSemanticLabel: semanticLabel,
      initialSemanticSelected: semanticSelected,
      initialAlignment: alignment,
      initialDevicePixelRatio: devicePixelRatio,
      initialEdgeFadeColor: edgeFadeColor,
      initialLocale: locale,
      initialTextDirection: textDirection,
      initialTextScaler: textScaler,
      initialTextStyle: textStyle,
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCreateJobPaymentAmountText renderObject) {
    renderObject.updateConfiguration(
      amountText: amountText,
      amount: amount,
      semanticLabel: semanticLabel,
      semanticSelected: semanticSelected,
      alignment: alignment,
      animate: animate,
      devicePixelRatio: devicePixelRatio,
      edgeFadeColor: edgeFadeColor,
      locale: locale,
      textDirection: textDirection,
      textScaler: textScaler,
      textStyle: textStyle,
    );
  }
}
