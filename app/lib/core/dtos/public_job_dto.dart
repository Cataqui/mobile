import 'package:cataqui_app/core/dtos/fuzzy_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_job_dto.freezed.dart';
part 'public_job_dto.g.dart';

@freezed
abstract class PublicJobDto with _$PublicJobDto {
  const factory PublicJobDto({
    required String jobId,
    required String title,
    required String description,
    required String descriptionSummary,
    required JobContactReferenceDto contactReference,
    required FuzzyJobLocationDto location,
    required String? payment,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PublicJobDto;

  factory PublicJobDto.fromJson(Map<String, Object?> json) => _$PublicJobDtoFromJson(json);

  factory PublicJobDto.fixture() => PublicJobDto(
    jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    title: 'Mock: ajudante para descarregar caminhão',
    description:
        'Mock job for staging QA. Need one person to help unload '
        'boxes from a small truck for about two hours near Centro. This is test '
        'data and should not be treated as a real opportunity.',
    descriptionSummary: 'Trabalho rápido para ajudar a descarregar caixas no Centro.',
    contactReference: const JobContactReferenceDto(
      contactId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      method: .whatsapp,
    ),
    location: const FuzzyJobLocationDto(
      latitude: -23.556391,
      longitude: -46.844076,
      areaRadius: 2000,
      imageUrl: 'https://maps.cataqui.com/static/fixture',
    ),
    payment: r'R$120',
    status: .active,
    createdAt: DateTime.parse('2026-06-06T00:36:46.623Z'),
    updatedAt: DateTime.parse('2026-06-06T00:36:46.623Z'),
  );
}
