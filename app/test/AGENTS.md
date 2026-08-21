# AGENTS.md — Cataquí App Test Conventions

## 1. Mocks Live in One Place

All mock classes must be defined in `test/mocks.dart`. Do **not** create inline mocks, handwritten fakes, or per-file mock classes unless the mocked interface has private fields that make mocktail impossible (e.g., `FeedState` extends `_$FeedState`). In those extreme cases, use a lightweight `Fake` subclass in the test file and document why mocktail cannot work.

## 2. Instantiate Once in `setUp`

Do **not** call `MockXxx()` inside individual tests. Declare the mock at the group level and instantiate it once in `setUp`:

```dart
late MockFeedRepository repository;

setUp(() {
  repository = MockFeedRepository();
});
```

Each test then uses the shared instance. If a test needs a different stub, it overrides the relevant `when` inside that test only.

## 3. Stub Defaults in `setUp` — Override Per Test

Define the default `when` stubs in `setUp` so every test starts with a working baseline. Individual tests only add `when` overrides for the specific path they are testing:

```dart
setUp(() {
  repository = MockFeedRepository();
  when(() => repository.getFeedJobs(cursor: any(named: 'cursor')))
      .thenAnswer((_) async => feedEnvelope());
});

// Test only overrides what differs:
testWidgets('when the API fails, it should show error', (tester) async {
  when(() => repository.getFeedJobs(cursor: any(named: 'cursor')))
      .thenThrow(Exception('fail'));
  ...
});
```

This keeps tests DRY while making deviations explicit and easy to spot.

When many tests in a group need the same mock setup (e.g., a shared `setBool` stub), put it in `setUp`. Do not repeat the same `when` in every individual test — that's noise.

## 4. Helper Organization — No Top-Level Functions

Helper code (fixture builders, pump helpers, app wrappers, cleanup) must not be top-level functions. Organize them in one of two ways:

- **Inside the test file** — for small, single-use helpers scoped to one test group.
- **Inside a dedicated class** — for reusable helpers shared across test files. Use a class with a private constructor and `static` methods (e.g. `FeedViewTestHelpers`).

This keeps the import namespace clean and groups related functionality under an explicit name.

## 5. When to Use `FakeFeedState` Instead

Riverpod code generation creates `_$FeedState` (library-private, starts with `_$`). Mocktail needs `extends _$FeedState with Mock implements FeedState` to mock a notifier, but `_$FeedState` is inaccessible outside `feed_state.dart`.

The accepted alternative is a `Fake` subclass:

```dart
class FakeFeedState extends FeedState { ... }
```

This inherits the correct `runBuild()` from `_$FeedState` while letting us override `build()` directly. Use `initialAsyncValue` for synchronous state control (avoids FakeAsync error propagation issues).

Also: `extends Mock implements FeedState {}` (without `_$FeedState`) won't work — the Riverpod framework needs the real `state`/`ref`/`runBuild()` from the base class hierarchy, which only `extends FeedState` (→ `_$FeedState`) provides.

This is the **only** exception to Rule 1. Any future `Fake*` class must be justified by the same constraint (inaccessible generated base class).

## 6. One Golden File Per Golden Test

Each golden test must produce **exactly one** golden image file. Do not use multi-scenario `groupId` grouping that writes multiple goldens from a single `goldenTest` invocation. If a widget has multiple states, write separate `goldenTest` blocks — one per state, each with its own descriptive name and a single `pumpWidget` + `screenMatchesGolden`.

```dart
// Correct — one golden per test
goldenTest('when loaded, it should render the feed with job cards',
    (tester) async {
  await tester.pumpWidget(...);
  await screenMatchesGolden(tester, 'feed_view_loaded');
});

goldenTest('when empty, it should render the empty state message',
    (tester) async {
  await tester.pumpWidget(...);
  await screenMatchesGolden(tester, 'feed_view_empty');
});
```

