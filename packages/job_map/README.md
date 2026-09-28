# job_map

Internal Flutter plugin for Cataquí's Google Maps job cards on Android and iOS.
It owns map scene construction, adaptive render policy, frame caching, native
renderers, and the typed platform bridge. The consuming app owns job DTOs and
supplies visible and predicted map scenes through `MapFrameCoordinator`.

Import `package:job_map/job_map.dart` for the widget, scene, route lease,
coordinator, provider, and warmup API. Test fakes and surface overrides are
exported from `package:job_map/job_map_testing.dart`.

The host app must configure its Google Maps API keys before using the plugin.
The iOS integration uses Swift Package Manager and Google Maps SDK 9.

## Platform contract

`pigeons/job_map_api.dart` is the single contract for Dart, Kotlin, and Swift.
The workspace pins Pigeon 26.1.10. After changing the schema, run:

```sh
bash tool/pigeon.sh
```

Check that all generated sides are current with:

```sh
bash tool/pigeon.sh --check
```

Run focused package tests from this directory with `fvm flutter test`.
