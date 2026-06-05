# AGENTS.md — Cataquí UI (qui)

## Purpose

`qui` (Cataquí UI) is the reusable design system package for the Cataquí platform. It contains foundational UI components, tokens, and patterns used across all Cataquí apps (mobile, web, and beyond).

## Preview Requirement

Every widget in `qui` **must** have a `@Preview` annotation attached to a top-level preview function at the bottom of the widget's own `.dart` file. This ensures all components are visually documented and testable in the Flutter Widget Previewer.

### Preview rules

- Place the preview function directly in the same file as the widget (not in a separate file).
- Use `package:flutter/widget_previews.dart` for the `@Preview` annotation.
- Wrap the widget in a `MaterialApp` with `QuiTheme.light(primaryColor: ...)` so theme tokens resolve correctly.
- Use `package:qui/src/theme/qui_theme.dart` (not `package:qui/qui.dart`) to avoid circular imports when the preview is colocated with the widget.

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
- Widgets live in `lib/src/widgets/` — one file per widget.
- Every widget file includes a `@Preview` annotated preview function at the bottom.
- Preview functions are **not** exported from the barrel file — they are only discovered by the Widget Previewer at development time.
