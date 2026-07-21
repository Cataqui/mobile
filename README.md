# Cataquí — Mobile

Cataquí is the real-time opportunity layer of the city: a fast, frictionless, hyperlocal feed for quick jobs, side hustles, informal work, and temporary tasks.

## Prerequisites

| Tool    | Version                  | Install                          |
| ------- | ------------------------ | -------------------------------- |
| Flutter | `3.44.0` (via fvm)       | [fvm.dev](https://fvm.dev)       |
| Dart    | Bundled with Flutter SDK | via fvm                          |
| melos   | `^7.8.0` (global)        | `dart pub global activate melos` |

### PATH setup

Add the Dart pub cache bin directory to your shell config:

```zsh
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Setup

```bash
# Install Flutter version
fvm install

# Configure local environment variables
cp .env.example .env

melos setup
```

Before running the app, set the local environment variables in `.env`. Use `.env.example` as the committed template.

Regenerate code after changing environment values so [Envied](https://pub.dev/packages/envied) can refresh the generated Dart config.

## Development

```bash
# Run tests with coverage (interactive package selection)
melos test

# Run tests without coverage (fast, for pre-commit hook)
melos test:no-coverage

# Run tests for all packages (no prompt)
melos coverage

# Individual steps:
melos coverage:clean        # Remove all coverage artifacts
melos coverage:collect       # Run tests with --coverage (no HTML)

# Static analysis
melos analyze

# Code generation (workspace-wide)
melos gen:all

# Code generation (interactive package selection)
melos gen

# Resolve dotdart from ../dotdart for local package development
melos dotdart:local

# Temporarily disable the local override and restore the committed v0.6.0 lock
melos dotdart:remote-lock

# Regenerate the iOS and Android native splash resources
melos generate_splash

# Update approved visual goldens after intentional UI changes
melos goldens:update         # asks which package/app
melos goldens:update:all     # updates all packages/apps
```

### dotdart development

The app and `qui` declare dotdart from the immutable public `v0.6.0` Git tag.
For local package work, the ignored root `pubspec_overrides.yaml` resolves the
sibling checkout at `../dotdart`; copy `pubspec_overrides.yaml.example` or run
`melos dotdart:local` to activate it.

Running Pub while the override is active changes `pubspec.lock` to a path
resolution. Before committing, testing a release checkout, or releasing Mobile,
run `melos dotdart:remote-lock`. That command temporarily disables the override,
regenerates the lock from `v0.6.0`, and restores the ignored override file. The
committed lockfile must always contain the Git resolution, never the local path.

### Git Hooks

This project uses [dart_husky](https://pub.dev/packages/dart_husky) to enforce code quality and commit conventions.

**Hooks run automatically on every commit:**

- `pre-commit` — runs `melos analyze` (static analysis across all packages) and tests only on packages with staged files (via `preset: melos` with `staged_only: true`). The commit is blocked if either fails.
- `commit-msg` — validates commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) format.

Hooks are automatically installed via `melos setup`. To install manually:

```bash
fvm dart run dart_husky install
```

To bypass hooks for an emergency commit (e.g. WIP):

```bash
git commit --no-verify -m "message"
```

---

### Commit Conventions

All commits must follow the Conventional Commits format:

```
<type>(<optional scope>): <subject>
```

| Type       | When to use                                                         |
| ---------- | ------------------------------------------------------------------- |
| `feat`     | A new feature                                                       |
| `fix`      | A bug fix                                                           |
| `chore`    | Maintenance, deps, tooling                                          |
| `docs`     | Documentation only                                                  |
| `style`    | Formatting, whitespace                                              |
| `refactor` | Code change, no feature or fix                                      |
| `test`     | Adding or fixing tests                                              |
| `build`    | Build system changes                                                |
| `ci`       | CI configuration                                                    |
| `perf`     | Performance improvement                                             |
| `revert`   | Revert a previous commit                                            |
| `agent`    | Agent-related files (`AGENTS.md`, `.agents/`, `.opencode/`, skills) |

**Examples:**

```bash
git commit -m "feat(feed): add location radius map"
git commit -m "fix: resolve null pointer in feed"
git commit -m "agent: add flutter-riverpod-expert skill"
git commit -m "chore(deps): update riverpod to 3.3.0"
git commit -m "test: add regression test for feed pagination"
```

## Project Structure

```
Mobile/
├── app/                      # Main Flutter application
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── packages/
│       └── oh_my_flutter/         # Flutter/Dart superpower utils
│           ├── lib/
│           ├── test/
│           └── pubspec.yaml
│       └── qui/                  # Reusable UI components
│           ├── lib/
│           ├── test/
│           ├── analysis_options.yaml
│           └── pubspec.yaml
├── pubspec.yaml              # Workspace root
└── .fvmrc                    # Flutter version pin
```
