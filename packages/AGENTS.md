# AGENTS.md — Cataquí Packages

## 0. Purpose & Scope

This directory contains reusable Cataquí packages designed for two consumption modes:

- **Internal sharing** across the Cataquí monorepo (`app/`, future services, other packages)
- **Public distribution** on `pub.dev` (each package SHOULD be publishable independently)

Every package herein is a standalone product. Treat it as an open-source library from day one, regardless of whether it is currently published.

---

## 1. Package Philosophy

### Beginner-Friendly First

The primary consumer of a package is another developer — possibly a junior, possibly external to Cataquí, possibly unfamiliar with Flutter/Dart. Every package must be immediately usable with minimal context.

- The `README.md` must contain a **copy-paste-ready code example** that demonstrates the single most common use case.
- The API surface must be **minimal**: expose the fewest classes, methods, and widgets needed to solve the problem. Hide implementation details in `src/`.
- Error messages must be **actionable**: tell the user what went wrong AND how to fix it.
- Never require reading the package source code to understand how to use it.

### Well-Documented API

Every public declaration exported by the package must have a **dartdoc comment** (`///`). Follow the [Dart documentation guidelines](https://dart.dev/effective-dart/documentation):

- Write dartdoc for the **package consumer first**. The primary reader is an app
  developer using the package, not the package maintainer. Explain when and why
  to use the API, what behavior or role it controls, and what guarantees the
  consumer can rely on. Avoid maintainer-focused implementation narration unless
  it directly affects correct package usage.
- Document the **what** and **why**, not just the how.
- Use `///` doc comments on all public APIs: classes, top-level functions, extensions, typedefs, enums, fields, and constructors.
- Include a **code example** inside the doc comment using triple-backtick fences. This example must be valid Dart that a user could copy and paste:

````dart
/// Creates a formatted currency string for display.
///
/// ```dart
/// final price = formatCurrency(amount: 2500, locale: 'pt_BR');
/// print(price); // R$ 2.500,00
/// ```
String formatCurrency({required int amount, String locale = 'pt_BR'});
````

- Document **parameters**, **return values**, and **exceptions** using `[param]`, `Returns`, and `{@template}`/`{@macro}` for repeated text.
- Every constructor parameter that is stored as a public field must document what it controls.

### Versioning & Stability

Follow **strict semantic versioning** (`major.minor.patch`):

| Change Type                      | Version Bump |
| -------------------------------- | ------------ |
| Breaking public API change       | `major`      |
| New backwards-compatible feature | `minor`      |
| Bug fix, internal refactor, docs | `patch`      |

Before a `1.0.0` release, breaking changes are permitted within `0.x` but must be documented in `CHANGELOG.md` with migration notes.

---

## 2. Package Structure & Conventions

### Directory Layout

```
my_package/
├── lib/
│   ├── my_package.dart          # Barrel file — only exports, no logic
│   └── src/
│       ├── my_package_base.dart  # Internal classes NOT exported
│       └── implementations/
├── example/                      # (optional) Runnable example app
├── test/
│   └── my_package_test.dart
├── analysis_options.yaml
├── CHANGELOG.md
├── LICENSE
├── pubspec.yaml
└── README.md
```

### The Barrel File Rule

The file `lib/<package_name>.dart` is the **single entry point** for consumers. It must use `export` directives with `show`/`hide` to control exactly what is visible:

```dart
/// Cataquí Core — domain models, types, and constants.
library;

export 'src/models/post.dart' show Post, PostStatus;
export 'src/formatters/currency.dart' show formatCurrency;
```

**Never**:

- Place logic directly in the barrel file
- Use `export 'src/...'` without `show` to restrict the surface
- Export internal utilities, helper classes, or `src/` transitive dependencies

Everything under `lib/src/` is **implementation detail** by convention. The Dart ecosystem treats `src/` as private. Consumers **must not** import from `src/` directly. Use barrel-file-only exports to enforce this boundary.

### Constraints on Three-Party Dependencies

- **Zero external dependencies is the ideal.** Prefer Dart/Flutter SDK capabilities.
- If a dependency is required, prefer a well-known, well-maintained package with broad adoption.
- Every dependency must be justified in a code comment near the import or in the `pubspec.yaml` description.
- **Do not duplicate functionality** already provided by `dart:*` or `package:flutter/*` SDK.

---

## 3. Documentation Standards

### README.md (required for every package)

| Section                                 | Required?                    | Notes                                        |
| --------------------------------------- | ---------------------------- | -------------------------------------------- |
| Short description (1 sentence)          | Yes                          | Same as `pubspec.yaml` description           |
| Visual badge row (pub.dev, license, CI) | Recommended                  | Only if published                            |
| Installation instructions               | Yes                          | `flutter pub add <package>` or `pub add`     |
| Quick-start code example                | Yes                          | Copy-paste ready, shows the primary use case |
| Full API usage (optional sections)      | As needed                    | Document advanced patterns                   |
| Additional configuration                | If applicable                | Platform setup, environment, etc.            |
| Contributing guide                      | Link to root CONTRIBUTING.md | Optional for internal-only packages          |

### CHANGELOG.md (required)

Every release must be documented in `CHANGELOG.md` following [keepachangelog.com](https://keepachangelog.com) format:

```markdown
## 0.2.0

- Added `formatCurrency()` for BRL and USD locale formatting.
- Changed `Post.createdAt` from `String` to `DateTime`.
- Fixed off-by-one error in pagination offset calculation.
```

### pubspec.yaml

Include these fields to make the package discoverable and professional:

```yaml
name: oh_my_flutter
description: Flutter/Dart superpower utils — extensions, helpers, and reusable patterns.
version: 0.1.0
repository: https://github.com/cataqui/mobile
issue_tracker: https://github.com/cataqui/mobile/issues
documentation: https://cataqui.dev/docs
topics:
  - cataqui
  - jobs
  - marketplace
```

---

## 4. Code Quality & Testing

### Analysis

All packages must use `analysis_options.yaml` that includes `very_good_analysis`. The root `analysis_options.yaml` is already configured — each package should reference it:

```yaml
include: ../../analysis_options.yaml
```

Run `melos analyze` before every commit. Zero warnings.

### Testing Requirements

Follow the monorepo testing protocol from the root `AGENTS.md`:

- Every public function, class method, and widget must have **at least one test**.
- One assertion per `test()` block.
- Test the **failure cases** too: null inputs, network errors, empty states, boundary values.
- Tests must be **deterministic** — no reliance on wall clock, random, or network.
- Run with `melos test` (or per-package: `fvm flutter test`).
- All tests must follow the `when, should` naming pattern (e.g.,
  `when formatCurrency is called with 2500, it should return R$ 2.500,00`).

### Documentation Tests

Doc comments with code examples should compile. Where feasible, use `///
/// ```dart
/// // ...example...
/// ````
patterns and verify they work. Consider using `dart doc` to confirm no broken references.

---

## 5. Developer Experience Principles

### Predictable API Shapes

Follow Dart conventions that users already know:

- **Constructors**: Use named parameters (required or optional) for anything beyond a single positional parameter.
- **Factories**: Prefer named constructors over static methods for object creation.
- **Futures vs Streams**: Return `Future<T>` for one-shot operations, `Stream<T>` for sequences of values over time.
- **Async suffix**: Append `Async` to method names that return `Future` or `Stream` (e.g., `fetchPostAsync()`).
- **Null safety**: Use `?` for nullable, `required` for mandatory named parameters. Never use `late` unless the initialization pattern is truly unavoidable (and then document why).

### Consistent Error Handling

- Define **typed exceptions** (`class PostNotFoundException implements Exception`) instead of generic `Exception` strings.
- Include a `message` property on all custom exceptions.
- Never swallow errors silently. If you catch, you must log, rethrow, or handle visibly.

### Naming Conventions

| What             | Convention                     | Example                                    |
| ---------------- | ------------------------------ | ------------------------------------------ |
| Public API types | UpperCamelCase                 | `class JobCategory { }`                    |
| Public functions | lowerCamelCase                 | `String formatCurrency(...)`               |
| File names       | snake_case                     | `currency_formatter.dart`                  |
| Private helpers  | underscore prefix              | `_validateInput()`                         |
| Extensions       | UpperCamelCase, noun/adjective | `extension DateTimeFormatting on DateTime` |

### Export Hygiene

- Do **not** export types that the consumer did not ask for. If a model depends on another type, the consumer should not need to import that dependency separately — re-export it through your barrel file if it is part of a returned value.
- Prefer explicit `show` in exports. Avoid bare `export 'src/foo.dart'` — always list symbols.

---

## 6. Security & Privacy (Package Context)

- **Never** include API keys, tokens, or endpoints in package source code. Package consumers must provide configuration.
- If a package requires secrets (e.g., API base URL, auth tokens), accept them via constructor parameters or a configuration object — never hardcode.
- If a package handles user location data, document the privacy implications and required platform permissions in the README.
- All HTTP-capable packages must use `https` URLs only.

---

## 7. Monorepo Integration

### Cross-Package Dependencies

Declare dependencies using relative `path:` in `pubspec.yaml`:

```yaml
dependencies:
  oh_my_flutter:
    path: ../oh_my_flutter
```

Before publishing to `pub.dev`, replace `path:` dependencies with proper version constraints.

### Workspace Scripts

- `melos analyze` — static analysis across all packages
- `melos test` — run all package tests
- `melos gen:all` — regenerate code-gen outputs across all packages (if applicable)

Always use `melos` for cross-package operations, not ad-hoc scripts.

---

## 8. Checklist Before Creating or Modifying a Package

1. [ ] Does the barrel file export only the intended public API?
2. [ ] Are all public declarations documented with `///` dartdoc?
3. [ ] Does every public declaration have at least one test?
4. [ ] Is the README complete with a copy-paste example?
5. [ ] Is the CHANGELOG updated?
6. [ ] Does `melos analyze` pass with zero warnings?
7. [ ] Does `melos test` pass?
8. [ ] Are all `src/` imports hidden from the barrel file?
9. [ ] Are there zero hardcoded secrets or endpoints?
10. [ ] Is the semantic version correctly bumped?
