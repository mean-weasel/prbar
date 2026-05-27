# T001 Scout: iOS Reliability Surfaces

## Relevant Surfaces

- `apple/PRBarShared/PRBarStore.swift`
  - Owns `isRefreshingActivity`, `activityRefreshIssue`, and `lastActivityRefreshAt`.
  - `refreshActivity()` preserves existing activity on failure and records `activityRefreshIssue`.
  - `refreshActivityForIncludedRepositories()` is used from restore/setup and can route the whole app to an issue screen on failure.
  - `authIssue(for:)` maps every non-missing-configuration error to a generic GitHub sign-in failure.
- `apple/PRBarShared/GitHubRepositories.swift`
  - `URLSessionGitHubRepositoryTransport` is shared by auth, repo fetch, and activity fetches.
  - It collapses all non-2xx HTTP responses into `GitHubRepositoryError.invalidResponse`.
  - Network errors pass through as raw `URLError`.
- `apple/PRBarShared/GitHubActivity.swift`
  - Activity client throws coarse `GitHubActivityError.missingSession`, `.invalidURL`, or `.invalidResponse`.
  - Activity calls use the repository transport, so HTTP status details are currently lost before reaching the store.
- `apple/PRBarShared/GitHubAuth.swift`
  - Device auth errors are either missing configuration, pending authorization, storage failed, or generic failed string.
  - Stored session exists in Keychain, but activity data itself is not persisted.
- `apple/PRBar/Components/ActivitySyncStatusView.swift`
  - Shows refreshing, not-yet-refreshed, last-refreshed, and failed states.
  - Does not distinguish last successful sync from last attempted failed sync.
- `apple/PRBar/PRs/PRsView.swift` and `apple/PRBar/Releases/ReleasesView.swift`
  - Both expose pull-to-refresh and toolbar refresh with shared sync status.
- `apple/PRBar/PRBarApp.swift`
  - UI tests can inject deterministic activity providers with launch arguments.
  - Live app uses Keychain session, GitHub repository client, GitHub activity client, and UserDefaults repo selection.
- Tests:
  - `apple/PRBarTests/PRBarModelTests.swift` covers refresh success/failure preservation, auth flow, repo fetch, and repository setup refresh.
  - `apple/PRBarTests/GitHubActivityTests.swift` covers request construction and happy-path mapping.
  - `apple/PRBarUITests/PRBarUITests.swift` covers visible sync status only for not-yet-refreshed and last-refreshed happy paths.

## Current Reliability Behavior

- Last successful sync:
  - `lastActivityRefreshAt` exists and updates on successful refresh/setup restore.
  - On refresh failure, existing PR/release arrays remain in memory and `lastActivityRefreshAt` is preserved.
- Last attempted sync:
  - Not tracked.
  - A failed retry cannot tell the user when the failure happened.
- Stale/offline:
  - No explicit stale state or stale copy.
  - The app may still show existing in-memory/sample activity, but it does not say it is showing previously synced data.
  - No persistent activity cache beyond the app process.
- Error taxonomy:
  - Missing OAuth config has a specific issue.
  - Everything else becomes `github-auth-failed` with generic sign-in copy, including network errors, 401/403/404/429/5xx, repository fetch failures, activity failures, decode failures, and storage failures.
  - GitHub SSO is represented only at repository row level as `Repository.Access.sso`; API-level SSO/403 details are not parsed.
- Retry behavior:
  - Refresh re-entry is guarded by `isRefreshingActivity`.
  - There is no backoff, retry-after, rate-limit display, or last-attempt timestamp.

## Risks And Ambiguities

- A persistent activity cache is valuable but could become a broader data model/storage slice; first slice should only choose it if Judge believes it can be kept small.
- Shared transport changes can affect auth, repository fetch, and activity fetch behavior across iOS and any future shared clients.
- The existing `AuthIssue` name is too auth-specific for activity/network/rate-limit problems, but renaming broadly may create churn.
- Physical Preview currently runs only core tab launch, not the new reliability states, so simulator UI tests need to carry most behavior proof for the first PR.
