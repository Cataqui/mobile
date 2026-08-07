import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'job_payment_dto.freezed.dart';
part 'job_payment_dto.g.dart';

@freezed
sealed class JobPaymentDto with _$JobPaymentDto {
  const factory JobPaymentDto({
    @JsonKey(unknownEnumValue: JobPaymentType.unknown) required JobPaymentType type,
    @JsonKey(unknownEnumValue: JobPaymentAmountPeriod.unknown) required JobPaymentAmountPeriod amountPeriod,
    required String currency,
    num? minAmount,
    num? maxAmount,
    @Default('') String note,
  }) = _JobPaymentDto;

  const JobPaymentDto._();

  factory JobPaymentDto.fromJson(Map<String, Object?> json) => _$JobPaymentDtoFromJson(json);

  factory JobPaymentDto.fixture() => const JobPaymentDto(
    type: JobPaymentType.fixed,
    minAmount: 120,
    maxAmount: 200,
    amountPeriod: JobPaymentAmountPeriod.single,
    currency: 'BRL',
    note: '',
  );

  String formatPayment(Translations t) {
    return switch (type) {
      JobPaymentType.fixed => _formatFixed(t),
      JobPaymentType.range => _formatRange(t),
      JobPaymentType.flexible => t.jobPayment.paymentFlexible,
      JobPaymentType.other => t.jobPayment.paymentOther,
      JobPaymentType.unknown => t.jobPayment.paymentUnknown,
    };
  }

  String _formatFixed(Translations t) {
    final localeTag = t.$meta.locale.underscoreTag;
    final hasDecimals = minAmount != minAmount!.toInt();
    final decimals = hasDecimals ? 2 : 0;
    final formatter = NumberFormat.simpleCurrency(name: currency, locale: localeTag, decimalDigits: decimals);
    final formattedAmount = formatter.format(minAmount).replaceAll(RegExp(r'\s'), '');
    final suffix = _periodSuffix(t);
    return t.jobPayment.paymentFixed(value: formattedAmount, period: suffix);
  }

  String _formatRange(Translations t) {
    final localeTag = t.$meta.locale.underscoreTag;
    final hasDecimals = maxAmount != maxAmount!.toInt();
    final decimals = hasDecimals ? 2 : 0;
    final formatter = NumberFormat.simpleCurrency(name: currency, locale: localeTag, decimalDigits: decimals);
    final formattedAmount = formatter.format(maxAmount).replaceAll(RegExp(r'\s'), '');
    final suffix = _periodSuffix(t);
    return t.jobPayment.paymentRangeUpTo(value: formattedAmount, period: suffix);
  }

  String _periodSuffix(Translations t) {
    return switch (amountPeriod) {
      JobPaymentAmountPeriod.single => '',
      JobPaymentAmountPeriod.hourly => t.jobPayment.paymentPeriodHourly,
      JobPaymentAmountPeriod.daily => t.jobPayment.paymentPeriodDaily,
      JobPaymentAmountPeriod.weekly => t.jobPayment.paymentPeriodWeekly,
      JobPaymentAmountPeriod.monthly => t.jobPayment.paymentPeriodMonthly,
      JobPaymentAmountPeriod.yearly => t.jobPayment.paymentPeriodYearly,
      JobPaymentAmountPeriod.unknown => '',
    };
  }
}
