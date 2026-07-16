# AGENTS.md — Cataquí App

## Purpose

`app` is the monorepo's **application entry point** — the primary mobile app for the Cataquí platform. It is the **sole consumer** of `qui` design system components and `oh_my_flutter` superpower utils.

Unlike the `qui` package (which must be portable and publicly distributable), the `app` package is **internal and single-purpose**. It orchestrates screens, widgets, services, and state specific to the Cataquí mobile experience.

## No Documentation for Internal Code

Code inside `app/` is **not a public API**. It is consumed exclusively by this application itself and by AI agents working on this repository.

- **No dartdoc (`///`) needed** on any class, method, field, or variable inside the `app` package. The code should be self-explanatory through naming, structure, and conventions alone.
- **No `@Preview` annotations** — they are only required in the `qui` package.
- Dartdoc is reserved for `qui` and `oh_my_flutter`, which may be published as standalone packages on pub.dev.

## Structure

```
app/lib/
├── main.dart          # App entry point
├── app.dart           # MaterialApp.router configuration
├── core/              # DTOs, providers, config
│   ├── dtos/          # Freezed JSON DTOs (generated)
│   └── providers.dart # App-level Riverpod providers
├── gen/               # FlutterGen generated assets (do not edit, gitignored)
├── i18n/              # Slang translation files (pt-BR)
├── views/             # Screen-level widgets (pages/routes)
└── widgets/           # Reusable app-level widgets
```

## i18n (Translations)

Internationalization uses **slang** (`package:slang`) for type-safe translations
with JSON source files and code generation.

- **Source files:** Translation strings live in `app/lib/i18n/` as JSON files
  (e.g., `pt-BR.i18n.json`). Run `melos gen:all` after editing them.
- **Access pattern:** Read translations via Riverpod:
  ```dart
  final i18n = ref.watch(translationProvider);
  ```
  Always name the local variable `i18n`, not `t`.
- **Variable naming in code:** Use `i18n` everywhere the translation object is
  held, including function/method parameters.
- **Typed parameters:** Every slang parameter must include a type annotation
  (e.g., `{value: String}`, `{count: int}`). Never use untyped parameters like
  `$value` or `{value}`.
- **Provider:** `translationProvider` is declared in `app/lib/core/providers.dart`
  and reads the locale from `appStateProvider`.

## State Management

### Provider Placement

Every app-level Riverpod provider must be declared in `app/lib/core/providers.dart`.
Do not declare providers alongside repositories, DTOs, widgets, or feature files.
Feature state/data classes are the exception — the `@riverpod` notifier and its
data class must live at the same level as their view for easier finding and
management.

### Provider Style — Always Use Code Generation

All providers in `providers.dart` **must** use the `@riverpod` annotation syntax
(top-level function with `Ref ref` parameter), not `final xxxProvider = Provider<...>`:

```dart
@Riverpod(keepAlive: true)  // shared singleton — survives navigation
AppConfig appConfig(Ref ref) {
  return AppConfig(environment: Env.environment, cataquiApiUrl: Env.cataquiApiUrl);
}

@riverpod                      // auto-dispose — scoped to consumer lifecycle
OmfWhatsapp omfWhatsapp(Ref ref) {
  return OmfWhatsapp();
}
```

- `@Riverpod(keepAlive: true)` when the provider holds app-wide shared state
  (config, repositories, singleton services, Dio, GoRouter, translations).
- `@riverpod` (auto-dispose) when the instance is cheap to recreate and has no
  lasting state (utilities like `OmfWhatsapp`, `OmfTelephony`).

The function name without the `Provider` suffix determines the generated
provider name: `appConfig(Ref ref)` → `appConfigProvider`. Do NOT use
`final xxxProvider = ...` variable syntax.

Use uppercase `@Riverpod` only when passing arguments like `keepAlive: true`.
Use lowercase `@riverpod` for the plain auto-dispose form.

### Feature State/Data Conventions

Feature-level Riverpod notifiers follow a two-class naming convention:

- **`XxxState`** — the `@riverpod` notifier class (e.g., `FeedState extends _$FeedState`, generates `feedStateProvider`).
- **`XxxData`** — the immutable value class held by the notifier (e.g., `FeedData` with `copyWith`).

