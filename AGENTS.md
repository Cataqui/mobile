# AGENTS.md — Cataquí Mobile

## 0. Mission & Core Philosophy

You are operating within the **Cataquí Mobile Repository**, a high-performance Mobile App Monorepo built using Flutter and Dart.

Cataquí is the real-time opportunity layer of the city: a fast, frictionless, hyperlocal feed for quick jobs, side hustles, informal work, and temporary tasks.

### The Core Product Promise

> Open Cataquí and immediately see real opportunities happening near you right now.

### Core Visual & Experience Anchors

- **Ultralight & Fast:** Zero lag, instantaneous feed updates, smooth 60/120fps scrolling.
- **Hyperlocal:** Geographically sorted, contextualized for the streets of São Paulo.
- **Frictionless Loop:** Post an opportunity $\rightarrow$ Discover in feed $\rightarrow$ Tap Direct WhatsApp Contact.
- **Non-Corporate Brand:** Feels trustworthy, authentic, local, and premium—never look or behave like enterprise HR software, staffing ERPs, or corporate applicant tracking systems (ATS).
- **Mass-Market by Default:** Cataquí is built for the masses — every line of code must prioritize broad device coverage across Latin America, where low-end devices dominate. Every architectural decision, dependency, animation, layout, and feature must be optimized to run well on low-end hardware, not just flagship phones. If a feature cannot be delivered performantly on low-end devices, it must be rethought or cut.

---

## 1. Technical Stack & Environment

This repository is structured as a **Mobile App Monorepo** containing core applications and modularized, domain-isolated Dart/Flutter packages for mobile apps.

### Environment & Tooling

- **Flutter Version Management:** Managed exclusively via **fvm** (`https://fvm.dev/`). Do **NOT** use global untracked Flutter installations.
- **Determinism Rule:** The `pubspec.lock` file is the absolute source of truth for dependencies. **Never** add `pubspec.lock` to `.gitignore`. It must be committed on every dependency alteration to guarantee identical builds across all agent environments and the CI pipeline.
- **SDK Constraints:** Always respect the minimum Flutter/Dart SDK constraints declared in `pubspec.yaml`.
- **Environment Variables:** Keep local runtime configuration in the root
  `.env` file, using `.env.example` as the committed template. The app reads
  `ENVIRONMENT` and `CATAQUI_API_URL` through Envied-generated Dart code.
  Regenerate code after changing `.env` values.

### Architecture & Frameworks

- **State Management:** **Riverpod** (preferring code-generation workflows via `@riverpod`).
- **Networking Layer:** **Dio** (configured with explicit interceptors for standardized error handling and clean timeout controls).
- **Local Persistence:** High-performance local cache engine (e.g., Isar/Hive) used for offline-first geographic feed continuity.

---

## 2. Monorepo Guardrails & Package Rules

To maintain absolute structural health across the monorepo, follow these modularization rules:

- **Domain Isolation:** Code within local packages must communicate across boundaries using clean, explicit public APIs. Do not leak internal implementation layers.
- **Reusable UI Elements (`qui`):** All UI elements that can be reused further must live in a package called `qui`, which stands for Cataquí UI.
- **Local Dependencies:** Declare cross-package dependencies inside `pubspec.yaml` using exact relative paths:

```yaml
dependencies:
  oh_my_flutter:
    path: ../oh_my_flutter
```

- **Task Orchestration:** Always execute tasks using the workspace's designated monorepo tool (e.g., **Melos** or specific workspace scripts) when performing multi-package operations.

---

## 3. Coding Conventions (Dart & Flutter)

### Clarity Over Cleverness

Write explicit, boring, readable production code. Avoid speculative abstractions, magic numbers, and hyper-condensed naming conventions.

- **Bad:** `final p = await repo.find(id);`
- **Good:** `final post = await _postsRepository.findById(postId: postId);`

### Strong Type Safety

- **Strictly Avoid `dynamic`.** Use explicit types, Data Transfer Objects (DTOs), or sealed classes.
- If data input is truly unknown (e.g., raw JSON streams), narrow the types immediately at the boundary layer using runtime checks before propagating data into the business logic.

