# AGENTS.md — Cataquí App Test Conventions

## 1. Mocks Live in One Place

All mock classes must be defined in `test/mocks.dart`. Do **not** create inline mocks, handwritten fakes, or per-file mock classes unless the mocked interface has private fields that make mocktail impossible (e.g., `FeedState` extends `_$FeedState`). In those extreme cases, use a lightweight `Fake` subclass in the test file and document why mocktail cannot work.

## 2. Instantiate Once in `setUp`

Do **not** call `MockXxx()` inside individual tests. Declare the mock at the group level and instantiate it once in `setUp`:

```dart
late MockFeedRepository repository;

setUp(() {
  repository = MockFeedRepository();
  registerFallbackValue(FeedSort.latest);
});
```

Each test then uses the shared instance. If a test needs a different stub, it overrides the relevant `when` inside that test only.

## 3. Stub Defaults in `setUp` — Override Per Test

Define the default `when` stubs in `setUp` so every test starts with a working baseline. Individual tests only add `when` overrides for the specific path they are testing:

```dart
setUp(() {
  repository = MockFeedRepository();
  registerFallbackValue(FeedSort.latest);
  when(() => repository.getFeedJobs(cursor: any(named: 'cursor'), sort: any(named: 'sort')))
      .thenAnswer((_) async => feedEnvelope());
});

// Test only overrides what differs:
testWidgets('when the API fails, it should show error', (tester) async {
  when(() => repository.getFeedJobs(cursor: any(named: 'cursor'), sort: any(named: 'sort')))
      .thenThrow(Exception('fail'));
  ...
});
```

This keeps tests DRY while making deviations explicit and easy to spot.

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

## 8. Real Interactions in Golden Tests

Prefer driving real user interactions (`tester.tap`, `tester.drag`, `tester.enterText`, `tester.pumpAndSettle`) over stubbing intermediate states. This catches usability bugs — not just visual regressions:

```dart
// ✅ Prefer this — simulate real navigation flow
goldenTest('when tapping a job card, it should navigate to the detail screen',
    (tester) async {
  await tester.pumpWidget(createApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Descarregar Caminhão'));
  await tester.pumpAndSettle();
  await screenMatchesGolden(tester, 'job_detail_loaded');
});

// ❌ Avoid this — bypasses navigation, misses transition bugs
goldenTest('job detail loaded state', (tester) async {
  await tester.pumpWidget(createApp(initialRoute: '/job/123'));
  await screenMatchesGolden(tester, 'job_detail_loaded');
});
```

Exceptions are permitted when the interaction requires an external dependency that cannot be simulated (e.g., camera, biometrics, push notification opt-in). Document the exception in the test description.
