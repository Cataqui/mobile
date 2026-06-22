# AGENTS.md — oh_my_flutter

## What is oh_my_flutter?

`oh_my_flutter` is a Flutter/Dart utility and superpower package — a grab-bag of
extensions, helpers, Dio interceptors, exception types, and reusable patterns
that make everyday Flutter development faster and more ergonomic.

It is **not** a domain-specific package (that belongs elsewhere, e.g. Cataquí
models or API clients). It is general-purpose: any Flutter project could benefit
from importing it.

## Omf Prefix Rule

Every **public class, mixin, enum, extension, or typedef** exported by this
package **must** be prefixed with `Omf`.

**Rationale:** A consumer importing multiple packages should immediately know
which namespace a symbol belongs to. The `Omf` prefix (short for
**O**h_**M**y_**F**lutter) makes the origin unmistakable at the call site
without requiring the developer to check the import statement.

```dart
// Good — clearly from oh_my_flutter
class OmfOfflineErrorDioInterceptor extends Interceptor { ... }

// Bad — ambiguous origin
class OfflineErrorDioInterceptor extends Interceptor { ... }
```

This rule applies to everything in the barrel export (`lib/oh_my_flutter.dart`).
Internal (`src/`) classes that are **not** exported are exempt from this rule.
