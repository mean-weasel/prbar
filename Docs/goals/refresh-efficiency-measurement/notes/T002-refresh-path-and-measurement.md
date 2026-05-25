# T002 Refresh Path And Measurement Scout

## Refresh Call Graph

Manual refresh starts in `PRPopoverView`'s closure from `PRMenuBarApp.body`, which calls `refresh(now:)` at `Sources/App/PRMenuBarApp.swift:32` and `Sources/App/PRMenuBarApp.swift:38`.

Scheduled refresh uses the same path after `refreshIfDue(now:)` gates through `RefreshPolicy` at `Sources/App/PRMenuBarApp.swift:41`, `Sources/App/PRMenuBarApp.swift:44`, and `Sources/App/PRMenuBarApp.swift:60`.

`PRMenuBarApp.refresh(now:failureMessage:)` guards duplicate work with `beginRefresh()`, captures the current store, increments `refreshGeneration`, then runs `PRActivityRefresher.refresh(current:now:)` on a background queue at `Sources/App/PRMenuBarApp.swift:68` through `Sources/App/PRMenuBarApp.swift:80`.

`PRActivityRefresher.refresh` preserves current settings by taking `store.settingsSnapshot`, loading a fresh provider store, and applying settings at `Sources/Models/PRActivityRefresher.swift:6` through `Sources/Models/PRActivityRefresher.swift:8`. Inclusion/window/bin preservation depends on `PRActivityStore.applying(_:)` at `Sources/Models/PRActivityStore.swift:107` through `Sources/Models/PRActivityStore.swift:131`.

Live GitHub refresh enters `GitHubPRActivityProvider.load(now:)` at `Sources/Models/GitHubPRActivityProvider.swift:36`. Current dirty work already adds a 15-minute in-memory discovery cache at `Sources/Models/GitHubPRActivityProvider.swift:19` and `Sources/Models/GitHubPRActivityProvider.swift:59`.

Cold live refresh phases:

1. Repository discovery: paginated `GET /user/repos` loop at `Sources/Models/GitHubPRActivityProvider.swift:142` through `Sources/Models/GitHubPRActivityProvider.swift:159`.
2. Pullable filter: `repositories.filter(\.canPull)` at `Sources/Models/GitHubPRActivityProvider.swift:66` through `Sources/Models/GitHubPRActivityProvider.swift:67`.
3. Authenticated user lookup: `GET /user` at `Sources/Models/GitHubPRActivityProvider.swift:115` through `Sources/Models/GitHubPRActivityProvider.swift:119`.
4. Organization lookup and owner list creation: `GET /user/orgs` at `Sources/Models/GitHubPRActivityProvider.swift:121` through `Sources/Models/GitHubPRActivityProvider.swift:139`.
5. GraphQL merged-PR search per owner, with pagination: `Sources/Models/GitHubPRActivityProvider.swift:186` through `Sources/Models/GitHubPRActivityProvider.swift:243`.
6. Decode/filter by merger: `Sources/Models/GitHubPRActivityProvider.swift:226` through `Sources/Models/GitHubPRActivityProvider.swift:238`.
7. Bucket counts per repository: `Sources/Models/GitHubPRActivityProvider.swift:162` through `Sources/Models/GitHubPRActivityProvider.swift:183`.
8. Store replacement and UI state update on main queue: `Sources/App/PRMenuBarApp.swift:82` through `Sources/App/PRMenuBarApp.swift:93`.

## Current Request Count Formula

Let:

- `R` = number of `/user/repos` pages.
- `O` = number of search owners: authenticated user plus organizations.
- `G` = total GraphQL search pages across owners.

Cold refresh request count is `R + 1 /user + 1 /user/orgs + G`.

Repeated refresh inside the current discovery cache TTL should be `G` only. Existing fixture test coverage proves the simple one-owner case: initial load captures 4 requests, and a second load inside cache duration raises total to 5, meaning the second refresh issued only `/graphql` (`Tests/PRMenuBarTests/GitHubPRActivityProviderTests.swift:133` through `Tests/PRMenuBarTests/GitHubPRActivityProviderTests.swift:156`).

