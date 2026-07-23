# AGENTS.md — Cataquí Mobile

## 0. Mission & Core Philosophy

You are operating within the **Cataquí Mobile Repository**, a high-performance Flutter app workspace built using Flutter and Dart.

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

This repository is structured as a **Flutter app workspace**. Shared packages that used to live in this repository now live in their own repositories and are consumed like normal external dependencies.

### Environment & Tooling

- **Flutter Version Management:** Managed exclusively via **fvm** (`https://fvm.dev/`). Do **NOT** use global untracked Flutter installations.
- **Determinism Rule:** The `pubspec.lock` file is the absolute source of truth for dependencies. **Never** add `pubspec.lock` to `.gitignore`. It must be committed on every dependency alteration to guarantee identical builds across all agent environments and the CI pipeline.
- **SDK Constraints:** Always respect the minimum Flutter/Dart SDK constraints declared in `pubspec.yaml`.
- **Environment Variables:** Keep local runtime configuration in the root
  `.env` file, using `.env.example` as the committed template. The app reads
  `ENVIRONMENT` and `CATAQUI_API_URL` through Envied-generated Dart code.
  Regenerate code after changing `.env` values.
- **Startup Splash:** Keep essential asynchronous startup work in
  `AppBootstrap.setup()` so the native splash remains visible until bootstrap completes.

### Architecture & Frameworks

- **State Management:** **Riverpod** (preferring code-generation workflows via `@riverpod`).
- **Networking Layer:** **Dio** (configured with explicit interceptors for standardized error handling and clean timeout controls).
- **Local Persistence:** High-performance local cache engine (e.g., Isar/Hive) used for offline-first geographic feed continuity.

---

## 2. Workspace Guardrails & Package Rules

To maintain absolute structural health across the workspace, follow these modularization rules:

