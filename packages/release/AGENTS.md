# AGENTS.md — Release Tooling

## Scope

These instructions apply to `packages/release/` and take precedence over the
root testing rules when they conflict.

This package owns internal Dart tooling for preparing, building, verifying, and
publishing Cataquí mobile releases. Keep release orchestration here. Fastlane
remains responsible for platform-native store operations.

## Commands

Run commands through the repository's FVM-managed workspace:

- Format the workspace: `melos format`
- Analyze the workspace: `melos analyze`
- Test this package: `cd packages/release && fvm dart test`
- Generate package code: `melos gen`
- Build a signed AAB after production code generation:
  `fvm dart run release:build_aab`

## Testing Boundary

Test deterministic release logic thoroughly. This includes parsing, validation,
serialization, versioning, path resolution, generated configuration contents,
artifact inspection, and filesystem restoration or cleanup that can be tested
without distorting production code.

External process orchestration may remain without unit tests when making it
testable would add production-facing indirection or artificial injection seams.
Examples include:

- code generation and Flutter SDK commands;
- Gradle, Java, Fastlane, and Git operations;
- process launching and inherited standard input or output;
- network downloads used only to obtain release tooling;
- store APIs and other external release services.

Do not introduce or retain abstractions such as `processRunner`, fake
downloaders, command-recording callbacks, or similar parameters solely so a
test can replace an external tool. A thin command that delegates to a trusted
tool may be verified by running the real command locally or in CI instead.

If behavior can be extracted into a small deterministic component without
complicating the production API, extract and test that component. Bug fixes in
deterministic logic still require regression tests. When an external
orchestration path is intentionally not unit-tested, state which real command or
CI gate verifies it.

## Release Code Rules

- Keep commands explicit, fail closed, and non-interactive.
- Never print signing credentials, service-account credentials, or secret
  contents.
- Materialize signing files only for the shortest necessary lifetime and remove
  them in `finally` blocks.
- Keep code generation separate from Android artifact build commands. Generate
  production code before building or verifying Android release artifacts.
- Prefer standard Flutter, Gradle, Fastlane, and store tooling over custom
  reimplementations.
- Keep irreversible publication separate from build preparation and
  verification.