```dart
// Incorrect — do NOT group multiple states in one goldenTest
goldenTest('feed view states', (tester) async {
  await tester.pumpWidget(loaded);
  await screenMatchesGolden(tester, 'feed_view_loaded');
  // ... then re-pump for empty, error, etc. → multiple goldens in one test
});
```

## 7. Screen-State Coverage Matrix

Every screen must have a golden test for **every distinct visual state** it can render. The minimum set is:

| State        | When to test                                             |
| ------------ | -------------------------------------------------------- |
| `loading`    | Initial async loading spinner or skeleton                |
| `loaded`     | Happy path with realistic content                        |
| `empty`      | Zero results but no error (e.g., "Nenhuma oportunidade") |
| `error`      | Network or server failure with retry UI                  |
| `refreshing` | Pull-to-refresh or silent background refresh indicator   |

Additional states (e.g., `focused`, `disabled`, `selected`, `frosted`) must also be covered when the screen supports them.

```dart
goldenTest('when loading, it should show shimmer placeholders',
    (tester) async { ... });

goldenTest('when loaded, it should render opportunity cards',
    (tester) async { ... });

goldenTest('when empty, it should show the no-results illustration',
    (tester) async { ... });

goldenTest('when error, it should show the error state with retry',
    (tester) async { ... });
```

State coverage applies to all screens, every component that changes appearance based on state must have full golden coverage.

## 8. Real Interactions Scoped to the SUT

When a test owns a view's rendering or behavior, instantiate that view directly. Do not navigate through preceding views merely to reach the subject. Flow changes must not break tests whose subject is still valid, and unrelated setup obscures what the test actually proves.

Once the system under test (SUT) is rendered, drive its behavior through real user interactions (`tester.tap`, `tester.drag`, `tester.enterText`, `tester.pumpAndSettle`) instead of calling its state methods or stubbing intermediate UI states. This catches usability and visual bugs in the SUT while keeping unrelated flows outside the test boundary.

Navigation belongs only in focused route or flow tests whose explicit SUT is navigation or a transition between views. A view test must not navigate from another view into its SUT.

Every test must construct and exercise the minimum scope necessary for its assertion or golden. Include only the providers, inherited widgets, state, dependencies, and user actions required by the behavior under test.

```dart
// Correct — render the payment SUT directly, then interact with it as a user.
goldenTest('when the payment type selector is tapped, it should show its options',
    (tester) async {
  await tester.pumpWidget(testApp(child: const CreateJobPaymentView(jobId: 'job-id')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('create_job_payment_type_selector')));
  await tester.pumpAndSettle();
  await screenMatchesGolden(tester, 'create_job_payment_type_selector_open');
});

// Incorrect — description entry and navigation are unrelated to this view state.
goldenTest('when the payment type selector is tapped, it should show its options',
    (tester) async {
  await tester.pumpWidget(testApp(child: const CreateJobDescriptionView()));
  await tester.enterText(find.byType(TextField), 'Description');
  await tester.tap(find.byKey(const ValueKey('continue')));
  await tester.pumpAndSettle();
  await screenMatchesGolden(tester, 'create_job_payment_fixed');
});
```

## 9. Never Assert on Hardcoded Translation Strings

Tests must never assert on hardcoded Portuguese string literals that are translation values. When a test checks for text that comes from the i18n layer (`find.text`, `find.textContaining`, `expect(result.contains(...))`, `expect(result, equals(...))`), it must read the expected string through the `Translations` API so the test stays green when copy changes.

### Canonical Setup

Build the `Translations` instance once per test file and name the variable `i18n` (per `app/AGENTS.md`):

```dart
import 'package:cataqui_app/i18n/locale.dart';

late Translations i18n;

setUpAll(() async {
  i18n = await AppLocale.ptBr.build();
});
```

### Usage

