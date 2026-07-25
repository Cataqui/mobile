import 'package:release/src/dtos/store_release_notes_dto.dart';
import 'package:test/test.dart';

void main() {
  test('when decoding store release notes, it should return every typed localization', () {
    final releaseNotes = StoreReleaseNotesDto.fromJson({
      'localizations': [
        {
          'locale': 'pt-BR',
          'releaseNoteBullets': ['Novidades locais.'],
        },
      ],
    });

    expect(releaseNotes.toJson(), {
      'localizations': [
        {
          'locale': 'pt-BR',
          'releaseNoteBullets': ['Novidades locais.'],
        },
      ],
    });
  });

  test('when store release note localizations have the wrong type, it should reject the JSON', () {
    expect(() => StoreReleaseNotesDto.fromJson({'localizations': 'pt-BR'}), throwsA(isA<TypeError>()));
  });
}
