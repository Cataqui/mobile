# AGENTS.md — Cataquí UI (qui)

## Purpose

`qui` (Cataquí UI) is the reusable design system package for the Cataquí platform. It contains foundational UI components, tokens, and patterns used across all Cataquí apps (mobile, web, and beyond).

## Dart Documentation

### Naming

In Dart doc comments for this package, always refer to the design system as
`QUI`, not `Cataquí`. The package name means "Q" + "UI", standing for
`Cataquí UI`, so public API documentation should use the package-oriented name.

### Every Public Member Must Have Dartdoc

Every public class, constructor, method, property, enum, enum value, typedef,
and top-level function **must** have a `///` doc comment. There are no
exceptions for "obvious" members — `dart doc` surfaces all public declarations
and a missing doc comment is a visible gap. Private (`_`-prefixed) members must
**not** have dartdoc.

### First Sentence Rule

The first sentence of every doc comment must be a complete, self-contained
statement ending with a period. It appears as the short summary in `dart doc`
lists and search results. Separate it from the rest of the comment with a blank
`///` line.

| Declaration type    | First sentence starts with                                       |
| ------------------- | ---------------------------------------------------------------- |
| Class               | Noun phrase describing what an instance **is**                   |
| Constructor         | "Creates a …"                                                    |
| Method (side-effect)| Third-person verb describing what it **does**                    |
| Method (returns)    | Noun phrase describing the **result**                            |
| Non-bool property   | Noun phrase describing what it **is**                            |
| Bool property       | "Whether …" followed by the condition                            |
| Enum type           | Noun phrase describing the category                              |
| Enum value          | Descriptive phrase                                               |
| Typedef             | Noun phrase describing the signature                             |

```
/// Creates a text hero that animates [TextStyle], content, and wrapping
/// behavior between source and destination.
///
/// The [TextStyle] is interpolated via [TextStyle.lerp] across the full
/// flight. Text content and layout constraints ([maxLines], [overflow])
/// switch from the source configuration to the destination configuration
/// at the exact midpoint (50 %) of the flight animation.
factory QuiHero.text({ … })
```

### Class Documentation Structure

A well-documented class follows this order:

1. First sentence (what it **is**)
2. Blank `///` line
3. Detailed prose — 2‑4 paragraphs explaining behavior, invariants, and edge cases
4. Structured subsections with `##` headings (e.g. `## How it works`, `## Choosing a variant`, `## Performance`)
5. Code samples — prefer fenced ` ```dart ` blocks
6. `See also:` bulleted list

### Code Samples

Prefer fenced ` ```dart ` code blocks over indented ones. Every code sample
must be complete enough to copy‑paste and understand without surrounding
prose. Use `{@tool snippet}` blocks for inline examples and `{@tool dartpad}`
for interactive samples (though the latter requires a separate fixture file).

```dart
/// ```dart
/// QuiHero.box(
///   tag: 'card-1',
///   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
/// )
/// ```
```

### Parameter and Return Value Documentation

Document each constructor parameter, method parameter, and return value within
the enclosing doc comment using `[parameterName]` references — never
`@param` or `@return` tags (these are Java/JSDoc conventions, not Dart).

```
/// Wraps [child] with the behavior owned by this extension.
///
/// The [context] is the [BuildContext] at the point where the hero renders.
/// Use it to access the [QuiHeroPageRoute] via [QuiHeroPageRoute.maybeOf].
///
/// The returned widget replaces [child] in the hero's render tree.
Widget wrap({required BuildContext context, required Widget child});
```

### Cross-Reference Linking

Wrap type names, member names, and constructor names in square brackets `[]`
to create links in generated documentation:

| To link to                | Syntax                           |
| ------------------------- | -------------------------------- |
| Class                     | `[ClassName]`                    |
| Named constructor         | `[ClassName.named]`              |
| Unnamed constructor       | `[ClassName.new]`                |
| Method                    | `[ClassName.method()]`           |
| Property / field          | `[ClassName.property]`           |
| Enum value                | `[EnumName.value]`               |
| Top-level function        | `[functionName()]`               |
| Member on `this` class    | `[method()]` or `[property]`     |

Use backticks `` ` ` `` for parameter names, code values, and expressions in
prose that do not need a link: `` `width` `` → `width`. Use `[width]` only
when `width` is a documented property you want to link to.

### Boolean Property Documentation

Every boolean property must start with "Whether" and describe the condition:

```
/// Whether an interactive pop gesture is currently in progress.
///
/// Returns `true` after a successful call to [startInteractivePop] and
/// `false` after [cancelInteractivePop] or [commitInteractivePop] completes.
bool get isInteractivePopActive => _isInteractivePopActive;
```

### "See Also" Sections

Place `See also:` at the end of class‑level and significant member‑level docs.
Each entry is a bullet (`*`) containing a `[Link]` followed by a comma and a
brief description of why the reader should care:

```
/// See also:
///  * [QuiHeroPageRoute], the route created by this page that manages hero
///    animations and the interactive-pop API.
///  * [QuiHero], the hero widget that flies between the source route and
///    this page.
///  * [QuiHeroDragToCloseExtension], the extension that wires drag gestures
///    to the route's interactive-pop API.
```

### Templates and Macros (`{@template}` / `{@macro}`)

Use `{@template}` and `{@macro}` when the same prose block is referenced
in **more than one** doc comment. Do **not** create templates for single-use
text.

- Define with: `/// {@template qui_component_descriptive_name}` … `/// {@endtemplate}`
- Reference with: `/// {@macro qui_component_descriptive_name}`
- Naming convention: `qui_<component>_<descriptive_snake_case>`