### Named Parameters & Immutability

- Always use **named parameters** for functions and constructors containing more than a single primitive parameter.
- Enforce immutability on domain models (`@immutable` or code-generated immutable data classes) using deep `copyWith` patterns for state transitions.

### Enums Over Constant Objects

- Prefer Dart `enum` structures over arbitrary `const` objects or magic strings for state variations, domain constants, and error codes. Use switches over enums to guarantee compile-time exhaustiveness.
- Keep enums in a separate enum-specific `part` file instead of placing them at the top of the primary implementation file. Name the file after the owner plus `_enums.dart`, for example `qui_text_button_enums.dart`, not a generic `*_types.dart` file. The main file must declare the matching `part` directive, and the enum file must use `part of` so the public API stays cohesive while the implementation file remains focused.

### Exhaustive Switch Over Enums

- **Never use a `default` or wildcard (`_`) clause** in a `switch` expression or `switch` statement over a Dart `enum` type. Every variant must be listed explicitly. This guarantees that adding a new enum value produces a compile error at every use site instead of silently falling through a default — which would otherwise mask the new value and introduce logic bugs that only surface at runtime.

### Types & Callback Aliases

- Reusable typedefs and public callback/function types must live in a dedicated
  `*_types.dart` file for their widget, component, or feature owner.

### One Implementation Class Per File

Every source file must contain **at most one** implementation class (a class with fields, methods, or widget logic). Pure value classes (`const` constructors, no logic) may coexist in the same file as their primary consumer if they have no implementation of their own. The only exception is Flutter `StatefulWidget` / `ConsumerStatefulWidget` pairs: the main widget class and its private `_*State` class must always stay in the same file. Files that grow beyond this limit must be split using same-directory `part` files with the `part of` directive, following the established `qui_location_radius_map` folder structure.

### Constants Local to Widgets

- Do **not** extract a value into a named constant unless it is used in **more than one place**. Single-use values should be inlined directly at the usage site. This avoids unnecessary indirection and keeps the widget code lean.

### Component Architecture (UI Layer)

- **Keep Widgets Lean:** Break down bloated `build` methods into small, single-responsibility `ConsumerWidget` or `HookConsumerWidget` components.
- **Scoped Re-renders:** Ensure Riverpod ref watch calls (`ref.watch`) are highly granular. Avoid watching entire complex state models when only a single property is required by the widget layout.
- **Widget Method Ordering:** In Flutter widget classes, place helper methods that do not return widgets above `build`. Helper methods that return widgets must stay below `build`.

### Early Returns Over if/else

- Prefer early returns over if/else branches. They reduce nesting and make the non-viable paths immediately visible.
- if/else chaining should be deeply avoided — it forces the reader to hold all branches in their head to understand each one. Only chain if/else when no cleaner alternative exists (e.g. exhaustive switch over an enum with 3+ cases, or a genuinely unavoidable three-way choice that cannot be decomposed).
- When a function has a guard clause, return early and avoid wrapping the entire body in an if block:

```dart
// Good — guard returns early, main path is flat
void _resumeOrSkipTransition() {
  if (_phase == QuiWidgetTransitionPhase.idle) return;
  if (_isDisabled) {
    _skipToIdle();
    return;
  }
  _animationController.forward();
}
```

```dart
// Avoid — else adds unnecessary nesting
void _resumeOrSkipTransition() {
  if (_phase != QuiWidgetTransitionPhase.idle) {
    if (_isDisabled) {
      _skipToIdle();
    } else {
      _animationController.forward();
    }
  }
}
```

---

## 4. Testing Protocol

Untested business logic is considered broken code.

### Execution Pathways

All testing, analysis, and build routines must run within the **fvm** environment wrapper.

- **Run Tests:** `melos test` — interactive package selection, runs tests with per-package coverage HTML report
- **Analyze Code:** `melos analyze`

### Strict Regression Rule

Every bug fix must include a corresponding regression test. The test must accurately simulate and reproduce the failure state prior to the implementation of the fix, and pass completely afterward.

