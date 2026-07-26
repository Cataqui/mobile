# Cataquí Releases

This guide explains how changes already merged into `main` become a tested
mobile release. The pipeline is automation-first: contributors merge normal
feature PRs, Release Please maintains one release PR, and merging that release
PR promotes the candidate that was already tested.

Repository administration, credential provisioning, and store-account setup
are intentionally outside this guide.

## Mental model

```text
feature PRs → main → release PR → signed candidate → human approval
                                                     ↓
                      GitHub Release + App Review submission
```

The release PR is the control point. Additional releasable changes merged into
`main` update the same open PR and produce a new candidate. Nothing is published
to users until that release PR is merged.

The pipeline follows the
[Release Please release-PR model](https://github.com/googleapis/release-please#whats-a-release-pr):
the bot accumulates releasable commits, updates the changelog and version, then
creates the tag and GitHub Release after the release PR is merged.

## Release contract

### Version

`app/pubspec.yaml` is the only mobile version source:

```yaml
version: 1.3.0+42
```

- `1.3.0` is the public version shown by Android and iOS.
- `42` is the monotonically increasing Android `versionCode` and iOS
  `CFBundleVersion`.
- Release Please selects the semantic version.
- Candidate automation preserves the proposed build number or raises it to stay
  ahead of TestFlight.
- Release builds consume this value directly. Do not pass Flutter
  `--build-name` or `--build-number` overrides.

### Releasable changes

Release Please reads Conventional Commits from `main`:

| Commit            | Release effect |
| ----------------- | -------------- |
| `fix(app): ...`   | Patch          |
| `feat(app): ...`  | Minor          |
| `feat(app)!: ...` | Major          |
| `chore(app): ...` | No release     |

The `app` scope is preferred but does not determine the version bump. The commit
type and breaking-change marker do.

### Candidate identity

Every successful candidate records
`distribution/releases/v<version>/manifest.json`. It links the version,
candidate source commit, release-input tree hash, and production configuration.
The tree hash covers the app, locale package, workspace manifests and lockfile,
and pinned Flutter version. Only tracked source files participate, so generated
and ignored runner files cannot make verification platform-dependent.

The publication workflow promotes the tested iOS candidate:

- the existing TestFlight build is submitted for App Review.

Android store distribution is not configured.

Production publications are serialized so two versions cannot be submitted at
the same time. The workflow does not rebuild the app after approval. Any source
change that affects the binary requires a new candidate.

## Normal release flow

### 1. Merge normal work

Develop features and fixes in ordinary branches and merge them into `main`
after the safety checks pass. Multiple PRs can accumulate in one release.

### 2. Let automation prepare the candidate

After a releasable merge, Release Please creates or updates the open release PR
and calls the candidate workflow. The candidate workflow then:

1. updates `app/pubspec.yaml` and `app/CHANGELOG.md`;
2. reconciles the numeric build number;
3. generates localized store notes;
4. runs a signed Android release build and release lint with a disposable CI certificate;
5. uploads the matching iOS build to internal TestFlight;
6. records the candidate manifest in the release PR.

A later releasable merge into `main` updates the same release PR and replaces
the candidate with a newly built version.

### 3. Review and test

Before merging the release PR, verify:

- the proposed version and changelog describe the intended release;
- all candidate workflow jobs passed;
- the recorded candidate version matches `app/pubspec.yaml`;
- the internal TestFlight build was tested;
- every localized “What’s New” file is accurate;
- no app or locale source changed after the recorded candidate was built.

The release PR may be edited to improve generated release-note copy. A source
change belongs in a normal PR to `main`, which will produce a new candidate.

### 4. Merge to publish

Merging the accepted release PR is the publication approval. Release Please
creates the version tag and publishes the GitHub Release. That event starts the
production workflow, which verifies the recorded candidate and submits its
existing TestFlight build for App Review.

Do not manually create the release tag or submit a different iOS build under
the same candidate.

## Localized “What’s New”

The locale catalog lives in `packages/locale/lib/i18n/*.i18n.json`. The same
locale tags drive the app, generated release notes, and store metadata.

Candidate automation writes one editable file per locale:

```text
distribution/releases/v<version>/<locale>.txt
```

Generated copy is a draft. Review it for accuracy, tone, and store suitability
before approving the release. It must describe only user-visible changes in the
current changelog section.

## Failure and recovery

| Failure                                             | Correct response                                                                             |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Candidate preparation or build fails                | Fix the cause through a normal PR, then let the release PR update and build a new candidate. |
| Generated “What’s New” copy is poor                 | Edit the locale text files in the release PR and rerun its checks.                           |
| More work merges before release                     | Wait for the release PR and candidate to update, then test the newest candidate.             |
| Candidate artifact is missing or cannot be verified | Produce a new candidate; never reconstruct or substitute an old artifact.                    |
| App Review rejects the build                        | Land the fix on `main` and ship a new candidate with a new build number.                     |
| A published version has a serious defect            | Forward-fix it with a new patch release; released build numbers are never reused.            |

Retrying a failed candidate workflow is safe when its release branch has not
changed. A failed production workflow can be rerun against the same release tag;
it re-verifies the recorded candidate before publishing. If there is any doubt
about artifact identity, create and test a new candidate.

## Sources of truth

| Concern                                 | Repository source                                                |
| --------------------------------------- | ---------------------------------------------------------------- |
| Public version and build number         | `app/pubspec.yaml`                                               |
| Technical release history               | `app/CHANGELOG.md`                                               |
| Release Please behavior                 | `release-please-config.json` and `.release-please-manifest.json` |
| Release Please orchestration            | `.github/workflows/release-please.yml`                           |
| Candidate build and recording           | `.github/workflows/release-candidate.yml`                        |
| Android code checks                      | `.github/workflows/ci.yml`                                       |
| Build Android App Bundle                | `fvm dart run release:build_aab`                                 |
| Production publication                  | `.github/workflows/release.yml`                                  |
| Store upload lanes                      | `fastlane/Fastfile`                                              |
| Locale catalog                          | `packages/locale/lib/i18n/`                                      |
| Release implementation and verification | `packages/release/`                                              |
| Candidate notes and identity            | `distribution/releases/v<version>/`                              |
