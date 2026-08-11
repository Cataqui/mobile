import 'package:freezed_annotation/freezed_annotation.dart';

part 'registered_auth_intent_dto.freezed.dart';
part 'registered_auth_intent_dto.g.dart';

@freezed
abstract class RegisteredAuthIntentDto with _$RegisteredAuthIntentDto {
  const factory RegisteredAuthIntentDto({
    required String intentToken,
    required String code,
    required String codeReceiver,
    required DateTime expiresAt,
  }) = _RegisteredAuthIntentDto;

  factory RegisteredAuthIntentDto.fromJson(Map<String, Object?> json) => _$RegisteredAuthIntentDtoFromJson(json);

  factory RegisteredAuthIntentDto.fixture() => RegisteredAuthIntentDto(
    intentToken: 'kJ3YFf0SYkZp6gWlMTq3up5ELXWRw_zTuF8j0M5tJgI',
    code: 'AUTH-K7F9Q2M8VD',
    codeReceiver: '+5511999999999',
    expiresAt: DateTime.parse('2026-08-10T15:15:00.000Z'),
  );
}
