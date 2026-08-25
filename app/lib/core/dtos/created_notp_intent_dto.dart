import 'package:freezed_annotation/freezed_annotation.dart';

part 'created_notp_intent_dto.freezed.dart';
part 'created_notp_intent_dto.g.dart';

@freezed
abstract class CreatedNotpIntentDto with _$CreatedNotpIntentDto {
  const factory CreatedNotpIntentDto({
    required String intentToken,
    required String code,
    required String codeReceiver,
    required DateTime expiresAt,
  }) = _CreatedNotpIntentDto;

  factory CreatedNotpIntentDto.fromJson(Map<String, Object?> json) => _$CreatedNotpIntentDtoFromJson(json);

  factory CreatedNotpIntentDto.fixture() => CreatedNotpIntentDto(
    intentToken: 'kJ3YFf0SYkZp6gWlMTq3up5ELXWRw_zTuF8j0M5tJgI',
    code: 'NOTP-K7F9Q2M8VD',
    codeReceiver: '+5511999999999',
    expiresAt: DateTime.parse('2026-08-10T15:15:00.000Z'),
  );
}
