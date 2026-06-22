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

# Update approved visual goldens after intentional UI changes
melos goldens:update         # asks which package/app
melos goldens:update:all     # updates all packages/apps
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
