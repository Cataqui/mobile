import 'package:cataqui_app/core/dtos/auth_intent_exchange_result_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session_dto.freezed.dart';
part 'auth_session_dto.g.dart';

@freezed
abstract class AuthSessionDto with _$AuthSessionDto {
  const factory AuthSessionDto({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    required String refreshToken,
    required DateTime refreshTokenExpiresAt,
    required String userId,
  }) = _AuthSessionDto;

  factory AuthSessionDto.fromJson(Map<String, Object?> json) => _$AuthSessionDtoFromJson(json);

  factory AuthSessionDto.fromIssuedAuthSession(IssuedAuthSessionDto issuedSession) => AuthSessionDto(
    accessToken: issuedSession.accessToken,
    accessTokenExpiresAt: issuedSession.expiresAt,
    refreshToken: issuedSession.refreshToken,
    refreshTokenExpiresAt: issuedSession.refreshExpiresAt,
    userId: issuedSession.userId,
  );

  factory AuthSessionDto.fixture() => AuthSessionDto(
    accessToken: 'a' * 43,
    accessTokenExpiresAt: DateTime.parse('2026-08-10T15:15:00.000Z'),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.parse('2026-09-09T15:15:00.000Z'),
    userId: '4963fef0-b62a-4760-9f99-675fdc42a896',
  );
}
