import 'package:cataqui_app/core/dtos/fuzzy_job_location_dto.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_job_summary_dto.freezed.dart';
part 'user_job_summary_dto.g.dart';

@freezed
abstract class UserJobSummaryDto with _$UserJobSummaryDto {
  const factory UserJobSummaryDto({
    required String jobId,
    required String title,
    required String descriptionSummary,
    required String? payment,
    required FuzzyJobLocationDto location,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserJobSummaryDto;

  factory UserJobSummaryDto.fromJson(Map<String, Object?> json) => _$UserJobSummaryDtoFromJson(json);

  factory UserJobSummaryDto.fixture() => UserJobSummaryDto(
    jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    title: 'Ajuda para descarregar caixas',
    descriptionSummary: 'Trabalho rápido para ajudar a descarregar caixas no Centro.',
    payment: r'R$120',
    location: FuzzyJobLocationDto.fixture(),
    status: .active,
    createdAt: DateTime.parse('2026-09-22T12:00:00.000Z'),
    updatedAt: DateTime.parse('2026-09-22T12:00:00.000Z'),
  );
}
