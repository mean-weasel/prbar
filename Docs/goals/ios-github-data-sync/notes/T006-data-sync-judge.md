# T006 Data Sync Judge

## Decision

Complete enough for PR.

## Evidence

- `GitHubActivityClient` uses the stored GitHub session and authenticated REST requests for merged PR, release, tag, and tag commit metadata.
- `PRBarApp` injects the live activity client for normal launches and fixture-backed activity for UI tests.
- `PRBarStore` refreshes activity after repositories are loaded and scopes requests to `includedRepositories`.
- PR, Releases, and Share views no longer anchor their ranges to fixture-only `SampleData.today`.
- `GitHubActivityTests` cover request construction, session failure, merged PR filtering, releases, tags, and commit-date mapping.
- `PRBarModelTests` cover included-repository filtering and failure behavior during connect.
- T005 verification passed: format check, whitespace check, unit tests, and PR UI smoke profile.

## Rationale

The implementation satisfies the first live data-sync tranche without needing real credentials in CI. It is not just cosmetic: normal app launches now have a production-facing data provider that maps GitHub API responses into the app's existing PR and release/tag models, while tests remain deterministic through the same transport/provider seams established in the auth/repo foundation.

The privacy boundary is acceptable for this slice. Activity is requested only for repositories included by the existing selection/default logic, and the test coverage proves private activity is not pulled into the store unless the repository is included.

## Deferred

- True OAuth device-flow polling remains a separate auth task.
- Activity loading states, cache persistence, incremental refresh, ETags, and background refresh are future reliability work.
- Release annotation and richer social sharing are product work after the data foundation.
- A later slice should consider clearer user-facing copy for activity sync failures instead of reusing the generic auth issue ID.

## Next Step

Proceed to T007: final build/unit/UI verification, PR notes, push, and open a draft PR.
