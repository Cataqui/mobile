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
