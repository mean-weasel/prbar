# T001 Scout: iOS Activity Offline Cache

## Scope

Mapped the current iOS activity data, storage, freshness, auth, repo-selection, test, and workflow surfaces for a persistent offline cache. This was read-only.

## Source Surfaces

- `apple/PRBarShared/PRBarStore.swift`
  - Owns `pullRequests`, `releases`, `activityAnchorDate`, selected dates, `activityRefreshIssue`, `lastActivityRefreshAt`, and `lastActivityRefreshAttemptAt`.
  - `restoreGitHubSession()` restores auth and repository selection, then immediately calls `refreshActivityForIncludedRepositories()` when stored repo selection exists.
  - `finishRepositorySetup()` saves included repo IDs and then refreshes activity synchronously.
  - `refreshActivity()` preserves in-memory activity on failure and records `activityRefreshIssue`.
  - `applyActivitySnapshot(_:)` is the single place that mutates PR/release arrays and calendar anchors from a snapshot.
- `apple/PRBarShared/GitHubActivity.swift`
  - Defines `GitHubActivitySnapshot` with `pullRequests`, `releases`, and `anchorDate`.
  - The snapshot is `Equatable` and `Sendable`, but not currently `Codable`.
  - `StaticGitHubActivityProvider` and `SequencedGitHubActivityProvider` filter snapshots by included repositories, useful for tests.
- `apple/PRBarShared/PRBarModels.swift`
  - `GitHubUser`, repository visibility/access, and release source are `Codable`.
  - `Repository`, `PullRequest`, and `ReleaseMoment` are not currently `Codable`, but their stored fields are codable-friendly except `URL`, which is codable already.
- `apple/PRBarShared/GitHubAuth.swift`
  - `KeychainGitHubSessionStore` persists the auth session in Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
  - `GitHubAuthSession` is codable and exposes a `connection` including the GitHub login.
- `apple/PRBarShared/GitHubRepositories.swift`
  - `UserDefaultsRepositorySelectionStore` persists included repo IDs at `github.includedRepositoryIDs`.
  - No repo-selection persistence is scoped by GitHub account login today.
- `apple/PRBar/PRBarApp.swift`
  - Non-UI-test app construction wires Keychain session, live GitHub repository/activity clients, and `UserDefaultsRepositorySelectionStore`.
  - UI tests use in-memory auth/repo selection stores and deterministic activity providers.
- `apple/PRBar/Components/ActivitySyncStatusView.swift`
  - Shows fresh, not-refreshed, failed, and stale-with-issue states based on `lastRefreshedAt`, `lastRefreshAttemptAt`, and `activityRefreshIssue`.
- `apple/PRBar/PRs/PRsView.swift` and `apple/PRBar/Releases/ReleasesView.swift`
  - Both show `ActivitySyncStatusView`.
  - Both refresh via pull-to-refresh and the toolbar button.
- `apple/PRBarTests/PRBarModelTests.swift`
  - Existing tests cover repository selection persistence, activity refresh replacement, failure preserving in-memory data, and rate-limit issue mapping.
- `apple/PRBarUITests/PRBarUITests.swift`
  - Existing UI tests cover pull-to-refresh success and stale-with-issue behavior for the current process.
- `.github/workflows/ios.yml`
  - PR/merge_group/push iOS workflow runs build, `PRBarTests`, and UI smoke for iOS changes.
- `.github/workflows/ios-physical-preview.yml`
  - Manual physical Preview workflow targets `iPhone-preview` on the dedicated `prbar-ios` runner labels.

## Current Data Flow

1. App launch creates `PRBarStore.sample(...)`, so the store starts with `SampleData.pullRequests` and `SampleData.releases`.
2. In production launch, `store.restoreGitHubSession()` runs.
3. If a GitHub session exists, `loadRepositoriesForConnectedUser()` fetches repos and applies stored included IDs.
4. If stored IDs exist, `restoreGitHubSession()` immediately performs a live activity refresh before entering `.authenticated`.
5. If the live refresh fails during restore, `routeState` becomes `.issue(...)`; there is no attempt to restore previous activity from disk.
6. In an already authenticated session, `refreshActivity()` keeps current in-memory PRs/releases on failure, but that in-memory state is lost on app relaunch.

## Current Persistence

- Auth session: Keychain, via `KeychainGitHubSessionStore`.
- Repository selection: UserDefaults, via `UserDefaultsRepositorySelectionStore`.
- Activity data: no persistent store.
- Freshness metadata: no persistent store for `lastActivityRefreshAt` or `lastActivityRefreshAttemptAt`.

## Cache Risks

- Sample data can be mistaken for a real cache because production stores begin from `PRBarStore.sample(...)`.
- Cache should probably be scoped to the GitHub login from `GitHubConnection.user?.login` or the restored `GitHubAuthSession`, otherwise one account can see another account's cached metadata.
- Repository selection changes should either filter restored cached data by currently included repo IDs or invalidate stale repo-inclusion assumptions.
- Disconnect should clear activity cache and freshness metadata.
- Decode corruption or schema changes should fail safely and leave the app able to fetch live data.
- Atomic writes matter because partial JSON writes could otherwise break startup.
- Persisting private repo PR/release titles and release notes locally is a privacy-sensitive behavior; the first PR should use app-private storage and avoid backup/export surfaces unless explicitly decided later.

## Implementation Options For Judge

1. **Versioned activity cache store vertical slice.**
   - Add a small `GitHubActivityCacheStoring` abstraction and file-backed JSON implementation in shared code.
   - Make `Repository`, `PullRequest`, `ReleaseMoment`, and `GitHubActivitySnapshot` `Codable`.
   - Store a versioned cache envelope with snapshot, `lastRefreshedAt`, GitHub login/account key, and included repo IDs.
   - Restore a matching cache during `restoreGitHubSession()` before live refresh, then show stale/offline status if live refresh fails.
   - Clear cache on disconnect.
   - This is the recommended first vertical slice because it proves user-visible relaunch/offline behavior end to end without changing OAuth or backend scope.
2. **Minimal metadata-only freshness persistence.**
   - Persist only last refresh dates and maybe repo IDs.
   - Not sufficient for the goal because PR/release arrays would still be sample data after relaunch.
3. **Persist derived PR/release arrays directly in `PRBarStore`.**
   - Smaller at first, but risks coupling persistence to view/store internals and makes corruption/versioning harder to test.

## Suggested Verification

- `git diff --check`
- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- Focused UI test for restored cached activity plus failed refresh:
  `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build -resultBundlePath apple/ActivityCacheUITest.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:PRBarUITests/PRBarUITests/testRelaunchRestoresCachedActivityWhenRefreshFails`

## Suggested First Slice

Approve option 1 as a single vertical slice, with strict file limits and tests for:

- cache encode/decode and unsupported version/corrupt data fallback;
- cache save after successful setup and refresh;
- cache restore before failed live refresh;
- cache scoping by login and included repo IDs;
- cache clear on disconnect;
- UI proof that cached data appears after relaunch/failed refresh with stale copy.
