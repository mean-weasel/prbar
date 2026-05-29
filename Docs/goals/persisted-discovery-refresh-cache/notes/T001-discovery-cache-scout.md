# T001 Scout: Persisted Discovery Refresh Cache

## Current Discovery Call Graph

- `GitHubPRActivityProvider.load(now:)` calls `discovery(now:)` before GraphQL PR search.
- `discovery(now:)` currently has only an in-memory `GitHubDiscoveryCache`; if it is fresh, refresh records `discovery.cache_hit` and skips REST discovery.
- When memory cache is missing or expired, discovery performs:
  - `/user/repos` via `repositories()`
  - `/user` via `authenticatedUser()`
  - `/user/orgs` via `organizations()`
- `load(now:)` then calls `mergedPullRequestsByRepository(...)`; the prior tranche already supports persisted merged-PR cache compatibility by `owners`, `mergedBy`, `repositoryIDs`, and window coverage.

## Current Cache Shape

- `GitHubDiscoveryCache` is private to `GitHubPRActivityProvider.swift` and contains:
  - `createdAt`
  - `authenticatedUser`
  - `searchOwners`
  - `pullableRepositories`
- `discoveryResponseCache` is in-memory only and maps `GitHubAPIRequest.cacheKey` to `GitHubCachedAPIResponse(data:eTag:)`.
- Conditional discovery already works after memory expiry: `discoveryData(for:)` sends `If-None-Match` and can reuse cached response data for `304`.
- No discovery cache or discovery response cache is persisted across provider/app restart.

## Persistence Design

The safest first implementation is a token-fingerprinted UserDefaults store, mirroring `UserDefaultsGitHubMergedPullRequestCacheStore`, that persists a discovery payload containing:

- schema/versioned key prefix
- `GitHubDiscoveryCache`
- `discoveryResponseCache`

Models that likely need `Codable`:

- `GitHubDiscoveryCache`
- `GitHubCachedAPIResponse`
- `GitHubRepository`
- `GitHubRepository.Owner`
- `GitHubRepository.Permissions`
- `GitHubAuthenticatedUser`
- `GitHubOrganization`

Provider changes should add an optional `GitHubDiscoveryCacheStoring` init dependency. `discovery(now:)` should:

1. Use fresh in-memory discovery as today.
2. Load persisted discovery by token fingerprint when memory is empty.
3. If persisted discovery is still inside `discoveryCacheDuration`, assign both `discoveryCache` and `discoveryResponseCache`, record a cache-hit metric, and return before REST discovery.
4. If persisted discovery exists but is stale, restore only its response cache so live discovery can revalidate with ETags.
5. Save discovery + response cache after successful live discovery.

## Acceptance Target

The target of `1` foreground request is feasible for a compatible restarted refresh:

- first provider warms persisted discovery + persisted merged-PR cache
- restarted provider loads fresh persisted discovery before REST discovery
- restarted provider loads compatible persisted PR cache
- foreground request path is only `/graphql`, with `graphql.total` mode `incremental`

The benchmark should keep the existing `persisted_cache_refresh` scenario at `4` requests for PR-cache-only restart evidence and add a new persisted-discovery scenario expecting `1` request.

## Correctness Risks And Fallbacks

- Token mismatch: persisted discovery must be scoped by token fingerprint and not reuse another token's snapshot.
- Corrupt persisted payload: load should return nil and force live discovery.
- Stale discovery: should force live discovery; if persisted response cache has ETags, stale revalidation can still be conditional.
- Repository/user/org changes: live discovery after staleness should update discovery; the existing merged-PR cache compatibility should fall back to full GraphQL when `repositoryIDs`, `owners`, or `mergedBy` differ.
- No pullable repositories: should persist the empty discovery result safely and skip GraphQL when reused.
- Secrets: cache keys must not include the raw token.

## Candidate Worker Slice

Largest safe useful slice:

- Add persisted discovery cache store and inject it into live GitHub provider construction.
- Wire provider discovery to load fresh persisted discovery before foreground REST discovery and save successful discovery snapshots.
- Restore persisted response cache for stale conditional discovery.
- Add tests for restarted one-request path, token mismatch, corrupt payload, stale fallback, stale conditional revalidation, and repository mismatch triggering full GraphQL fallback.
- Update refresh benchmark with `persisted_discovery_cache_refresh`.

Likely allowed files:

- `Sources/Models/GitHubPRActivityProvider.swift`
- `Sources/Models/GitHubPRActivityProvider+ConditionalRequests.swift`
- `Sources/Models/GitHubDiscoveryCacheStore.swift`
- `Sources/Models/GitHubRepository.swift`
- `Sources/Models/GitHubAccount.swift`
- `Sources/Models/PRActivityProviderFactory.swift`
- `Tests/PRMenuBarTests/GitHubPRActivityProviderTests.swift`
- `Tests/PRMenuBarTests/GitHubPRActivityProviderIncrementalTests.swift`
- `Tests/PRMenuBarTests/GitHubDiscoveryCacheStoreTests.swift`
- `Tests/PRMenuBarTests/RefreshBenchmarkTests.swift`

Verification:

- `./scripts/format-check.sh`
- `./scripts/file-size-check.sh`
- targeted `xcodebuild test` for provider/cache/benchmark tests
- `make refresh-benchmark`
- full `make test` at final audit
