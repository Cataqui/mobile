# AGENTS.md — Repositories

Repositories are raw transport boundaries. They forward request-specific values exactly as supplied and map transport
responses into typed DTOs. Do not trim, normalize, filter, debounce, validate search eligibility, synthesize local DTO
responses, or suppress requests based on presentation or workflow rules inside a repository. The owning Riverpod state
provider or controller decides whether and when to call the repository and performs any input preparation required by
that workflow. Pass typed response bodies directly to generated DTO factories with `response.data!`; field validation
belongs to generated DTO parsing. Do not add repository-side null guards or custom response-shape validation.

Repository classes follow a strict separation between reactive constructor
parameters and per-call function parameters:

- **Constructor params** — reserved for infrastructure the repository depends
  on for its entire lifetime, such as `Dio`. If the param changes, rebuilding
  the repository is the correct behavior.
- **Function params** — used for request-specific data that may change between
  calls without invalidating the repository instance. For example, `locale`
  should be passed directly to the method that needs it rather than injected
  at construction time, so locale changes don't force unnecessary widget
  rebuilds via Riverpod.
