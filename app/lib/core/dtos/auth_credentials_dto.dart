import 'dart:convert';

import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_credentials_dto.freezed.dart';
part 'auth_credentials_dto.g.dart';

@freezed
abstract class AuthCredentialsDto with _$AuthCredentialsDto {
  const factory AuthCredentialsDto({required String refreshToken, required DateTime refreshTokenExpiresAt}) =
      _AuthCredentialsDto;

  const AuthCredentialsDto._();

  factory AuthCredentialsDto.fromJson(Map<String, Object?> json) => _$AuthCredentialsDtoFromJson(json);

  factory AuthCredentialsDto.fromSecureStorageValue(String value) {
    final Object? decodedValue = jsonDecode(value);

    if (decodedValue is! Map<String, Object?>) {
      throw const FormatException('Stored authentication credentials must be a JSON object.');
    }

    return AuthCredentialsDto.fromJson(decodedValue);
  }

  factory AuthCredentialsDto.fromAuthSession(AuthSessionDto session) {
    return AuthCredentialsDto(refreshToken: session.refreshToken, refreshTokenExpiresAt: session.refreshTokenExpiresAt);
  }

  factory AuthCredentialsDto.fixture() => AuthCredentialsDto(
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.parse('2026-09-09T15:15:00.000Z'),
  );

  String toSecureStorageValue() => jsonEncode(toJson());
}
