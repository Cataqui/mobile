import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_contact_dto.freezed.dart';
part 'job_contact_dto.g.dart';

@freezed
abstract class JobContactDto with _$JobContactDto {
  const factory JobContactDto({
    @JsonKey(name: 'contact_method', unknownEnumValue: JobContactMethod.unknown)
    required JobContactMethod contactMethod,
    required String identifier,
  }) = _JobContactDto;

  factory JobContactDto.fromJson(Map<String, Object?> json) => _$JobContactDtoFromJson(json);

  factory JobContactDto.fixture() =>
      const JobContactDto(contactMethod: JobContactMethod.whatsapp, identifier: '+5511999999999');
}