### Bug Fix Workflow: Test-First When Possible

When the root cause of a bug is clearly understood and a regression test can be written before modifying production code, follow **test-first**:

1. Write the regression test that reproduces the bug
2. Run it — **it must fail** (confirming the test correctly captures the bug)
3. Implement the fix in production code
4. Run the test again — **it must pass** (confirming the fix resolves it)

This guarantees the regression test is valid and not vacuously passing. If the exact cause is not yet clear or you cannot write a meaningful test before changing code, implement the fix first and add the regression test afterward. Use judgment: test-first is preferred when the path is clear; code-first is acceptable when exploration is still needed.

### Shared Test Mocks

- Use `mocktail` for shared test mocks, stubs, and verifications. App-level. Reusable mocks must live in `/test/mocks.dart`.

### Dedicated Test Files

Each source file must have its own dedicated test file. Do not collect unrelated
coverage in shared catch-all test files; place tests in a path that mirrors the
source owner, for example `lib/src/extensions/color_extension.dart` maps to
`test/extensions/color_extension_test.dart`.

### DTO Fixture Tests Must Override Under Test

When a test uses `XxxDto.fixture()` and asserts on a specific field, it **must**
override that field via `copyWith` on the fixture. This ensures the test is
isolated from fixture default changes.

- **Incorrect (test breaks if fixture default changes):**

```dart
test('when parsing a feed job, it should map the title', () {
  final job = FeedJobDto.fixture();
  expect(job.title, 'Descarregar Caminhão');
});
```

- **Correct (explicit override keeps test stable):**

```dart
test('when parsing a feed job, it should map the title', () {
  final job = FeedJobDto.fixture().copyWith(title: 'Descarregar Caminhão');
  expect(job.title, 'Descarregar Caminhão');
});
```

### One Assertion Per Test Case

Every individual test block must contain **exactly one** `expect` or assertion call. If verifying a complex workflow state requires multiple checks, explicitly split the assertions across cleanly named, isolated test scenarios.

- **Incorrect (Multiple Assertions):**

```dart
    test('should return a valid active post', () {
      final post = service.findById(postId: "123");
      expect(post, isNotNull);
      expect(post.title, equals("Garçom para Fim de Semana"));
      expect(post.status, equals(JobStatus.active));
    });
```

- **Correct (Isolated Atomic Assertions):**

```dart
    test('should return a post instance when found by ID', () {
      final post = service.findById(postId: "123");
      expect(post, isNotNull);
    });

    test('should map the correct title to the fetched post', () {
      final post = service.findById(postId: "123");
      expect(post.title, equals("Garçom para Fim de Semana"));
    });

    test('should return an active status for a new job opportunity', () {
      final post = service.findById(postId: "123");
      expect(post.status, equals(JobStatus.active));
    });
```

### Golden Testing Requirement

Every widget and screen created anywhere in this repository must have golden
tests covering all visual states (resting, active, error, loading, disabled,
etc.). Golden tests use the `alchemist` package and serve as the primary
visual regression guard.

- Use `goldenTest` from `alchemist` — not raw `matchesGoldenFile`.
- If a package or app does not already have golden-test infrastructure, set it
  up before adding or changing widgets/screens. Add `alchemist` as a
  `dev_dependency`, create `test/flutter_test_config.dart`, configure
  `AlchemistConfig` with the app/package theme, and commit the generated CI
  goldens.
- Configure `AlchemistConfig` so package-specific tokens resolve correctly
  (for example, `qui` uses `QuiTheme.light(primaryColor: ...)`).
- Each widget or screen must have a dedicated golden test file:
  `test/widgets/<widget_name>_golden_test.dart` or
  `test/screens/<screen_name>_golden_test.dart`.
- Scenarios must cover every distinct visual state the widget or screen can
  render (e.g., resting, focused, loading, error, disabled, frosted-glass
  variant).
- CI goldens (`test/**/goldens/ci/`) are committed to source control.
  Platform goldens (`test/**/goldens/macos/`, etc.) are gitignored.
