import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_contact_dto.freezed.dart';
part 'job_contact_dto.g.dart';

@freezed
abstract class JobContactDto with _$JobContactDto {
  const factory JobContactDto({
    required String name,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'contact_method', unknownEnumValue: JobContactMethod.unknown)
    required JobContactMethod contactMethod,
  }) = _JobContactDto;

  factory JobContactDto.fromJson(Map<String, Object?> json) =>
      _$JobContactDtoFromJson(json);
}
