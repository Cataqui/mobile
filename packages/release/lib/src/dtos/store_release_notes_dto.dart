import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:release/src/dtos/localized_store_release_note_dto.dart';

part 'store_release_notes_dto.freezed.dart';
part 'store_release_notes_dto.g.dart';

@freezed
abstract class StoreReleaseNotesDto with _$StoreReleaseNotesDto {
  const factory StoreReleaseNotesDto({required List<LocalizedStoreReleaseNoteDto> localizations}) =
      _StoreReleaseNotesDto;

  factory StoreReleaseNotesDto.fromJson(Map<String, Object?> json) => _$StoreReleaseNotesDtoFromJson(json);
}
