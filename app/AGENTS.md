# AGENTS.md — Cataquí App

## Purpose

`app` is the monorepo's **application entry point** — the primary mobile app for the Cataquí platform. It is the **sole consumer** of `qui` design system components and `cataqui_core` domain models.

Unlike the `qui` package (which must be portable and publicly distributable), the `app` package is **internal and single-purpose**. It orchestrates screens, widgets, services, and state specific to the Cataquí mobile experience.

## No Documentation for Internal Code

Code inside `app/` is **not a public API**. It is consumed exclusively by this application itself and by AI agents working on this repository.

- **No dartdoc (`///`) needed** on any class, method, field, or variable inside the `app` package. The code should be self-explanatory through naming, structure, and conventions alone.
- **No `@Preview` annotations** — they are only required in the `qui` package.
- Dartdoc is reserved for `qui` and `cataqui_core`, which may be published as standalone packages on pub.dev.

## Structure

```
app/lib/
├── main.dart          # App entry point
├── app.dart           # MaterialApp.router configuration
├── core/              # DTOs, providers, config
│   ├── dtos/          # Freezed JSON DTOs (generated)
│   └── providers.dart # App-level Riverpod providers
├── i18n/              # Slang translation files (pt-BR)
├── views/             # Screen-level widgets (pages/routes)
└── widgets/           # Reusable app-level widgets
```