The notifier and its data class reside together in `app/lib/views/<feature>/`.

### State Files Per Feature

Each Riverpod feature notifier and its data class get their own files:

- `app/lib/views/<feature>/<feature>_state.dart` — the `@riverpod` notifier + generated `.g.dart`
- `app/lib/views/<feature>/<feature>_data.dart` — the immutable data class

Tests mirror the source at `app/test/views/<feature>/<feature>_state_test.dart`.

## Routing (Type-Safe)

Every screen-level view in `app/lib/views/<feature>/` must have a companion
`<feature>_route.dart` declaring a `@TypedGoRoute<XxxRoute>` class
`extends GoRouteData with $XxxRoute` with a `part '<feature>_route.g.dart'`.

- **Parameters:** Path params, query params, and `$extra` are declared as typed
  constructor fields. Path param names must match the `:param` placeholders in
  the route path.
- **Navigation:** Navigate ONLY via the generated typed API:
  `XxxRoute(...).go(context)` / `.push<T>(context)` / `.pushReplacement(context)`
  / `.replace(context)`. Never build route location strings by hand.
- **Registration:** `app/lib/core/providers.dart` registers routes via the
  generated `$xxxRoute` getters (e.g. `GoRouter(routes: [$feedRoute, $jobRoute])`).
  Do NOT use `$appRoutes` — it is per-library and would collide across multiple
  route files.
- **Custom transitions:** Override `buildPage()` to return a `Page<void>` for
  custom page types / transitions. Otherwise override `build()` and let go_router
  supply the default `MaterialPage`.
- **Engine:** Navigation is powered by `go_router` + `go_router_builder` code
  generation. The routing algorithm is exposed as a `GoRouter` via
  `goRouterProvider` (keepAlive).`

## DTOs

- **Code Generation:** The `app` package is configured with **Freezed** and
  **json_serializable** for immutable API DTOs and type-safe JSON conversion.
  Run `melos gen:all` after adding or changing generated DTOs. Generated
  `.freezed.dart` and `.g.dart` files under `app/lib/core/dtos/` are ignored.
- **File Structure:** Keep exactly one DTO class per Dart source file.
  Shared enums may live in a dedicated non-DTO enum file.
- **Fixture Factories:** Every DTO must expose a `fixture()` factory method that
  returns a valid instance with realistic test data. Tests should use
  `XxxDto.fixture()` instead of shared fixture JSON files. Use `copyWith` to
  customize specific fields for a test case.

## Assets

The app uses **flutter_gen** for type-safe asset access.

- **Setup:** `flutter_gen_runner` is declared as a dev dependency; configuration
  lives in `app/pubspec.yaml` under the `flutter_gen:` key. Output goes to
  `lib/gen/` (gitignored via `app/.gitignore`).
- **Adding a new asset:**
  1. Place the file in the appropriate directory under `app/assets/`.
  2. Declare the directory in `app/pubspec.yaml` under `flutter: assets:`.
  3. Run `melos gen:all` from the repository root to regenerate.
- **Access pattern:** Import `package:cataqui_app/gen/assets.gen.dart` and use
  the `Assets.<category>.<name>` accessor directly. For SVGs, call `.svg()`; for
  raster images, call `.image()`.
- **Example:**
  ```dart
  Assets.logos.cataqui.svg(width: 120, height: 120);
  ```
- **Facades:** The app does **not** use branded facades like `qui`'s
  `QuiIcon`/`QuiThreeD` — access the `Assets` entry point directly.

## Repositories

Repository classes follow a strict separation between reactive constructor
parameters and per-call function parameters:

- **Constructor params** — reserved for infrastructure the repository depends
  on for its entire lifetime, such as `Dio`. If the param changes, rebuilding
  the repository is the correct behavior.
- **Function params** — used for request-specific data that may change between
  calls without invalidating the repository instance. For example, `locale`
  should be passed directly to the method that needs it rather than injected
  at construction time, so locale changes don't force unnecessary widget
  rebuilds via Riverpod.
