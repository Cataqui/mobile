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

# Install dependencies
fvm flutter pub get

# Configure local environment variables
cp .env.example .env

# Run code generation
fvm dart run build_runner build --workspace --delete-conflicting-outputs
```

Before running the app, set the local environment variables in `.env`. Use `.env.example` as the committed template.

Regenerate code after changing environment values so [Envied](https://pub.dev/packages/envied) can refresh the generated Dart config.

The `app` package is configured for DTO code generation with Freezed and
json_serializable. Add DTOs with `freezed_annotation` and `json_annotation`
imports, then regenerate with `melos gen:all`. Generated `.freezed.dart` and
`.g.dart` files under `app/lib/core/dtos/` are gitignored.

## Development

```bash
# Run tests with coverage (interactive package selection)
melos test

# Run tests for all packages (no prompt)
melos coverage

# Individual steps:
melos coverage:clean        # Remove all coverage artifacts
melos coverage:collect       # Run tests with --coverage (no HTML)

# Static analysis
melos analyze

# Code generation (workspace-wide)
melos gen:all

# Update approved visual goldens after intentional UI changes
melos goldens:update
```

## Project Structure

```
Mobile/
├── app/                      # Main Flutter application
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── packages/
│       └── cataqui_core/         # Shared domain logic
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
