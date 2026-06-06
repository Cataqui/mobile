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
- **DTO Code Generation:** The `app` package is configured with **Freezed** and
  **json_serializable** for immutable API DTOs and type-safe JSON conversion.
  Run `melos gen:all` after adding or changing generated DTOs. Generated
  `.freezed.dart` and `.g.dart` files under `app/lib/core/dtos/` are ignored.
- **DTO File Structure:** Keep exactly one DTO class per Dart source file.
  Shared enums may live in a dedicated non-DTO enum file.
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
  cataqui_core:
    path: ../cataqui_core
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

### Constants Local to Widgets

- Do **not** extract a value into a named constant unless it is used in **more than one place**. Single-use values should be inlined directly at the usage site. This avoids unnecessary indirection and keeps the widget code lean.

### Component Architecture (UI Layer)

- **Keep Widgets Lean:** Break down bloated `build` methods into small, single-responsibility `ConsumerWidget` or `HookConsumerWidget` components.
- **Scoped Re-renders:** Ensure Riverpod ref watch calls (`ref.watch`) are highly granular. Avoid watching entire complex state models when only a single property is required by the widget layout.

---

## 4. Testing Protocol

Untested business logic is considered broken code.

### Execution Pathways

All testing, analysis, and build routines must run within the **fvm** environment wrapper.

- **Run Tests:** `melos test` — interactive package selection, runs tests with per-package coverage HTML report
- **Analyze Code:** `melos analyze`

### Strict Regression Rule

Every bug fix must include a corresponding regression test. The test must accurately simulate and reproduce the failure state prior to the implementation of the fix, and pass completely afterward.

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
- Run `melos goldens:update` from the repository root to regenerate after
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
2.  **No Dead Code:** Do not leave commented-out blocks of logic, unused imports, experimental features, or speculative abstractions behind. Every single line of code must serve the immediate objective.
3.  **Dependency Lockdown:** Do not add external third-party pub packages unless explicitly instructed. Lean heavily on native Flutter/Dart capabilities and the repository's existing technical stack.
4.  **No Silent Contracts:** Never modify, rename, or delete public API boundaries, core Riverpod provider definitions, or common data model interfaces without analyzing downstream impacts across the entire monorepo workspace.
5.  **Fail Safely:** If a structural change cannot be safely implemented within these parameters, immediately halt execution, document the exact technical roadblock, and explicitly state the architectural trade-offs required to move forward.
6.  **README Sync:** The `README.md` at the project root is the authoritative source of project requirements (prerequisites, setup, scripts). Whenever you modify tooling, dependencies, setup steps, or any requirement that affects onboarding, you **must** update both `README.md` and `AGENTS.md` to stay in sync.
