import 'package:release/src/dtos/localized_store_release_note_dto.dart';
import 'package:test/test.dart';

void main() {
  test('when decoding a localized store release note, it should return every typed field', () {
    final releaseNote = LocalizedStoreReleaseNoteDto.fromJson({
      'locale': 'pt-BR',
      'releaseNoteBullets': ['Novidades locais.'],
    });

    expect(releaseNote.toJson(), {
      'locale': 'pt-BR',
      'releaseNoteBullets': ['Novidades locais.'],
    });
  });

  test('when a localized store release note field has the wrong type, it should reject the JSON', () {
    expect(
      () => LocalizedStoreReleaseNoteDto.fromJson({'locale': 'pt-BR', 'releaseNoteBullets': 42}),
      throwsA(isA<TypeError>()),
    );
  });

  test('when formatting release note bullets, it should put every sentence on its own store line', () {
    const releaseNote = LocalizedStoreReleaseNoteDto(
      locale: 'pt-BR',
      releaseNoteBullets: ['Primeira novidade.', 'Segunda novidade.'],
    );

    expect(releaseNote.formattedReleaseNote, '• Primeira novidade.\n• Segunda novidade.');
  });

  test('when formatting an empty release note bullet, it should reject the release note', () {
    const releaseNote = LocalizedStoreReleaseNoteDto(locale: 'pt-BR', releaseNoteBullets: [' ']);

    expect(() => releaseNote.formattedReleaseNote, throwsStateError);
  });
}
