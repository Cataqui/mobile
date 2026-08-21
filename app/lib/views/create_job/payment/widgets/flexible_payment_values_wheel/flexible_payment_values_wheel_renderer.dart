part of 'flexible_payment_values_wheel.dart';

class _FlexiblePaymentValuesWheelRenderer extends LeafRenderObjectWidget {
  const _FlexiblePaymentValuesWheelRenderer({
    required this.animation,
    required this.amounts,
    required this.semanticLabel,
    required this.adjacentColor,
    required this.centeredColor,
    required this.backgroundColor,
    required this.devicePixelRatio,
    required this.locale,
    required this.textDirection,
    required this.textScaler,
    required this.textStyle,
    required this.textHeightBehavior,
    required this.textWidthBasis,
    super.key,
  });

  final Animation<double> animation;
  final List<String> amounts;
  final String semanticLabel;
  final Color adjacentColor;
  final Color centeredColor;
  final Color backgroundColor;
  final double devicePixelRatio;
  final Locale locale;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextStyle textStyle;
  final ui.TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;

  @override
  FlexiblePaymentValuesWheelRenderBox createRenderObject(BuildContext context) {
    return FlexiblePaymentValuesWheelRenderBox(
      initialAnimation: animation,
      initialAmounts: amounts,
      initialSemanticLabel: semanticLabel,
      initialAdjacentColor: adjacentColor,
      initialCenteredColor: centeredColor,
      initialBackgroundColor: backgroundColor,
      initialDevicePixelRatio: devicePixelRatio,
      initialLocale: locale,
      initialTextDirection: textDirection,
      initialTextScaler: textScaler,
      initialTextStyle: textStyle,
      initialTextHeightBehavior: textHeightBehavior,
      initialTextWidthBasis: textWidthBasis,
    );
  }

  @override
  void updateRenderObject(BuildContext context, FlexiblePaymentValuesWheelRenderBox renderObject) {
    renderObject.updateConfiguration(
      animation: animation,
      amounts: amounts,
      semanticLabel: semanticLabel,
      adjacentColor: adjacentColor,
      centeredColor: centeredColor,
      backgroundColor: backgroundColor,
      devicePixelRatio: devicePixelRatio,
      locale: locale,
      textDirection: textDirection,
      textScaler: textScaler,
      textStyle: textStyle,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
    );
  }
}
