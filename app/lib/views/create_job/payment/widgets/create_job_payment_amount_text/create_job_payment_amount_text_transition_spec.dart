part of 'create_job_payment_amount_text.dart';

class _CreateJobPaymentAmountTextTransitionSpec {
  const _CreateJobPaymentAmountTextTransitionSpec._();

  static String digitsOf(String text) => text.replaceAll(_nonDigitPattern, '');

  static bool isDigit(String character) => !_nonDigitPattern.hasMatch(character);

  static final RegExp _nonDigitPattern = RegExp(r'\D');
}
