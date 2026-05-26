# T004 Data Sync Architecture Decision

## Result

Approved.

## Decision

Implement one vertical slice that adds a protocol-backed GitHub activity provider for selected repositories:

- PR activity from REST per-repo pull request listing.
- Releases from REST per-repo release listing.
- Tag fallback from REST per-repo tag listing plus commit-date enrichment.
- Store refresh wiring that replaces fixture PR/release arrays after a signed-in repo load.
- Deterministic static/fixture implementations for unit and UI tests.

## Architecture

Use REST per-repository endpoints instead of Search or GraphQL for this first slice:

- `GET /repos/{owner}/{repo}/pulls?state=closed&sort=updated&direction=desc&per_page=100&page=N`
- filter to `merged_at != nil` and within a bounded date window in the client.
- `GET /repos/{owner}/{repo}/releases?per_page=100&page=N`
- `GET /repos/{owner}/{repo}/tags?per_page=100&page=N`
- for tag fallback, fetch the tag commit URL and map its commit author/committer date when available.

Add:

- `GitHubActivityProviding` protocol.
- `GitHubActivityClient` using `GitHubSessionStoring` and the existing data transport seam.
- `StaticGitHubActivityProvider` for previews/UI tests.
- `GitHubActivitySnapshot` carrying `[PullRequest]`, `[ReleaseMoment]`, and an `anchorDate`.
- `PRBarStore.activityAnchorDate` so PRs/Releases/Share use real activity anchor dates instead of `SampleData.today`.

## Scope Boundaries

- Keep network calls synchronous for parity with the existing repository client and current store shape.
- Keep error handling recoverable and generic in the UI; detailed rate-limit UI can come later.
- Do not implement background refresh, durable activity caching, social features, hosted sharing, or real device-flow polling in this slice.
- Do not require real GitHub credentials in CI.

## Privacy Decision

Only fetch activity for `includedRepositories`. Since private repos can be intentionally included, private activity may enter the store only after selection. Share surfaces must continue to show the private evidence warning through `cardHasPrivateEvidence`.

## Worker Task

T005 should implement the above data-sync slice with tests.

## Allowed Files

- `apple/PRBarShared/GitHubActivity.swift`
- `apple/PRBarShared/GitHubAuth.swift`
- `apple/PRBarShared/GitHubRepositories.swift`
- `apple/PRBarShared/PRBarModels.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBarShared/SampleData.swift`
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBar/PRs/PRsView.swift`
- `apple/PRBar/Releases/ReleasesView.swift`
- `apple/PRBar/Share/WorkCardRenderer.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- `apple/PRBarTests/GitHubActivityTests.swift`
- `apple/PRBarUITests/PRBarUITests.swift`
- `Docs/goals/ios-github-data-sync/state.yaml`
- `Docs/goals/ios-github-data-sync/notes/T004-data-sync-architecture-decision.md`
- `Docs/goals/ios-github-data-sync/notes/T005-data-sync-worker.md`

## Verify

- `./scripts/format-check.sh`
- `git diff --check`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`

## Stop If

- Live activity mapping requires files outside the allowed list.
- GitHub tag semantics require a new product decision that cannot be represented as release/tag fallback.
- Tests need real GitHub credentials or network.
- Private repo data would be fetched or exported without explicit selected-repo inclusion.
- Verification fails twice for the same reason.

## Deferred Work

- Background refresh and caching.
- Rate-limit-specific UI.
- Auth device-code polling.
- Social/sharing backend.
- Rich tag annotation beyond commit-date fallback.
