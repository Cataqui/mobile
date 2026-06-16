import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:cataqui_app/i18n/strings.g.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'job_payment_dto.freezed.dart';
part 'job_payment_dto.g.dart';

@freezed
sealed class JobPaymentDto with _$JobPaymentDto {
  const factory JobPaymentDto({
    @JsonKey(unknownEnumValue: JobPaymentType.unknown) required JobPaymentType type,
    @JsonKey(name: 'min_amount') required num minAmount,
    @JsonKey(name: 'amount_period', unknownEnumValue: JobPaymentAmountPeriod.unknown)
    required JobPaymentAmountPeriod amountPeriod,
    required String currency,
  }) = _JobPaymentDto;

  const JobPaymentDto._();

  factory JobPaymentDto.fromJson(Map<String, Object?> json) => _$JobPaymentDtoFromJson(json);

  factory JobPaymentDto.fixture() => const JobPaymentDto(
    type: JobPaymentType.fixed,
    minAmount: 120,
    amountPeriod: JobPaymentAmountPeriod.single,
    currency: 'BRL',
  );

  String formatPayment(Translations t) {
    if (type == JobPaymentType.flexible) return t.jobPayment.paymentFlexible;

    final localeTag = t.$meta.locale.underscoreTag;
    final decimals = minAmount == minAmount.toInt() ? 0 : 2;
    final formatter = NumberFormat.simpleCurrency(name: currency, locale: localeTag, decimalDigits: decimals);
    final formattedAmount = formatter.format(minAmount);
    final suffix = _periodSuffix(t);

    return switch (type) {
      JobPaymentType.fixed => '$formattedAmount$suffix',
      JobPaymentType.range => '$formattedAmount+$suffix',
      JobPaymentType.other || JobPaymentType.unknown => formattedAmount,
      JobPaymentType.flexible => t.jobPayment.paymentFlexible,
    };
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