Repeated refresh after TTL should rediscover: the existing test raises total to 8 across two refreshes and verifies request 5 is `/user/repos` (`Tests/PRMenuBarTests/GitHubPRActivityProviderTests.swift:158` through `Tests/PRMenuBarTests/GitHubPRActivityProviderTests.swift:188`).

## Phase Boundaries To Time

Minimum useful phase timers:

- `refresh.total`: from `beginRefresh()` success to main-queue success/failure handling.
- `provider.load.total`: entire `GitHubPRActivityProvider.load(now:)`.
- `discovery.total`: `discovery(now:)` including cache hit/miss classification.
- `discovery.repositories`: paginated `/user/repos` calls plus JSON decode.
- `discovery.authenticated_user`: `/user` call plus decode.
- `discovery.organizations`: `/user/orgs` call plus decode and owner sorting.
- `graphql.total`: all owner searches.
- `graphql.owner.<kind>.<login>` or sanitized owner bucket: per-owner GraphQL search duration and page count.
- `graphql.decode_filter`: response decode, GraphQL error check, `mergedBy` filtering.
- `activity.bucket`: repository activity construction and weekly/daily bucket generation.
- `settings.apply`: `PRActivityStore.applying(_:)`, because settings preservation is a correctness invariant.
- `ui.commit`: main-queue store/error update, if instrumentation can capture it without noisy UI coupling.

Request metrics should include method, path, status family, cache outcome where available, and GraphQL page/cursor count. Do not log tokens, full URLs with sensitive query text, or owner names unless explicitly redacted/sanitized.

## Baseline Measurement Harness Shape

Recommended fixture-backed harness:

- Add a test or script-level `GitHubAPITransport` wrapper that records request path/method and duration around an inner fixture transport.
- Add deterministic fixture responses for: cold refresh, repeated refresh within discovery TTL, repeated refresh after TTL, multiple repository pages, multiple owners, and GraphQL pagination.
- Generate a small machine-readable report, for example JSON in `build/refresh-benchmark.json`, with request counts and phase durations for cold vs repeated refresh.
- Make the report command runnable without live credentials and include it in verification.

Optional live harness:

- If `gh auth status` is available, allow a live run through `gh auth token` or `PR_MENU_BAR_GITHUB_TOKEN`, but never require it for CI or completion.
- Current environment has `gh auth status` available for account `neonwatty`, so live measurement is possible locally, but fixture-backed proof remains required.

## Risks And Stop Conditions

Incremental search:

- Must not miss PRs when the visible window changes, the app crosses a bucket boundary, or a prior refresh failed.
- Needs a full-refresh fallback whenever the incremental baseline is unknown, stale, outside the displayed date range, or incompatible with settings/cache state.
- Must dedupe merged PRs by stable identity; current model stores title/repository/date only, so Scout recommends Judge require a stable PR identity before approving a narrow incremental implementation.

Conditional requests:

- Current transport returns only `Data`; conditional support likely needs status/header metadata, especially ETag and 304 handling.
- 304 cannot currently pass through `(200..<300)` handling at `Sources/Models/URLSessionGitHubAPITransport.swift:27`, so the transport contract must change or a specialized wrapper must handle it.
- Conditional discovery must interact cleanly with the existing in-memory discovery TTL.

Async/await migration:

- Current transport uses a semaphore around `URLSession.dataTask` at `Sources/Models/URLSessionGitHubAPITransport.swift:9` through `Sources/Models/URLSessionGitHubAPITransport.swift:39`.
- Migration touches protocol shape, provider calls, app refresh dispatch, and tests; Judge should defer unless observability shows it enables measurable parallelism or simplifies safe conditional-response handling.

## Recommended Next Worker Package

Before further optimization, implement observability and a fixture-backed benchmark/report. The first Worker should avoid changing live behavior except for optional sanitized debug metrics. It should produce request counts and phase timings for cold refresh, cache-hit repeated refresh, and cache-expired refresh, then run format, file-size, and full tests.
