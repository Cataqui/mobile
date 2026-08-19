part of 'flexible_payment_values_wheel.dart';

extension on _FlexiblePaymentValuesWheelState {
  List<int>? _resolveAmountValues(String currencyCode) {
    final amountValues = switch (currencyCode) {
      'BRL' => const <int>[350, 85, 430, 200, 720, 152, 530, 1200],
      _ => null,
    };
    if (amountValues != null) return amountValues;

    debugPrint('FlexiblePaymentValuesWheel does not have amount values for currency code "$currencyCode".');
    return null;
  }
}
