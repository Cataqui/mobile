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
    @JsonKey(name: 'max_amount') required num maxAmount,
    @JsonKey(name: 'amount_period', unknownEnumValue: JobPaymentAmountPeriod.unknown)
    required JobPaymentAmountPeriod amountPeriod,
    required String currency,
    @JsonKey(name: 'note') @Default('') String note,
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
    if (type == JobPaymentType.flexible) return t.jobPayment.paymentFlexible;

    final localeTag = t.$meta.locale.underscoreTag;
    final hasDecimals = minAmount != minAmount.toInt() || maxAmount != maxAmount.toInt();
    final decimals = hasDecimals ? 2 : 0;
    final formatter = NumberFormat.simpleCurrency(name: currency, locale: localeTag, decimalDigits: decimals);
    final formattedMinAmount = formatter.format(minAmount).replaceAll(RegExp(r'\s'), '');
    final formattedMaxAmount = formatter.format(maxAmount).replaceAll(RegExp(r'\s'), '');
    final suffix = _periodSuffix(t);

    return switch (type) {
      JobPaymentType.fixed => t.jobPayment.paymentFixed(value: formattedMinAmount, period: suffix),
      JobPaymentType.range => t.jobPayment.paymentRangeUpTo(value: formattedMaxAmount, period: suffix),
      JobPaymentType.other || JobPaymentType.unknown => formattedMinAmount,
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
