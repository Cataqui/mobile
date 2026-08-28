# AGENTS.md — Localization Catalog

## Group Related Translation States

When one concept has more than one related state, variant, or message, treat it
as a section and represent it with a nested JSON object. The object name owns
the concept, and its children describe the individual states. Do not flatten
the same relationship into multiple sibling keys with a repeated prefix.

```json
{
  "search": {
    "loadingSemanticLabel": "Buscando...",
    "empty": "Não achei nenhum lugar",
    "error": "Deu ruim aqui. Tenta de novo",
    "offlineError": "Tá sem internet parece"
  }
}
```

Avoid:

```json
{
  "searchLoadingSemanticLabel": "Buscando...",
  "searchEmpty": "Não achei nenhum lugar",
  "searchError": "Deu ruim aqui. Tenta de novo",
  "searchOfflineError": "Tá sem internet parece"
}
```

Keep a translation as a direct leaf only when it is genuinely standalone and
does not belong to a multi-state concept. Choose nesting by semantic ownership,
not merely to shorten generated accessor names.
