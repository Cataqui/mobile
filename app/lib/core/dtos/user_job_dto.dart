import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_location_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_job_dto.freezed.dart';
part 'user_job_dto.g.dart';

@freezed
abstract class UserJobDto with _$UserJobDto {
  const factory UserJobDto({
    required String jobId,
    required String description,
    required JobContactDto? contact,
    required UserJobLocationDto location,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserJobDto;

  factory UserJobDto.fromJson(Map<String, Object?> json) => _$UserJobDtoFromJson(json);

  factory UserJobDto.fixture() => UserJobDto(
    jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    description: 'Ajudar a descarregar caixas durante a tarde.',
    contact: JobContactDto.fixture(),
    location: UserJobLocationDto.fixture(),
    status: JobStatus.active,
    createdAt: DateTime.parse('2026-09-22T12:00:00.000Z'),
    updatedAt: DateTime.parse('2026-09-22T12:00:00.000Z'),
  );
}