- **External Package Boundaries:** Shared packages are owned by their standalone repositories. Consume them through their published package APIs or explicitly configured local overrides for development.
- **Design System:** Cataquí uses
  [Mateo](https://github.com/Ventairy/mateo/tree/main/design-system) as its
  design system. Reusable mobile UI belongs in the design system's Flutter package rather than in the application.
- **Future Internal Packages:** If internal packages are added to this
  repository, add each package explicitly to the root `pubspec.yaml` workspace
  list and use exact relative paths from the consuming package:

```yaml
dependencies:
  cataqui_internal:
    path: ../cataqui_internal
```

- **Task Orchestration:** Always execute tasks using the workspace's designated tool (e.g., **Melos** or specific workspace scripts) when performing multi-member operations.

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
- Keep enums in a separate enum-specific `part` file instead of placing them at the top of the primary implementation file. Name the file after the owner plus `_enums.dart`, for example `app_button_enums.dart`, not a generic `*_types.dart` file. The main file must declare the matching `part` directive, and the enum file must use `part of` so the public API stays cohesive while the implementation file remains focused.
- **Enum-owning logic over static helpers:** When logic is determined solely by an enum value (color resolution, label text, icon selection, etc.), put the getter or method on the enum itself rather than writing a static function on an implementation class. This keeps the resolution logic with the value that drives it, makes it discoverable from any call site via `myValue.method()`, and eliminates duplicate switch statements across consumers. The enum member is the single source of truth for its own behavior.

### Exhaustive Switch Over Enums

- **Never use a `default` or wildcard (`_`) clause** in a `switch` expression or `switch` statement over a Dart `enum` type. Every variant must be listed explicitly. This guarantees that adding a new enum value produces a compile error at every use site instead of silently falling through a default — which would otherwise mask the new value and introduce logic bugs that only surface at runtime.

### Types & Callback Aliases

- Reusable typedefs and public callback/function types must live in a dedicated
  `*_types.dart` file for their widget, component, or feature owner.
- Single-use typedefs are forbidden. If a function/record type is referenced in
  only one place, declare it inline at the usage site instead of extracting a
  typedef. Extract a typedef only when the same signature is used in more than
  one place (mirroring the "Constants Local to Widgets" rule).

### One Implementation Class Per File

Every source file must contain **at most one** implementation class (a class with fields, methods, or widget logic). Pure value classes (`const` constructors, no logic) may coexist in the same file as their primary consumer if they have no implementation of their own. The only exception is Flutter `StatefulWidget` / `ConsumerStatefulWidget` pairs: the main widget class and its private `_*State` class must always stay in the same file. Files that grow beyond this limit must be split using same-directory `part` files with the `part of` directive, following the established grouped-widget folder structure.

### No Top-Level Functions

Free-standing top-level functions are not permitted. Every function must be a
method on a class:

- **`static`** when the function has no dependency-injection needs (no `Ref`,
  no widget state, no provider access). Static methods keep the call site
  explicit (`MyClass.myMethod()`) and prevent scope pollution.
- **Instance** when the function may need dependency injection (e.g., access to
  Riverpod `Ref`, widget `State`, or other injected dependencies).

Pure utility functions (formatting, measurement, computation) must live as
`static` methods on the class that owns the domain they serve — typically the
widget or model that produces or consumes the data.

- **Do not mark a helper `static` if its only caller is an instance method.**
  A function should only be `static` when it is called from multiple contexts
  or has no logical tie to instance state. If an instance method is the sole
  caller, make it an instance private method instead — this keeps the calling
  convention consistent and avoids the `static` keyword as a ceremonial
  ceremony that adds no value.

### Constants Local to Widgets

- Do **not** extract a value into a named constant unless it is used in **more than one place**. Single-use values should be inlined directly at the usage site. This avoids unnecessary indirection and keeps the widget code lean.
- **Name your math:** When combining numbers in an expression where each operand's meaning is not immediately obvious (e.g. `width - 30 - 12 - 14 - 26`), extract each operand into a named constant so the expression reads as intent. Simple standalone values like `padding: 24` do not need extraction — the position tells you what the number means.
- **Linked layout constants:** When a calculation depends on a layout value defined elsewhere (padding, icon size, gap, etc.), store the shared value as a constant and reference it in both locations. This guarantees the two sites can never drift apart and makes the dependency explicit to readers.

### Shared Constants Across Files

- **Never** duplicate the same logical value as independent variables in separate files. When a value (size, duration, threshold, etc.) is shared across files, define it once as a **static const** on the class that owns the domain (e.g. `FeedView.indicatorSize`), and reference it everywhere the value is needed.
- Never use top-level constants (`const double myConstant = ...`) for shared values — they pollute the library namespace and bypass the owning class. Always put the constant as a `static const` member on the relevant class.
- When you encounter a value that already exists in two or more places, extract it into a single shared `static const` and create a test that verifies all consumers reference the same shared constant. This prevents silent desync when the value is updated in only one location.

### Component Architecture (UI Layer)

- **Keep Widgets Lean:** Break down bloated `build` methods into small, single-responsibility `ConsumerWidget` or `HookConsumerWidget` components.
- **Scoped Re-renders:** Ensure Riverpod ref watch calls (`ref.watch`) are highly granular. Avoid watching entire complex state models when only a single property is required by the widget layout.

### Method Ordering Within Classes

Every class must follow a consistent top-to-bottom method ordering so that related concerns are easy to find.

#### General Classes (Non-Widgets)

1. **Constructor fields** — `final` instance fields initialized via `this.xxx` in the constructor. List public fields first, then private fields. These are the class's primary inputs.
2. **Static public members** — `static` fields and methods usable by external callers.
3. **Static private members** — `static` helpers scoped to the class.
4. **Instance fields (non-constructor)** — `final`/`var` fields with inline initializers (`final name = defaultValue`). These are secondary state, not primary inputs.
5. **Instance public methods** — public instance methods (including getters and setters) that do not override a superclass member.
6. **Instance private methods** — private instance methods (including getters and setters) that do not override a superclass member.
7. **Overrides** — `@override` methods (lifecycle, operator overloads, interface implementations).

#### Widget Classes (StatefulWidget + State, StatelessWidget, ConsumerWidget, etc.)

1. **Constructor** — the widget's constructor.
2. **Static public members** — `static const` fields, `static` methods (including those returning Widget).
3. **Static private members** — `static const` private fields, `static` methods (including those returning Widget).
4. **Instance public fields** — `final`/`var` public fields (rare in widgets).
5. **Overrides** — `@override` methods in this exact order:
   - `createState()` (StatefulWidget only)
   - `didChangeDependencies()` (State only)
   - `didUpdateWidget()` (State only)
   - `dispose()` (State only)
   - `build()` / `build(BuildContext)` (always the last override)
6. **Private builder functions** — `_buildFoo()` methods that return Widget, called from `build()`.
7. **Private helper functions** — `_doSomething()` methods that return non-Widget values.
8. **Public helper functions** — public instance methods that return non-Widget values (rare).

#### State Classes

For `State<T>` subclasses the ordering above is adjusted so
private helpers are discovered before the lifecycle methods they
serve:

1. **Static public members**
2. **Static private members**
3. **Instance public fields** (must be `@visibleForTesting`; otherwise keep `private`)
4. **Instance private fields**
5. **Private helper functions** — `_doSomething()` methods that return non‑Widget values, ordered from most generic to most specific.
6. **Overrides** — `@override` methods in this exact order:
   - `initState()`
   - `didChangeDependencies()`
   - `didUpdateWidget()`
   - `dispose()`
   - lifecycle observer overrides (e.g. `didChangeAppLifecycleState`)
   - `build()` / `build(BuildContext)` — always the last override
7. **Private builder functions** — `_buildFoo()` methods that return Widget, called from `build()`.
8. **Public helper functions** — do **not** exist in a `State` class.

### Universal Extensions (One Per Type)

Extensions on a given type must live in a single shared file, not in dedicated
per-feature files. This avoids scattering multiple `extension on X` declarations
across the codebase and keeps the import surface minimal.

Apply this to every extension type: `WidgetExtension`, `StringExtension`,
`ColorExtension`, `BuildContextExtension`, and so on.

```dart
// Good — one extension per type, all methods on that type live together:
extension WidgetExtension on Widget {
  Widget skeleton({bool enabled = true, bool shimmer = true}) { ... }
  Widget fadeIn(...) { ... }
}

// Avoid — multiple per-feature extensions on the same type:
extension SkeletonExtension on Widget { Widget skeleton() { ... } }
extension FadeInExtension on Widget { Widget fadeIn() { ... } }
```

### Subdirectory Per File Group

Whenever a set of files is related to a single primary subject (e.g., a widget split into `HeroBox` and `_HeroBoxContent`, or a class with separate `_types`, `_enums`, or `_providers` files), **all related files must be placed under a dedicated subdirectory** named after the primary subject — even if a broader parent folder already exists.

For example, instead of:

```
hero/
  hero_box.dart
  hero_box_content.dart
```

place files under:

```
hero/hero_box/
  hero_box.dart
  hero_box_content.dart
```

This rule applies to any group of companion files: main implementation, private sub-widgets, enums, types, providers, tests, and golden test scenarios. Use a flat file layout only when a folder contains exactly one self-contained subject file with no companion files.

### Early Returns Over if/else

- Prefer early returns over if/else branches. They reduce nesting and make the non-viable paths immediately visible.
- if/else chaining should be deeply avoided — it forces the reader to hold all branches in their head to understand each one. Only chain if/else when no cleaner alternative exists (e.g. exhaustive switch over an enum with 3+ cases, or a genuinely unavoidable three-way choice that cannot be decomposed).
- When a function has a guard clause, return early and avoid wrapping the entire body in an if block:

```dart
// Good — guard returns early, main path is flat
void _resumeOrSkipTransition() {
  if (_phase == WidgetTransitionPhase.idle) return;
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
  if (_phase != WidgetTransitionPhase.idle) {
    if (_isDisabled) {
      _skipToIdle();
    } else {
      _animationController.forward();
    }
  }
}
```

### Color Scheme: Always Use Design-System Tokens

**Never hardcode color values** (`Colors.blue`, `Color(0xFF...`) in widget code, tests, or any UI layer. Resolve colors from the active design-system theme:

- **Semantic colors:** Prefer semantic roles such as background, primary text,
  borders, and component states.
- **Raw palette:** Use raw palette steps only when no semantic token exists.
- **Import:** Use the design system's public package entrypoint.

### Dart Documentation

- **Public API requires Dart doc.** Every declaration visible outside its library (public classes, public members, public typedefs, top-level constants) must have a `///` doc comment explaining what it does, when to use it, and what callers must know.
- **Internal code does not need Dart doc.** Private declarations (`_`-prefixed), library-internal declarations (in packages, anything not exported via `library` or `export`), and any symbol that cannot be reached from outside its owning file or package does not require a doc comment. The code itself — clear naming, strong types, small functions — is the documentation.
- When in doubt about whether something is public API, check whether it is exported by the package's main barrel file or referenced in another package's imports. If it is not reachable from outside, treat it as internal and skip the doc comment.

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

**Hard rule:** Tests for a given source file must always live in the test file
that mirrors it. e.g Never place tests for `color_extension.dart` in
`omf_oklch_test.dart` or any other file. If a source file adds a new public
method, the test for that method goes in the existing corresponding test file —
never in a different file.

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

### Relative-Time Tests Must Pin Time

Any test that renders or asserts relative time text (for example, `3h atrás`,
`1 dia atrás`, `X time ago`, or any value derived from `DateTime.now()`,
`clock.now()`, or elapsed durations) must pin both sides of the calculation:

- Pin the current time with `package:clock` or the existing project test helper.
- Set fixture dates explicitly relative to that fixed instant, instead of
  relying on fixture defaults or the real current date.
- For Alchemist golden tests, ensure the fixed clock is active during the actual
  pump/render step (`pumpWidget`, `pumpBeforeTest`, and any interaction such as
  scroll or drag), not only while constructing the widget. Alchemist may build
  or repaint later than the `builder` callback.
- Never approve golden changes caused only by calendar time passing. Fix the
  clock/date setup first, then regenerate goldens only if the stable output is
  intentionally different.

This prevents tests from breaking as days pass and keeps visual baselines
deterministic.

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
- Configure `AlchemistConfig` so package-specific tokens resolve correctly.
- Each widget or screen must have a dedicated golden test file:
  `test/widgets/<widget_name>_golden_test.dart` or
  `test/screens/<screen_name>_golden_test.dart`.
- Scenarios must cover every distinct visual state the widget or screen can
  render (e.g., resting, focused, loading, error, disabled, frosted-glass
  variant).
- CI goldens (`test/**/goldens/ci/`) are committed to source control.
  Platform goldens (`test/**/goldens/macos/`, etc.) are gitignored.
- Run `melos goldens:update` (asks which package) or `melos goldens:update:all`
  (all workspace members) from the repository root to regenerate after
  intentional visual changes. The script filters to workspace members with
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

### Test Descriptions as Documentation

Test descriptions must be **self-documenting**: a maintainer reading only the
descriptions should understand how the app behaves without reading the test body.

- Descriptions must spell out **which user action** is performed and **what the
  app does** in response, in plain user-facing language.
- Avoid jargon that refers to internal implementation details (e.g.,
  `isLoadingMore`, `_isAwaitEligible`, `_dragOffsetY`).
- When describing a multi-step interaction, include the full sequence of user
  actions and the resulting state so a failing test name is immediately
  actionable.
- **Good:** `when on the last card while loading more, after swiping up to enter
the waiting scale then swiping back down to exit, swiping down again navigates
to the previous card`
- **Bad:** `when exiting await and swiping down again, it should navigate to the
previous item instead of re-entering await` (uses internal state terms like
  "await" and "re-entering")
- **Bad:** `when rendering state after exiting from await, it should match the
approved goldens` (does not describe what the user sees)
- This applies to **all** test types: unit, widget, golden, integration.

### Prefer `pumpAndSettle` Over `pump`

In widget and golden tests, use `pumpAndSettle` over `pump` unless only `pump` is needed (e.g., asserting in-progress animation state, or avoiding infinite pump loops). `pumpAndSettle` waits for all animations, timers, and microtasks to complete, producing more realistic test frames and reducing flakiness from un-settled widget states.

### Always `pumpAndSettle` After `pumpWidget`

Always call `pumpAndSettle` immediately after `pumpWidget` before performing any action (taps, scrolls, assertions). The `pumpWidget` call only creates the initial frame; `pumpAndSettle` ensures all microtasks, timers, and animations have fully resolved before the test interacts with the widget tree. Skipping this step leads to flaky tests where widgets appear loading instead of their settled state.

**Exception:** When the widget intentionally shows an infinite loading state (e.g., `AsyncLoading` with a never-completing `Completer`), use a single `pump()` instead of `pumpAndSettle` to avoid the framework timing out waiting for the state to settle.

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
2.  **Sub-AGENTS.md Precedence:** Each repo, package, or product directory in this monorepo (e.g., `app/`) has its own `AGENTS.md`. Their rules **always prevail** over any colliding rule in this root `AGENTS.md`.
3.  **No Dead Code:** Do not leave commented-out blocks of logic, unused imports, experimental features, or speculative abstractions behind. Every single line of code must serve the immediate objective.
4.  **Dependency Lockdown:** Do not add external third-party pub packages unless explicitly instructed. Lean heavily on native Flutter/Dart capabilities and the repository's existing technical stack.
5.  **No Silent Contracts:** Never modify, rename, or delete public API boundaries, core Riverpod provider definitions, or common data model interfaces without analyzing downstream impacts across the entire monorepo workspace.
6.  **Fail Safely:** If a structural change cannot be safely implemented within these parameters, immediately halt execution, document the exact technical roadblock, and explicitly state the architectural trade-offs required to move forward.
7.  **README Sync:** The `README.md` at the project root is the authoritative source of project requirements (prerequisites, setup, scripts). Whenever you modify tooling, dependencies, setup steps, or any requirement that affects onboarding, you **must** update both `README.md` and `AGENTS.md` to stay in sync.
8.  **Low-End Device Gate:** Before implementing any request from the human, analyze whether the proposed solution will work performantly on low-end devices (2-4GB RAM, older SoCs, 60Hz displays common in Latin America). If the approach would only work well on high-end flagship devices, **stop** and warn the human explicitly, explaining why it fails on low-end hardware and suggesting alternatives. Every feature must work well on low-end devices first — top-end device support is a baseline, not a ceiling.
9.  **Revert on Failed Fix:** If a bug-fix attempt changes production code and the fix does not resolve the issue (tests still fail, behavior unchanged, or new failures introduced), revert all changes from that attempt immediately before trying a different approach. Never leave speculative, non-working, or partially-applied changes in the codebase — they are dead code that can introduce new bugs or confuse future readers.
10. **Debug Before Fixing:** When the root cause of a bug is not immediately clear, do not attempt a speculative fix. Instead, first work with the human to understand the environment and reproduce the issue. Add diagnostic logging (`debugPrint`, `log`, or similar) to the relevant code paths, then ask the human to run the app, reproduce the bug, and share the log output. Only propose a fix after the logs have revealed the actual cause. This applies even when you think you know the fix — if you cannot explain the root cause with evidence, you are guessing, and guessing is not fixing.
11. **No Unsolicited Changes:** Never modify, rename, delete, or create files that the human did not directly ask about. If you think something should be changed, ask permission first. Only make changes that are explicitly requested or directly required to fulfill the requested task.
12. **Fix Lints, Don't Suppress Them:** When the analyzer reports a warning or info-level lint, always fix the underlying code first. Only add `ignore_for_file` as a last resort when the lint is a known false positive (e.g., `cascade_invocations` on `void`-returning methods) or when the pattern is genuinely intentional and documented with a comment explaining why. Every `ignore_for_file` must have a comment immediately above it explaining why the lint cannot be fixed.
