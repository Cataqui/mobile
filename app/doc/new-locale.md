# Adding a new locale

Cataquí owns its translations in `lib/i18n/` and uses slang to generate the type-safe Dart catalog. Native system UI, including iOS permission prompts, uses platform localization resources and must be updated separately.

## 1. Add the slang catalog

1. Copy `lib/i18n/pt-BR.i18n.json` to `lib/i18n/<locale>.i18n.json`, using a BCP 47 locale identifier such as `en` or `es-MX`.
2. Translate every value. The project uses `missing_translation_strategy: fail`, so every locale must contain the complete base-locale key set.
3. Preserve each key's JSON structure and typed placeholders exactly. For example, `{count: int}` must remain typed and must not be renamed.
4. Keep related translation states nested under their owning concept, following `lib/i18n/AGENTS.md`.

From the repository root, regenerate translations and synchronize the native locale list:

```sh
melos run gen:i18n --no-select
```

Generated `strings*.g.dart` files must not be edited manually. Adding a catalog generates its `AppLocale` value, but it does not choose that locale for the user. Wire the generated value into the app's locale-selection behavior through `AppState.setLocale`. Change the default in `AppState.build` only when the product's default locale is intentionally changing.

## 2. Add native iOS strings

Create `ios/Runner/<locale>.lproj/InfoPlist.strings`. Add a localized entry for every user-visible `UsageDescription` key present in `ios/Runner/Info.plist`. For example:

```strings
"NSLocationWhenInUseUsageDescription" = "Localized explanation of how Cataquí uses the person's location.";
```

In Xcode, localize the Runner target's `InfoPlist.strings` resource for the new locale. Confirm that Xcode:

- adds the locale to the project's `knownRegions`;
- adds the locale file beneath the `InfoPlist.strings` variant group; and
- keeps `InfoPlist.strings` in the Runner target's Resources build phase.

Keep a complete fallback value for each usage-description key in `Info.plist`. `slang configure`, which runs through `gen:i18n`, updates `CFBundleLocalizations`; it does not create or translate `InfoPlist.strings`.

## 3. Check platform behavior

Android already preserves Flutter locale changes through the `locale|layoutDirection` activity configuration. If app-owned native Android text is introduced, add matching resources under an appropriate `android/app/src/main/res/values-<locale>/` directory. Android's system location permission dialog does not use an app-provided equivalent of the iOS usage-description string.

Update locale-sensitive widget tests and goldens for the new language. Pin any locale-dependent fixtures rather than relying on the host machine's language.

## 4. Validate the locale

From the repository root, run:

```sh
melos run gen:i18n --no-select
melos format
melos analyze
melos test
```

Build both native development variants. On iOS, inspect the built Runner bundle and confirm it contains `<locale>.lproj/InfoPlist.strings`. Finally, select the language in the app or iOS per-app language settings and manually verify Flutter text, Material-provided text, permission prompts, layout, truncation, and relevant accessibility labels.
