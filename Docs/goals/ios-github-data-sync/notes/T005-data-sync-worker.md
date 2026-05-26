# T005 Data Sync Worker Receipt

## Result

Implemented the first GitHub activity data-sync vertical slice for the iOS app.

## Changed Files

- `apple/PRBarShared/GitHubActivity.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBarShared/SampleData.swift`
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBar/PRs/PRsView.swift`
- `apple/PRBar/Releases/ReleasesView.swift`
- `apple/PRBar/Share/WorkCardRenderer.swift`
- `apple/PRBarTests/GitHubActivityTests.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- `Docs/goals/ios-github-data-sync/state.yaml`
- `Docs/goals/ios-github-data-sync/notes/`

## Behavior

- Added `GitHubActivityProviding`, `GitHubActivitySnapshot`, `StaticGitHubActivityProvider`, and a production-facing `GitHubActivityClient`.
- Added request builders for per-repository REST activity endpoints:
  - closed pull requests via `/repos/{owner}/{repo}/pulls`
  - releases via `/repos/{owner}/{repo}/releases`
  - tags via `/repos/{owner}/{repo}/tags`
  - tag commit dates via the tag commit URL
- Mapped merged PRs, releases, and tags into the app's existing `PullRequest` and `ReleaseMoment` models.
- Filtered fetched activity to the user's included repositories and the configured lookback window.
- Preserved deterministic UI-test behavior with static fixtures while normal app launches use the live activity client.
- Updated PR, Release, and Share views to anchor date ranges from `PRBarStore.activityAnchorDate` instead of the fixture-only `SampleData.today`.
- On GitHub connect/session restore, the store now refreshes activity after repository selection is known; failures keep fixture activity in place and surface the existing recoverable issue path.

## Tests Added

- Verified authenticated GitHub request construction for PR, release, and tag endpoints.
- Verified activity mapping filters out unmerged and out-of-window PRs.
- Verified releases and tags are represented separately and sorted into the release timeline.
- Verified missing sessions fail closed before network requests.
- Verified GitHub connect refreshes only included repository activity.
- Verified activity refresh failure preserves sample activity and shows the issue route.

## Verification

- `./scripts/format-check.sh`
  - Pass.
- `git diff --check`
  - Pass.
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
  - Pass: 31 tests, 0 failures.
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`
  - Pass: 2 UI tests, 0 failures.

## Deferred

- Production OAuth device-flow polling remains outside this slice.
- The first activity refresh is synchronous and does not yet include loading spinners, cache persistence, ETag support, or background refresh.
- The release/tag timeline now has real data plumbing, but annotation and social sharing expansion remain future product work.
