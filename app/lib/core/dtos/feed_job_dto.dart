import 'package:cataqui_app/core/dtos/feed_job_location_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_job_dto.freezed.dart';
part 'feed_job_dto.g.dart';

@freezed
abstract class FeedJobDto with _$FeedJobDto {
  const factory FeedJobDto({
    required String jobId,
    required String title,
    required DateTime createdAt,
    required String? payment,
    required FeedJobLocationDto location,
    required String descriptionSummary,
  }) = _FeedJobDto;

  const FeedJobDto._();

  factory FeedJobDto.fromJson(Map<String, Object?> json) => _$FeedJobDtoFromJson(json);

  factory FeedJobDto.fromJob(JobDto job) => FeedJobDto(
    jobId: job.jobId,
    title: job.title,
    createdAt: job.createdAt,
    payment: job.payment,
    location: FeedJobLocationDto(
      latitude: job.location.latitude,
      longitude: job.location.longitude,
      areaRadius: job.location.areaRadius,
    ),
    descriptionSummary: job.descriptionSummary,
  );

  factory FeedJobDto.fixture() => FeedJobDto(
    jobId: 'job_123',
    title: 'Descarregar Caminhão',
    createdAt: DateTime(2025, 6, 15),
    payment: 'Outro pagamento',
    location: const FeedJobLocationDto(latitude: -23.5505, longitude: -46.6333, areaRadius: 2000),
    descriptionSummary: 'Experiente em atendimento ao cliente, disponibilidade para finais de semana e feriados.',
  );
}