```dart
// ✅ Correct — reads from the Translations API
expect(find.text(i18n.feed.error.description), findsOneWidget);
expect(find.textContaining(i18n.jobPayment.paymentPeriodDaily), findsOneWidget);
expect(result, equals(i18n.jobPayment.paymentFlexible));

// ❌ Incorrect — hardcoded translation value
expect(find.text('Que estranho, não era pra isso acontecer. Tenta de novo'), findsOneWidget);
expect(find.textContaining('/dia'), findsOneWidget);
expect(result, equals('A Combinar'));
```

### Out of Scope

- **Fixture data** (job titles, descriptions used as test input) is not a translation and stays hardcoded or in a shared constant.
- **Non-translatable content** (currency symbols like `r'R$'`, numeric amounts like `'120'`) stays hardcoded.
- **Source-side i18n debt** (strings hardcoded in `app/lib/` source that should be translations but aren't yet) is a source issue — the test faithfully reflects current source behavior.

### Exception: Parameterized Template Fragments

Some translation values are parameterized templates (e.g. `paymentRangeUpTo`, `"Até {value}{period}"`). A test that checks for a fragment of the template (like `'Até'`) where no standalone translation key exists may remain hardcoded with a clarifying comment. Resolving this properly requires adding a new key to the JSON (a source-side change).

## 10. Package Mocks — Verify the Call, Trust the Package

When testing code that delegates to a package/library (e.g. `OmfWhatsapp.launchChat`,
`OmfTelephony.call`, `url_launcher.launchUrl`), the test's responsibility is only
to verify that the package method was called with the correct arguments. **Do not**
re-test the package's own behavior (URI construction, platform channel communication,
return values).

```dart
// Mock the package class in test/mocks.dart
class MockOmfWhatsapp extends Mock implements OmfWhatsapp {}

// In the test, inject via provider override:
when(() => whatsapp.launchChat(number: any(named: 'number')))
    .thenAnswer((_) async => true);

// Then verify the call:
verify(() => whatsapp.launchChat(number: '+5511999999999')).called(1);
```

- The stub must return a realistic default (`thenAnswer((_) async => true)` for
  `Future<bool>` methods) so the calling code's control flow can complete.
- `verify` checks the arguments passed to the package method — nothing more.
- Use `verifyNever` to confirm a method was NOT called in error/failure paths.
- Always define package mock classes in `test/mocks.dart`, not inline in test
  files.

## 11. Prefer `find.byKey` Over `find.text`

Always access widgets via `find.byKey` instead of `find.text`. Key-based lookups
are more robust: they don't break when translation copy changes, are immune to
duplicate strings, and make the test's intent explicit. If the widget under test
doesn't have a `Key`, add one via `ValueKey` — the small production-code change
is worth the test stability.

```dart
// ❌ Fragile — breaks when copy changes, ambiguous with duplicates
await tester.tap(find.text(i18n.job.contactButton.whatsapp));
expect(find.text(i18n.job.contactButton.unknown), findsOneWidget);

// ✅ Robust — survives copy changes, unambiguous
await tester.tap(find.byKey(const ValueKey('job_contact_whatsapp')));
expect(find.byKey(const ValueKey('job_contact_unknown')), findsOneWidget);
```

### When to Use Each

| Use `find.byKey` for                    | Use `find.text` for                                 |
| --------------------------------------- | --------------------------------------------------- |
| User-interaction points (taps, scrolls) | Content validation (is the right text showing?)     |
| Verifying widget presence/absence       | Verifying dynamic or API-driven content values      |
| Navigation targets                      | Fixture data assertions (with `copyWith` overrides) |

### Key Naming Convention

Use `snake_case` prefixed with the widget's domain:

```dart
const ValueKey('job_contact_whatsapp')
const ValueKey('feed_job_card_title')
const ValueKey('job_detail_back_button')
```

Keys are just for identification — namespace them by feature to avoid collisions.
Do not use i18n strings or user-facing text as key values.
