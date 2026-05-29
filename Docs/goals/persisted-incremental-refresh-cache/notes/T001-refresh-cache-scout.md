# T001 Refresh Cache Scout

## Refresh/cache call graph

Manual Refresh starts in `Sources/App/PRMenuBarApp.swift`: `PRPopoverView` calls `refresh(now:)`, which wraps `PRActivityRefresher(provider: providerSelection.provider)` and runs `refresher.refresh(current:now:)` on a background queue.

`Sources/Models/PRActivityRefresher.swift` preserves current settings by reading `store.settingsSnapshot`, loading a fresh provider store, and applying the saved settings to the new store.

For live GitHub data, `Sources/Models/PRActivityProviderFactory.swift` creates a single `GitHubPRActivityProvider` instance for the app lifetime when a token is available. That provider owns:

- `discoveryCache`, an in-memory repo/user/org cache with a 15-minute TTL.
- `discoveryResponseCache`, an in-memory ETag/body cache for conditional REST discovery requests.
- `mergedPullRequestCache`, an in-memory merged-PR cache used by incremental GraphQL search.

`GitHubPRActivityProvider.load(now:)` does discovery, computes the visible start date from `bucketLabels.count`, then calls `mergedPullRequestsByRepository(...)` with `forceFullRefresh: discovery.cacheHit == false`.

## Current incremental behavior

`Sources/Models/GitHubPRActivityProvider+IncrementalSearch.swift` chooses:

- `full` when discovery changed/missed, owners changed, merged user changed, the requested window starts before cached coverage, or there is no cache.
- `cache_only` when `until == cache.until`.
- `incremental` when cache shape matches and the new `until` is later.

Network results are merged into `pullRequestsByID`, then filtered back to the current display range. This already dedupes by stable GraphQL PR id and avoids advancing the cache when GraphQL throws, because `mergedPullRequestCache` is assigned only after network/decode succeeds.

Existing tests in `Tests/PRMenuBarTests/GitHubPRActivityProviderIncrementalTests.swift` cover:

- incremental range inside discovery cache duration;
- full search when the visible window expands before cached coverage;
- failed refresh does not advance the incremental cache.

## Existing persistence surface

There is no persistent merged-PR cache today. `GitHubMergedPullRequestCache`, `GitHubSearchOwner`, and `GitHubMergedPullRequest` are not all `Codable`, and the provider constructor has no cache-store dependency.

The closest existing durable pattern is `PRSettingsStore` in `Sources/Models/PRSettingsStore.swift`, which stores a `Codable` `PRSettingsSnapshot` in `UserDefaults` under a versioned key. `PRSettingsStore` is testable by injecting a `UserDefaults` suite.

No implementation currently scopes persisted GitHub cache data by token, authenticated user, owners, or cache schema version.

## Correctness risks and fallback triggers

Persisted cache should be used only when these remain compatible:

- schema version;
- authenticated merged user;
- search owners;
- requested display `since` is inside cached coverage;
- requested `until` is not before cache `until`;
- cached payload decodes cleanly.

Token-specific scoping should not store or log the token. A local token fingerprint derived with a one-way hash is enough to prevent reusing cache across different tokens; authenticated user plus owners are still needed because token scopes can change.

An overlap window should be added before incremental network search, for example `cache.until - 30 minutes`, with existing PR-id dedupe absorbing duplicates. This guards against GitHub search indexing lag and boundary rounding. The stored cache `until` should still advance only after successful network/decode.

On corrupt/incompatible/missing persisted cache, the provider should fall back to full search rather than fail refresh.

## Verification commands and hooks

Existing commands:

- `make refresh-benchmark` writes `build/refresh-benchmark.json`.
- `make test` runs the macOS test suite.
- `./scripts/format-check.sh`.
- `./scripts/file-size-check.sh`.

Existing benchmark coverage in `Tests/PRMenuBarTests/RefreshBenchmarkTests.swift` has cold, in-memory cache-hit, and cache-expired scenarios. It does not yet prove provider restart or persisted warm behavior.

Test support in `Tests/PRMenuBarTests/GitHubPRActivityProviderTestSupport.swift` already captures requests and can assert GraphQL query ranges from request bodies.

## Candidate Worker slice

Largest safe useful slice:

Implement a persisted merged-PR cache store and wire it into `GitHubPRActivityProvider`, including overlap/dedupe and fixture tests for provider restart/post-relaunch behavior plus invalid/corrupt/incompatible fallback.

Likely allowed files:

- `Sources/Models/GitHubPRActivityProvider.swift`
- `Sources/Models/GitHubPRActivityProvider+IncrementalSearch.swift`
- new `Sources/Models/GitHubMergedPullRequestCacheStore.swift`
- `Sources/Models/PRActivityProviderFactory.swift`
- `Tests/PRMenuBarTests/GitHubPRActivityProviderIncrementalTests.swift`
- `Tests/PRMenuBarTests/GitHubPRActivityProviderTestSupport.swift`
- new cache-store tests if helpful
- `Tests/PRMenuBarTests/RefreshBenchmarkTests.swift`

Keep `Sources/App/PRMenuBarApp.swift` out of the first Worker unless the provider factory cannot safely inject the store.
