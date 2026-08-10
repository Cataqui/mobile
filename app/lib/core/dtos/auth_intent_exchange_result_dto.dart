import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_intent_exchange_result_dto.freezed.dart';
part 'auth_intent_exchange_result_dto.g.dart';

@freezed
sealed class AuthIntentExchangeResultDto with _$AuthIntentExchangeResultDto {
  const factory AuthIntentExchangeResultDto.pending({required int retryAfterSeconds}) = PendingAuthIntentExchangeDto;

  const factory AuthIntentExchangeResultDto.issuedSession({
    required String accessToken,
    required String tokenType,
    required DateTime expiresAt,
    required String refreshToken,
    required DateTime refreshExpiresAt,
    required String userId,
  }) = IssuedAuthSessionDto;

  factory AuthIntentExchangeResultDto.fromJson(Map<String, Object?> json) =>
      _$AuthIntentExchangeResultDtoFromJson(json);

  factory AuthIntentExchangeResultDto.fromApiJson(Map<String, Object?> json) {
    final runtimeType = switch (json['status']) {
      'PENDING' => 'pending',
      null => 'issuedSession',
      final unsupportedStatus => throw FormatException('Unsupported auth intent exchange status: $unsupportedStatus'),
    };

    return AuthIntentExchangeResultDto.fromJson(<String, Object?>{...json, 'runtimeType': runtimeType});
  }

  factory AuthIntentExchangeResultDto.pendingFixture() {
    return const AuthIntentExchangeResultDto.pending(retryAfterSeconds: 1);
  }

  factory AuthIntentExchangeResultDto.issuedSessionFixture() => AuthIntentExchangeResultDto.issuedSession(
    accessToken: 'a' * 43,
    tokenType: 'Bearer',
    expiresAt: DateTime.parse('2026-08-10T15:15:00.000Z'),
    refreshToken: 'refresh-token',
    refreshExpiresAt: DateTime.parse('2026-09-09T15:15:00.000Z'),
    userId: '4963fef0-b62a-4760-9f99-675fdc42a896',
  );
}
