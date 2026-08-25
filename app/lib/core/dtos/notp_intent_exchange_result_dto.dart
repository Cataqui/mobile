import 'package:freezed_annotation/freezed_annotation.dart';

part 'notp_intent_exchange_result_dto.freezed.dart';
part 'notp_intent_exchange_result_dto.g.dart';

@freezed
sealed class NotpIntentExchangeResultDto with _$NotpIntentExchangeResultDto {
  const factory NotpIntentExchangeResultDto.pending({required int retryAfterSeconds}) = PendingNotpIntentExchangeDto;

  const factory NotpIntentExchangeResultDto.issuedSession({
    required String accessToken,
    required String tokenType,
    required DateTime expiresAt,
    required String refreshToken,
    required DateTime refreshExpiresAt,
    required String userId,
  }) = IssuedAuthSessionDto;

  factory NotpIntentExchangeResultDto.fromJson(Map<String, Object?> json) =>
      _$NotpIntentExchangeResultDtoFromJson(json);

  factory NotpIntentExchangeResultDto.fromApiJson(Map<String, Object?> json) {
    final runtimeType = switch (json['status']) {
      'PENDING' => 'pending',
      null => 'issuedSession',
      final unsupportedStatus => throw FormatException('Unsupported NOTP intent exchange status: $unsupportedStatus'),
    };

    return NotpIntentExchangeResultDto.fromJson(<String, Object?>{...json, 'runtimeType': runtimeType});
  }

  factory NotpIntentExchangeResultDto.pendingFixture() {
    return const NotpIntentExchangeResultDto.pending(retryAfterSeconds: 1);
  }

  factory NotpIntentExchangeResultDto.issuedSessionFixture() => NotpIntentExchangeResultDto.issuedSession(
    accessToken: 'a' * 43,
    tokenType: 'Bearer',
    expiresAt: DateTime.parse('2026-08-10T15:15:00.000Z'),
    refreshToken: 'refresh-token',
    refreshExpiresAt: DateTime.parse('2026-09-09T15:15:00.000Z'),
    userId: '4963fef0-b62a-4760-9f99-675fdc42a896',
  );
}