- Run `melos goldens:update` (asks which package) or `melos goldens:update:all`
  (all packages) from the repository root to regenerate after
  intentional visual changes. The script filters to packages with
  `dart_test.yaml` and prompts for package selection like `melos test`.
  Review the diff before committing.
- Golden tests do not replace unit tests for non-visual logic. They
  complement them.

### Descriptive Naming Convention

All tests (unit, widget, and golden) must use a descriptive `when, should`
pattern for their descriptions to ensure intent and behavior are immediately
clear.

- **Format:** `when <condition/action>, it should <expected result>`
- **Example:** `when tapping the cross icon, it should go into rest mode`
- Avoid vague descriptions like `renders correctly` or `test login`.

---

## 5. Security, Trust, & Safety Safeguards

Cataquí operates as a highly dynamic, real-time, peer-to-peer marketplace. Trust is core infrastructure.

- **Zero Leakage:** Never leave hardcoded backend credentials, API secrets, bypass tokens, or development environment keys anywhere within the codebase or repository history.
- **Sensitive Operational Logic:** Keep anti-spam heuristics, geographic positioning obfuscation metrics, content moderation thresholds, and reporting/abuse telemetry completely protected. Never expose operational parameters within user-facing log streams or client-side layout files.

---

## 6. Language, Naming, & Domain Boundaries

### Brand & Code Naming Conventions

- **Human-facing Markdown & Documentation:** Use the accented, premium brand representation: **Cataquí**
- **Code Elements, Packages, Schemas, & File Paths:** Use pure ASCII-safe lowercase strings: `cataqui`

### Domain Taxonomy

Always adopt the direct, real-world vernacular of the street. Explicitly exclude corporate enterprise terminology from models, variables, methods, and classes.

| Prefer Simple Local Terms            | Avoid Corporate/Enterprise HR Jargon              |
| :----------------------------------- | :------------------------------------------------ |
| `post`, `job`, `task`, `opportunity` | `requisition`, `human_capital`, `talent_pipeline` |
| `worker`, `poster`, `user`           | `candidate`, `applicant`, `talent_acquisition`    |
| `category`, `city`, `neighborhood`   | `department`, `organizational_unit`               |

---

## 7. Agent Operational Constraints

When executing modifications inside this repository as an AI agent, you must strictly comply with the following behavior rules:

1.  **Context Enforcement:** This file takes absolute precedence over generic coding preferences, standard global LLM training defaults, or speculative architectural habits.
2.  **Sub-AGENTS.md Precedence:** Each repo, package, or product directory in this monorepo (e.g., `app/`, `qui/`, `oh_my_flutter/`) has its own `AGENTS.md`. Their rules **always prevail** over any colliding rule in this root `AGENTS.md`.
3.  **No Dead Code:** Do not leave commented-out blocks of logic, unused imports, experimental features, or speculative abstractions behind. Every single line of code must serve the immediate objective.
4.  **Dependency Lockdown:** Do not add external third-party pub packages unless explicitly instructed. Lean heavily on native Flutter/Dart capabilities and the repository's existing technical stack.
5.  **No Silent Contracts:** Never modify, rename, or delete public API boundaries, core Riverpod provider definitions, or common data model interfaces without analyzing downstream impacts across the entire monorepo workspace.
6.  **Fail Safely:** If a structural change cannot be safely implemented within these parameters, immediately halt execution, document the exact technical roadblock, and explicitly state the architectural trade-offs required to move forward.
7.  **README Sync:** The `README.md` at the project root is the authoritative source of project requirements (prerequisites, setup, scripts). Whenever you modify tooling, dependencies, setup steps, or any requirement that affects onboarding, you **must** update both `README.md` and `AGENTS.md` to stay in sync.
8.  **Low-End Device Gate:** Before implementing any request from the human, analyze whether the proposed solution will work performantly on low-end devices (2-4GB RAM, older SoCs, 60Hz displays common in Latin America). If the approach would only work well on high-end flagship devices, **stop** and warn the human explicitly, explaining why it fails on low-end hardware and suggesting alternatives. Every feature must work well on low-end devices first — top-end device support is a baseline, not a ceiling.
