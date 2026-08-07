import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_envelope_dto.freezed.dart';
part 'api_envelope_dto.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiEnvelopeDto<T> with _$ApiEnvelopeDto<T> {
  const factory ApiEnvelopeDto({
    required T data,
    required String requestId,
    required DateTime timestamp,
    required String endpoint,
    ApiPaginationDto? pagination,
  }) = _ApiEnvelopeDto<T>;

  factory ApiEnvelopeDto.fromJson(Map<String, Object?> json, T Function(Object?) fromJsonT) =>
      _$ApiEnvelopeDtoFromJson(json, fromJsonT);

  factory ApiEnvelopeDto.fixture({required T data}) => ApiEnvelopeDto<T>(
    data: data,
    requestId: 'req-fixture',
    timestamp: DateTime.parse('2026-06-06T00:37:46.623Z'),
    endpoint: '/fixture',
  );
}
