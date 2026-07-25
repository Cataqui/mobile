import 'package:freezed_annotation/freezed_annotation.dart';

part 'localized_store_release_note_dto.freezed.dart';
part 'localized_store_release_note_dto.g.dart';

@freezed
abstract class LocalizedStoreReleaseNoteDto with _$LocalizedStoreReleaseNoteDto {
  const factory LocalizedStoreReleaseNoteDto({required String locale, required List<String> releaseNoteBullets}) =
      _LocalizedStoreReleaseNoteDto;

  const LocalizedStoreReleaseNoteDto._();

  factory LocalizedStoreReleaseNoteDto.fromJson(Map<String, Object?> json) =>
      _$LocalizedStoreReleaseNoteDtoFromJson(json);

  String get formattedReleaseNote {
    final bullets = releaseNoteBullets.map((bullet) => bullet.trim()).toList();

    if (bullets.any((bullet) => bullet.isEmpty)) {
      throw StateError('Release note bullets for $locale cannot be empty.');
    }

    return bullets.map((bullet) => '• $bullet').join('\n');
  }
}