Templates can be placed on any declaration (typedef, method, property) — they
do not need a dedicated location. Place each template on the declaration
where the concept is first introduced.

### Anti‑Patterns

| Avoid                                 | Use instead                                          |
| ------------------------------------- | ---------------------------------------------------- |
| `//` for public docs                  | `///` (only `//` is invisible to `dart doc`)         |
| `/** … */` JavaDoc style              | `///` on every line                                  |
| `@param name Description`             | `[name]` inline in prose                             |
| `@return Description`                 | Describe the result in the method's first sentence   |
| No blank line after first sentence    | Always add blank `///` line before detailed prose    |
| `/// Constructor.`                    | `/// Creates a [ClassName] that …`                   |
| `/// Sets the tooltip.`               | Omit — it adds no information beyond the signature   |
| `/// The name.` / `/// The title.`    | Omit — the name is inferred unless there's a non‑obvious detail |
| Indented code blocks (4 spaces)       | Fenced ` ```dart ` blocks                            |
| HTML tags in doc comments             | Markdown only                                        |
| Abbreviations (i.e., e.g.)            | Spell it out: "for example", "that is"               |
| Documenting both getter and setter    | Document only the getter — `dart doc` ignores setter docs |
| `[hero]` when meaning `[QuiHero]`    | Use the full type name — short links are ambiguous   |
| Redundant code in prose               | If already in a code block, don't repeat it verbatim |

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
- **Example:** `when QuiSearchBarButton is tapped, it should invoke the onTap callback`
- Avoid vague descriptions like `renders correctly` or `test login`.

## Structure

```
lib/
├── qui.dart                   # Barrel file — single entry point for consumers
├── gen/                       # Generated code (fonts, assets) — do not edit
└── src/
    ├── icons/                 # QuiIcons — automatic icon accessors (flutter_gen facade)
    ├── theme/                 # Design tokens (colors, typography, theme data)
    ├── three_d/               # Qui3d — automatic 3D image asset accessors (flutter_gen facade)
    └── widgets/               # Reusable UI components (each with attached preview)
```

## Conventions

- All public widgets are exported from `lib/qui.dart` with explicit `show`.
- Widgets live in `lib/src/widgets/`. Simple widgets may use one file. Larger
  widgets may use a same-named folder with one public entrypoint and focused
  `part` files for public value types, controllers, actions, and other support
  classes, following the `qui_swipe_deck` structure.
- Every widget file includes a `@Preview` annotated preview function at the bottom.
- Preview functions are **not** exported from the barrel file — they are only discovered by the Widget Previewer at development time.
- Access bundled SVG icons via `QuiIcons` (e.g. `QuiIcons.cross.svg(...)`), exported from the barrel. `QuiIcons` is an automatic facade over `flutter_gen`'s generated `Assets.icons` — add an `.svg` to `assets/icons/` and run `melos gen:all` to surface a new accessor. Do not import `gen/assets.gen.dart` directly from widget code; use `QuiIcons`.
- Access bundled 3D image assets via `Qui3d` (e.g. `Qui3d.box.image(width: 200, height: 200)`), exported from the barrel. `Qui3d` is an automatic facade over `flutter_gen`'s generated `Assets.threeD` — add an image file (e.g. `.webp`, `.png`, `.jpg`) to `assets/three_d/` and run `melos gen:all` to surface a new accessor. Do not import `gen/assets.gen.dart` directly from widget code; use `Qui3d`.
- Private declarations (`_`-prefixed classes, methods, fields, and part files for private types) must NOT have dartdoc. Private code should be self-explanatory through naming and structure alone. dartdoc is reserved for the public API surface that consumers outside the package can see.
