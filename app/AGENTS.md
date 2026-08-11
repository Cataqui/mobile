# AGENTS.md — Cataquí App

## Purpose

`app` is the monorepo's **application entry point** — the primary mobile app for the Cataquí platform. It uses the [Mateo Mobile design-system](https://github.com/Ventairy/mateo) components and `oh_my_flutter` utilities.

The `app` package is **internal and single-purpose**. It orchestrates screens, widgets, services, and state specific to the Cataquí mobile experience.

## No Widget Previews

Do not add `@Preview` annotations inside the app. Widget previews belong in the
Mateo package.

## Structure

```
app/lib/
├── main.dart          # App entry point
├── app.dart           # MaterialApp.router configuration
├── core/              # DTOs, providers, config
│   ├── dtos/          # Freezed JSON DTOs (generated)
│   └── providers.dart # App-level Riverpod providers
├── gen/               # FlutterGen generated assets (do not edit, gitignored)
├── views/             # Screen-level widgets (pages/routes)
└── widgets/           # Reusable app-level widgets
```

## i18n (Translations)

Internationalization is app-owned and uses **slang** (`package:slang`) for
type-safe translations.

- **Source files:** Translation strings live in
  `lib/i18n/` as JSON files (e.g., `pt-BR.i18n.json`). Run
  `melos gen` from the repository root after editing them.
- **Imports:** Import translations through
  `package:cataqui_app/i18n/locale.dart`; never
  import generated files directly.
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
  return const AppConfig(flavor: appFlavor ?? 'development');
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

Feature-level Riverpod notifiers are named after the domain responsibility or
workflow they own, not after the widget, view, or screen that currently consumes
them. A widget may be domain-specific while still being only one presentation
of the underlying state.

Use the following two-class naming convention:

- **`<Domain>State`** — the `@riverpod` notifier class (for example,
  `WhatsappLoginState extends _$WhatsappLoginState`, which generates
  `whatsappLoginStateProvider`).
- **`<Domain>Data`** — the immutable domain value held by the notifier when a
  dedicated value class is necessary (for example, `WhatsappLoginData`).

Do not include presentation suffixes such as `Button`, `Widget`, `View`, or
`Screen` in a Riverpod state or data class merely because that UI currently
owns or consumes the provider. For example, use `WhatsappLoginState`, not
`WhatsappLoginButtonState`. UI-specific interactive state belongs in the
widget or view under the UI ownership rule below.

Riverpod state attached to a view must live in the same directory as that view.
Name the notifier file after its domain subject with the `*_state.dart` suffix,
even when it lives beside the only view or widget that currently uses it. For
example, a WhatsApp login notifier beside `whatsapp_login_button.dart` is named
`whatsapp_login_state.dart`, not `whatsapp_login_button_state.dart`. Do not
create a separate sibling directory solely for view-owned state.

State shared by multiple views may live at their closest shared feature
directory instead.

### UI Ownership vs. Riverpod State

Anything that exists to control or react to the interface belongs in the UI
layer, normally the owning widget or view. This includes `BuildContext` usage,
app and widget lifecycle handling, toasts, dialogs, navigation, focus,
animations, presentation timers, and deciding which visual feedback to show.
Keep these concerns out of Riverpod notifier classes.

Riverpod state classes should primarily own non-interactive application logic:
calling repositories, coordinating data workflows, transforming results, and
publishing domain data plus standard loading and error state. Prefer
Riverpod's existing state types, such as `AsyncValue`, when they already
describe the observable result. Do not add custom notifier phases or data
variants solely to tell a widget which UI treatment to render; derive that
presentation in the widget or view from the notifier's domain state.

### State Files Per Feature

Each Riverpod notifier and its data class get their own files. When one view or
widget owns the domain workflow, both files live beside that UI while retaining
domain names:

- `<ui-directory>/<domain>_state.dart` — the `@riverpod` notifier plus its
  generated `.g.dart`
- `<ui-directory>/<domain>_data.dart` — the immutable data class, when needed

Tests mirror the source at
`<matching-test-directory>/<domain>_state_test.dart`.

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
  Run `melos gen` after adding or changing generated DTOs. Generated
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
  3. Run `melos gen` from the repository root to regenerate.
- **Access pattern:** Import `package:cataqui_app/gen/assets.gen.dart` and use
  the `Assets.<category>.<name>` accessor directly. For SVGs, call `.svg()`; for
  raster images, call `.image()`.
- **Example:**
  ```dart
  Assets.logos.cataqui.svg(width: 120, height: 120);
  ```
- **Facades:** The app does **not** use Mateo for app specific assets — access the
  app's `Assets` entry point directly.

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
