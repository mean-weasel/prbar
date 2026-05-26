# T002 iOS Data Architecture Map

## Result

Done.

## Baseline

- Branch `codex/ios-github-data-sync` starts from `origin/main` at `0e351e1 Add iOS GitHub auth repository plumbing (#44)`.
- PR #44 added the auth/session/repository boundary, but PR and release activity remain sample-data backed.
- The iOS target is generated from `apple/project.yml`; `PRBar` includes both `apple/PRBar` and `apple/PRBarShared`.

## Current Data Flow

- `apple/PRBarShared/SampleData.swift` owns fixture `repositories`, `pullRequests`, and `releases`.
- `apple/PRBarShared/PRBarStore.swift` stores mutable arrays for `repositories`, `pullRequests`, and `releases`.
- `PRBarStore.sample(...)` still initializes PR and release arrays from `SampleData`.
- `PRBarApp` injects auth and repository providers, but it does not inject any PR/release activity provider.
- Repository selection is already persisted through `RepositorySelectionStoring`; activity views filter against `store.includedRepositories`.

## Screens Depending on Activity Data

- `apple/PRBar/PRs/PRsView.swift`
  - Uses `store.pullRequests` directly for calendar counts, daily merge chart, repo distribution, recent PRs, and repo detail navigation.
  - Uses `SampleData.today` as the calendar end date.
  - Filters by included repo IDs locally.
- `apple/PRBar/Releases/ReleasesView.swift`
  - Uses `store.releases` directly for calendar counts, selected release card, and date-grouped release rows.
  - Uses `SampleData.today` as the calendar end date.
  - Filters by included repo IDs locally.
- `apple/PRBar/Share/WorkCardRenderer.swift`
  - Uses `store.pullRequests` for shipping snapshot counts.
  - Uses `store.releases` and sometimes PRs in the evidence side.
  - Uses `SampleData.today` as the activity range anchor.
  - Respects included repositories, but evidence can include private items if the user intentionally includes private repos.

## Existing GitHub Service Seams

- `apple/PRBarShared/GitHubAuth.swift`
  - `GitHubSessionStoring` exposes stored `GitHubAuthSession` with access token.
  - `KeychainGitHubSessionStore` is the live session store.
  - `InMemoryGitHubSessionStore` supports deterministic tests.
- `apple/PRBarShared/GitHubRepositories.swift`
  - `GitHubRepositoryTransport` provides a synchronous data seam.
  - `URLSessionGitHubRepositoryTransport` performs live authenticated requests.
  - `FixtureGitHubRepositoryTransport` consumes fixture responses in order.
  - `GitHubRepositoryClient` already shows the local pattern for request builders, paged clients, payload mapping, and static providers.

## Tests and Verification

- `apple/PRBarTests/PRBarModelTests.swift`
  - Covers repo selection, PR filtering by selected day, release filtering by selected day, auth/session behavior, repository API request construction, repository pagination, and privacy defaults.
  - Has local test-only helper types at the bottom.
- `apple/PRBarUITests/PRBarUITests.swift`
  - `--ui-testing` launch path uses static fakes.
  - PR/release/share screens have smoke coverage, but the `pr` smoke profile only runs tab surface and share export tests.
- `scripts/ios-build.sh`, `scripts/ios-test.sh`, and `scripts/ios-ui-smoke.sh` are the local gates.
- `.github/workflows/ios.yml` runs build, `PRBarTests`, and PR UI smoke on `pull_request`, `merge_group`, and `push` to `main`.

## Likely First Slice Shape

The next vertical slice should introduce a shared activity provider, not wire network calls directly into views:

- Add models or payload mappers for GitHub PR activity and release/tag activity in `apple/PRBarShared`.
- Add a protocol such as `GitHubActivityProviding` that returns pull requests and releases for selected repositories over a bounded date range.
- Add live and static implementations using the existing session-store and transport pattern.
- Inject the provider in `PRBarApp`, with static fixtures for `--ui-testing`.
- Add a store method to refresh activity after session restore/repo setup and to surface recoverable sync issues without breaking deterministic UI tests.

## Likely Allowed Files

- `apple/PRBarShared/GitHubActivity.swift` or similar new file.
- `apple/PRBarShared/GitHubAuth.swift` if token/session reuse needs small helpers.
- `apple/PRBarShared/GitHubRepositories.swift` if transport needs to be generalized or shared.
- `apple/PRBarShared/PRBarModels.swift`.
- `apple/PRBarShared/PRBarStore.swift`.
- `apple/PRBarShared/SampleData.swift`.
- `apple/PRBar/PRBarApp.swift`.
- `apple/PRBar/PRs/PRsView.swift` if calendar anchoring or empty/error states need visible support.
- `apple/PRBar/Releases/ReleasesView.swift` if calendar anchoring or empty/error states need visible support.
- `apple/PRBar/Share/WorkCardRenderer.swift` if evidence filtering needs live-data tweaks.
- `apple/PRBarTests/PRBarModelTests.swift` and possibly new test files under `apple/PRBarTests/`.
- `apple/PRBarUITests/PRBarUITests.swift` only if a visible live-data state needs UI coverage.
- `apple/project.yml` only if new source layout requires explicit changes; current folder-based sources likely avoid this.

## Verification Commands

- `./scripts/format-check.sh`
- `git diff --check`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' ./scripts/ios-build.sh`

## Risks for Judge

- `SampleData.today` is hard-coded into PR/Releases/Share range logic; live data needs either a store-level `activityAnchorDate` or a provider result date anchor.
- `PullRequest.repoID` currently uses the repository IDs in fixtures; live repo IDs from PR #44 use `owner/name`, so mapping must stay consistent.
- Release/tag coverage needs a product decision because GitHub Releases and Git tags are different sources.
- Synchronous URLSession transport matches current store simplicity but can block; acceptable for first deterministic slice only if scoped carefully.
- The current live auth implementation still does not complete device-flow polling, so tests and UI smoke must keep using fakes. Live provider code can still be correct against stored sessions.
