import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:cataqui_app/core/dtos/job_payment_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_job_dto.freezed.dart';
part 'feed_job_dto.g.dart';

@freezed
abstract class FeedJobDto with _$FeedJobDto {
  const factory FeedJobDto({
    @JsonKey(name: 'job_id') required String jobId,
    required String title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required JobPaymentDto payment,
    required FeedJobLocationDto location,
    @JsonKey(name: 'description_summary') required String descriptionSummary,
  }) = _FeedJobDto;

  factory FeedJobDto.fromJson(Map<String, Object?> json) => _$FeedJobDtoFromJson(json);

  // Freezed-generated classes cannot have custom constructors,
  // so a static factory method is the only option.
  // ignore: prefer_constructors_over_static_methods
  factory FeedJobDto.fixture() => FeedJobDto(
    jobId: 'job_123',
    title: 'Descarregar Caminhão',
    createdAt: DateTime(2025, 6, 15),
    payment: const JobPaymentDto(
      type: JobPaymentType.other,
      minAmount: 120,
      amountPeriod: JobPaymentAmountPeriod.hourly,
      currency: 'USD',
    ),
    location: const FeedJobLocationDto(
      neighborhood: 'Pinheiros',
      latitude: -23.556391,
      longitude: -46.844076,
      areaRadius: 2000,
    ),
    descriptionSummary: 'Experiente em atendimento ao cliente, disponibilidade para finais de semana e feriados.',
  );
}
