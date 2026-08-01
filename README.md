<p align="center">
  <img src="app/assets/logos/cataqui.svg" width="96" alt="Cataquí logo">
</p>

<h1 align="center">Cataquí Mobile</h1>

<p align="center">
  The real-time opportunity layer of the city.
  Open Cataquí and immediately discover work happening nearby.
</p>

Cataquí is a fast, hyperlocal feed for quick jobs, side hustles, informal work,
and temporary tasks. The product loop is deliberately short:
**post an opportunity → discover it in the feed → make contact**.

This repository contains the Flutter client for Android and iOS. The current
mobile experience focuses on discovery: swipe through nearby opportunities,
open the full job, then contact the poster through WhatsApp or a phone call.

## What guides the product

| Principle            | What it means for contributors                                                                                          |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Immediate            | Startup work stays behind the native splash and the feed request begins early.                                          |
| Hyperlocal           | Opportunities are organized around neighborhoods and a privacy-preserving location radius, not an exact street address. |
| Low-end first        | Every screen, map, animation, and dependency must run well on the 2–4 GB devices common across Latin America.           |
| Human, not corporate | Language and UI should feel local, direct, and trustworthy, never like enterprise recruiting software.                  |
| Resilient            | Loading, offline, retry, pagination, empty, and end-of-feed states are first-class product states.                      |

## Run the app

### 1. Install the toolchain

| Tool                                                              | Version used by the project  | Notes                                                                                                |
| ----------------------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------------------------------------------- |
| [FVM](https://fvm.app/documentation/getting-started/installation) | latest                       | Installs and runs the pinned Flutter SDK.                                                            |
| Flutter                                                           | `3.44.0`                     | Declared in [`.fvmrc`](.fvmrc); do not use an untracked global SDK.                                  |
| Dart                                                              | Bundled with Flutter         | Run it through `fvm dart`.                                                                           |
| [Melos](https://melos.invertase.dev/getting-started)              | `8.2.2`                      | Orchestrates the Dart workspace from the repository root.                                            |
| Android or iOS tooling                                            | Current Flutter requirements | Follow Flutter's [platform setup](https://docs.flutter.dev/install). iOS development requires macOS. |

### 2. Clone and configure

```bash
git clone https://github.com/Cataqui/mobile.git
cd mobile

fvm install
fvm dart pub global activate melos 8.2.2
```

If `melos` is not found afterward, add the Dart global executable directory to
your shell:

```zsh
export PATH="$PATH:$HOME/.pub-cache/bin"
```

The Flutter flavor selects the app runtime environment:

- `development` uses the staging API, installs as `Cataquí Dev`, and uses
  `com.cataqui.mobile.development`.
- `production` uses the production API, installs as `Cataquí`, and keeps the
  store identifier `com.cataqui.mobile`.

The separate identifiers let both variants stay installed on the same device.
Always pass a flavor explicitly; this prevents an unintentional production run
or a development build carrying the production identity.

Release automation, artifact signing, and store submission are intentionally
not configured in this repository. Android development builds use the local
debug certificate in every build mode so `fvm flutter run --release --flavor
development` can be installed on a device. Production release artifacts remain
unsigned until store signing is configured.

### 3. Set up and launch

Run workspace commands from the repository root unless a command explicitly
changes directories:

```bash
melos setup

cd app
fvm flutter run --flavor development
```

`melos setup` is the canonical repository setup command. It installs
everything needed to work in this repository.

Run `fvm flutter doctor` if launch fails and resolve any issue for the platform
you intend to use.

The first successful launch keeps the native splash visible while essential
local state loads, then opens the feed. To select a device explicitly:

```bash
cd app
fvm flutter devices
fvm flutter run --flavor development -d <device-id>
```

To exercise optimized Android code locally, keep the development flavor:

```bash
fvm flutter run --release --flavor development -d <device-id>
```

> [!TIP]
> VS Code users can select **App (Debug)** from the checked-in launch
> configurations. The workspace already points the Dart extension at the FVM
> SDK.

## Understand the codebase

The app uses feature-oriented slices. A typical request follows this path:

```text
route → view → Riverpod state → repository → Dio → Cataquí API
                  ↓
              typed DTOs
```

The main technical boundaries are:

- [Riverpod](https://riverpod.dev/) with generated providers for state and dependency injection.
- [Dio](https://pub.dev/packages/dio) repositories for network access.
- [go_router](https://pub.dev/packages/go_router) with generated typed routes.
- Freezed and JSON serialization for API models.
- [slang](https://pub.dev/packages/slang) in `app/lib/i18n` for app-owned translations.
- [Mateo Mobile](https://github.com/Ventairy/mateo/tree/main/mobile/packages/mateo_mobile_flutter) for the design system.
- [Alchemist](https://pub.dev/packages/alchemist) for golden testing

### Everyday commands

| Task                           | Command                |
| ------------------------------ | ---------------------- |
| Regenerate generated code      | `melos gen`            |
| Format code                    | `melos format`         |
| Analyze every workspace member | `melos analyze`        |
| Run the test suite             | `melos test`           |
| Update goldens                 | `melos goldens:update` |

`melos format` is built into Melos and formats every package in the workspace,
including packages added later. No path list needs to be maintained.

Run `melos gen` after changing Riverpod providers, routes, DTOs, generated
assets, or translation sources under
`app/lib/i18n`. It also synchronizes native iOS locales. Generated
Dart files are git ignored; source definitions are the reviewable contract.

`melos test` additionally produces HTML coverage reports. It is a local
convenience command that requires LCOV's `genhtml` and currently opens the
report with the macOS `open` command. The no-coverage command above is the
portable pre-submit gate used by CI.

## License and contributions

Cataquí Mobile is **source-available**, not OSI-approved open source. The
[PolyForm Shield License 1.0.0](LICENSE) lets you inspect, modify, and share the
software for permitted purposes, but does not permit using it to provide a
competing product—even when that product is free.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
Contributors retain ownership of their work and license submissions under the
same PolyForm Shield terms that apply to the repository.

The software license does not grant rights to Cataquí names, logos, or other
brand identifiers. See [TRADEMARKS.md](TRADEMARKS.md).
