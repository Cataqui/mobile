import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_contact_reference_dto.freezed.dart';
part 'job_contact_reference_dto.g.dart';

@freezed
abstract class JobContactReferenceDto with _$JobContactReferenceDto {
  const factory JobContactReferenceDto({
    required String contactId,
    @JsonKey(unknownEnumValue: ContactMethod.unknown) required ContactMethod method,
  }) = _JobContactReferenceDto;

  factory JobContactReferenceDto.fromJson(Map<String, Object?> json) => _$JobContactReferenceDtoFromJson(json);

  factory JobContactReferenceDto.fixture() =>
      const JobContactReferenceDto(contactId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', method: .whatsapp);
}
