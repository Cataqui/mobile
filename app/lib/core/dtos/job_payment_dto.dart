import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_payment_dto.freezed.dart';
part 'job_payment_dto.g.dart';

@freezed
abstract class JobPaymentDto with _$JobPaymentDto {
  const factory JobPaymentDto({
    @JsonKey(unknownEnumValue: JobPaymentType.unknown)
    required JobPaymentType type,
    @JsonKey(name: 'min_amount') required num minAmount,
    @JsonKey(
      name: 'amount_period',
      unknownEnumValue: JobPaymentAmountPeriod.unknown,
    )
    required JobPaymentAmountPeriod amountPeriod,
    required String currency,
  }) = _JobPaymentDto;

  factory JobPaymentDto.fromJson(Map<String, Object?> json) =>
      _$JobPaymentDtoFromJson(json);
}
