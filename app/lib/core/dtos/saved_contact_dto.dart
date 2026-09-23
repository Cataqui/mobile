import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_contact_dto.freezed.dart';
part 'saved_contact_dto.g.dart';

@freezed
abstract class SavedContactDto with _$SavedContactDto {
  const factory SavedContactDto({
    required String contactId,
    @JsonKey(name: 'method', unknownEnumValue: JobContactMethod.unknown) required JobContactMethod contactMethod,
    required String identifier,
  }) = _SavedContactDto;

  factory SavedContactDto.fromJson(Map<String, Object?> json) => _$SavedContactDtoFromJson(json);

  factory SavedContactDto.fixture() => const SavedContactDto(
    contactId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    contactMethod: JobContactMethod.whatsapp,
    identifier: '+5511999999999',
  );
}
