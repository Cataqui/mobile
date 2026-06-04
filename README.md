# Cataquí — Mobile

Cataquí is the real-time opportunity layer of the city: a fast, frictionless, hyperlocal feed for quick jobs, side hustles, informal work, and temporary tasks.

## Prerequisites

| Tool    | Version                    | Install                          |
| ------- | -------------------------- | -------------------------------- |
| Flutter | `3.44.0` (via fvm)         | [fvm.dev](https://fvm.dev)       |
| Dart    | Bundled with Flutter SDK   | via fvm                          |
| melos   | `^7.8.0` (global)          | `dart pub global activate melos` |
| lcov    | `^2.4` (for code coverage) | `brew install lcov`              |

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

# Run code generation
fvm dart run build_runner build --workspace --delete-conflicting-outputs
```

## Development

```bash
# Run tests with coverage (full pipeline: clean, test, merge, HTML, open browser)
melos test

# Individual coverage steps:
melos coverage:clean        # Remove all coverage artifacts
melos coverage:collect       # Run tests with --coverage
melos coverage:merge        # Merge all lcov.info files
melos coverage:html          # Generate HTML report
melos coverage:open          # Open HTML report in browser

# Static analysis
melos analyze

# Code generation (workspace-wide)
melos codegen
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
