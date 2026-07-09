import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_contact_reference_dto.freezed.dart';
part 'job_contact_reference_dto.g.dart';

@freezed
abstract class JobContactReferenceDto with _$JobContactReferenceDto {
  const factory JobContactReferenceDto({
    @JsonKey(name: 'contact_id') required String contactId,
    @JsonKey(name: 'contact_method', unknownEnumValue: JobContactMethod.unknown)
    required JobContactMethod contactMethod,
  }) = _JobContactReferenceDto;

  factory JobContactReferenceDto.fromJson(Map<String, Object?> json) =>
      _$JobContactReferenceDtoFromJson(json);

  factory JobContactReferenceDto.fixture() =>
      const JobContactReferenceDto(contactId: 'cm3x-contact-1', contactMethod: JobContactMethod.whatsapp);
}
