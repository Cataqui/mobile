import 'package:cataqui_app/core/dtos/job_contact_reference_dto.dart';
import 'package:cataqui_app/core/dtos/job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_dto.freezed.dart';
part 'job_dto.g.dart';

@freezed
abstract class JobDto with _$JobDto {
  const factory JobDto({
    required String jobId,
    required String title,
    required String description,
    required String descriptionSummary,
    required JobContactReferenceDto contactReference,
    required JobLocationDto location,
    required JobPaymentDto payment,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,
    @JsonKey(unknownEnumValue: JobType.unknown) required JobType type,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _JobDto;

  factory JobDto.fromJson(Map<String, Object?> json) => _$JobDtoFromJson(json);

  factory JobDto.fixture() => JobDto(
    jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    title: 'Mock: ajudante para descarregar caminhão',
    description:
        'Mock job for staging QA. Need one person to help unload '
        'boxes from a small truck for about two hours near Centro. This is test '
        'data and should not be treated as a real opportunity.',
    descriptionSummary: 'Trabalho rápido para ajudar a descarregar caixas no Centro.',
    contactReference: const JobContactReferenceDto(
      contactId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      contactMethod: JobContactMethod.whatsapp,
    ),
    location: const JobLocationDto(
      neighborhood: 'Centro',
      city: 'São Paulo',
      state: 'SP',
      country: 'BR',
      latitude: -23.556391,
      longitude: -46.844076,
      areaRadius: 2000,
    ),
    payment: const JobPaymentDto(
      type: JobPaymentType.fixed,
      minAmount: 120,
      maxAmount: 200,
      amountPeriod: JobPaymentAmountPeriod.single,
      currency: 'BRL',
      note: '',
    ),
    status: JobStatus.active,
    type: JobType.individual,
    createdAt: DateTime.parse('2026-06-06T00:36:46.623Z'),
    updatedAt: DateTime.parse('2026-06-06T00:36:46.623Z'),
  );
}
