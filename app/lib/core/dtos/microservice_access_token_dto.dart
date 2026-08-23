import 'package:cataqui_app/core/enums/microservice_access_token_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'microservice_access_token_dto.freezed.dart';
part 'microservice_access_token_dto.g.dart';

@freezed
abstract class MicroserviceAccessTokenDto with _$MicroserviceAccessTokenDto {
  const factory MicroserviceAccessTokenDto({
    @JsonKey(required: true) required String accessToken,
    @JsonKey(required: true) required DateTime expiresAt,
    @JsonKey(required: true) required MicroserviceAccessTokenType tokenType,
  }) = _MicroserviceAccessTokenDto;

  factory MicroserviceAccessTokenDto.fromJson(Map<String, Object?> json) => _$MicroserviceAccessTokenDtoFromJson(json);
}
