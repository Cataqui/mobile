import 'package:release/src/store_release_notes_prompt.dart';
import 'package:test/test.dart';

void main() {
  test('when generating store release notes, it should give the AI the store copy quality rules', () {
    final prompt = StoreReleaseNotesPrompt.generation(locales: ['pt-BR'], maxCharacters: 499);

    expect(
      prompt,
      allOf([
        contains('Lead with the most important user benefit'),
        contains('Include every significant user-visible change'),
        contains('Give each bullet one theme'),
        contains('Put each bullet sentence in its own releaseNoteBullets array item'),
        contains('Do not include a bullet marker or line break'),
        contains('exactly one complete sentence'),
        contains('silently classify every changelog item'),
        contains('Ignore developer-only changes'),
        contains('Treat the audience as people using the mobile app'),
        contains('without claiming what it sent or accomplished'),
        contains('Omit implementation quantities and limits'),
        contains('Never pad copy'),
        contains('end every bullet with punctuation'),
        contains('never insert characters from an unrelated script'),
        contains('rewrite anything that sounds translated, truncated, technical, or unnatural'),
        contains('Use this context only for natural vocabulary'),
        contains('prefer "trampo" or "trampos"'),
        contains('comfortably informal'),
        contains('Do not add a heading'),
        contains('Do not ask users to rate, review, follow, download, or try anything'),
        contains('Write each localization independently as native product copy'),
        contains('same user-visible facts in the same order across every locale'),
      ]),
    );
  });

  test('when editing store release notes, it should require native publication-ready copy', () {
    final prompt = StoreReleaseNotesPrompt.editing(locales: ['pt-BR', 'en', 'es'], maxCharacters: 499);

    expect(
      prompt,
      allOf([
        contains('final native-language editor'),
        contains('Audit the draft against the provided source changelog'),
        contains('Restore any significant app-user-visible change'),
        contains('Ignore developer-only changes'),
        contains('methods, constants, dependencies'),
        contains('source does not support'),
        contains('Keep generically named actions generic'),
        contains('light vibration confirms the contact action'),
        contains('without adding or strengthening any claim'),
        contains('behavior-defining qualifiers in every locale'),
        contains('tighten the wording instead'),
        contains('Never use corporate HR or job-board terms'),
        contains('natural, local, informal voice'),
        contains('same number of bullets across every locale'),
        contains('operating-system control names'),
        contains('delivery terms such as push'),
        contains('never as a literal translation'),
        contains('final joined release note between 1 and 499'),
      ]),
    );
  });

  test('when shortening store release notes, it should preserve separate supported user benefits', () {
    final prompt = StoreReleaseNotesPrompt.shortening(locales: ['pt-BR'], maxCharacters: 499);

    expect(
      prompt,
      allOf([
        contains('Never remove a bullet from only one locale'),
        contains('remove the same least important fact from every locale'),
      ]),
    );
  });
}
