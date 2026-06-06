import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_pagination_dto.freezed.dart';
part 'api_pagination_dto.g.dart';

@freezed
abstract class ApiPaginationDto with _$ApiPaginationDto {
  const factory ApiPaginationDto({
    @JsonKey(name: 'has_more') required bool hasMore,
    @JsonKey(name: 'next_cursor') String? nextCursor,
  }) = _ApiPaginationDto;

  factory ApiPaginationDto.fromJson(Map<String, Object?> json) =>
      _$ApiPaginationDtoFromJson(json);
}
