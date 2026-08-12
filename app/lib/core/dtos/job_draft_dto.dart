import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_draft_dto.freezed.dart';
part 'job_draft_dto.g.dart';

@freezed
abstract class JobDraftDto with _$JobDraftDto {
  const factory JobDraftDto({
    required String jobId,
    required String description,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? title,
    String? descriptionSummary,
    JobContactReferenceDto? contactReference,
    JobLocationDto? location,
    JobPaymentDto? payment,
    @JsonKey(unknownEnumValue: JobType.unknown) JobType? type,
  }) = _JobDraftDto;

  factory JobDraftDto.fromJson(Map<String, Object?> json) => _$JobDraftDtoFromJson(json);

  factory JobDraftDto.fixture() => JobDraftDto(
    jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    description: 'Preciso de uma pessoa para ajudar a descarregar caixas.',
    status: JobStatus.draft,
    createdAt: DateTime.parse('2026-08-12T12:00:00.000Z'),
    updatedAt: DateTime.parse('2026-08-12T12:00:00.000Z'),
  );
}
