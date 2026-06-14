# AGENTS.md — Cataquí UI (qui)

## Purpose

`qui` (Cataquí UI) is the reusable design system package for the Cataquí platform. It contains foundational UI components, tokens, and patterns used across all Cataquí apps (mobile, web, and beyond).

## Dart Documentation Naming

In Dart doc comments for this package, always refer to the design system as
`QUI`, not `Cataquí`. The package name means "Q" + "UI", standing for
`Cataquí UI`, so public API documentation should use the package-oriented name.

## Public Package Portability

Treat `qui` as a package that can be released publicly on pub.dev and used by
apps outside Cataquí. Widgets must be portable, defensive, and configurable for
reasonable environment differences instead of assuming Cataquí's internal
services, infrastructure, assets, data shapes, or provider capabilities.

### Portability rules

- Do not hardcode Cataquí-only URLs, signed tokens, backend assumptions, or
  environment-specific operational details in reusable widgets.
- Public widget APIs should describe real external capabilities when those
  capabilities can vary by consumer. For example, map widgets should accept
  tile source capability bounds such as `tileMinZoom` and `tileMaxZoom` instead
  of assuming every provider supports the same zoom range as Cataquí's tiles.
- Keep convenience defaults for Cataquí's current use case only when they are
  broadly safe and easy for external consumers to override.
- Before adding a widget assumption, ask whether it can break if a consuming app
  has a different tile server, locale, asset setup, theme, screen size, input
  data, platform, network policy, or accessibility configuration.
- Prefer small explicit configuration over hidden fixed behavior when the value
  represents an external system contract rather than visual taste.

## Preview Requirement

Every widget in `qui` **must** have a `@Preview` annotation attached to a top-level preview function at the bottom of the widget's own `.dart` file. This ensures all components are visually documented and testable in the Flutter Widget Previewer.

### Preview rules

- Place the preview function directly in the same file as the widget (not in a separate file).
- Use `package:flutter/widget_previews.dart` for the `@Preview` annotation.
- Wrap the widget in a `MaterialApp` with `QuiTheme.light(primaryColor: ...)` so theme tokens resolve correctly.
- Use `package:qui/src/theme/qui_theme.dart` (not `package:qui/qui.dart`) to avoid circular imports when the preview is colocated with the widget.

## Golden Testing

Every new widget in `qui` must have a corresponding golden test file at
`test/widgets/<widget_name>_golden_test.dart`.

### Golden test rules

- Cover all visual states (resting, active, error, loading, disabled, etc.)
  using `GoldenTestScenario` and `GoldenTestGroup`.
- Use `goldenTest` from `alchemist`, not raw `matchesGoldenFile`.
- Configure `AlchemistConfig` in `test/flutter_test_config.dart` with
  `QuiTheme.light(primaryColor: ...)` so theme tokens resolve in all golden
  scenarios.
- Commit CI goldens stored at `test/widgets/goldens/ci/`.
- Gitignore platform goldens stored at `test/widgets/goldens/macos/`,
  `test/widgets/goldens/linux/`, and `test/widgets/goldens/windows/`.
- Regenerate approved goldens from the repository root with
  `melos goldens:update`.
- Golden tests complement unit tests; they do not replace non-visual tests.

## Descriptive Naming

All tests must use the `when, should` pattern for descriptions.

- **Format:** `when <condition/action>, it should <expected result>`
- **Example:** `when QuiSearchBar is frosted, it should render a blurred background`
- Avoid vague descriptions like `renders correctly` or `test login`.

## Structure

```
lib/
├── qui.dart                   # Barrel file — single entry point for consumers
├── gen/                       # Generated code (fonts, assets)
└── src/
    ├── theme/                 # Design tokens (colors, typography, theme data)
    └── widgets/               # Reusable UI components (each with attached preview)
```

## Conventions

- All public widgets are exported from `lib/qui.dart` with explicit `show`.
- Widgets live in `lib/src/widgets/`. Simple widgets may use one file. Larger
  widgets may use a same-named folder with one public entrypoint and focused
  `part` files for public value types, controllers, actions, and other support
  classes, following the `qui_swipe_list` structure.
- Every widget file includes a `@Preview` annotated preview function at the bottom.
- Preview functions are **not** exported from the barrel file — they are only discovered by the Widget Previewer at development time.
