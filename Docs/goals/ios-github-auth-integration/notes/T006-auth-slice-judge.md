# T006 Auth Slice Judge

## Decision

Approved with one explicit boundary: the auth/session foundation is strong enough for the repo API + persistence slice, but production device-flow polling remains deferred and must not be represented as complete GitHub sign-in.

## Evidence

- `GitHubAuthSession` keeps access token material out of `PRBarStore`.
- `GitHubSessionStoring` has in-memory and Keychain-backed implementations.
- `GitHubDeviceFlowRequest` builds concrete GitHub OAuth device-code and token polling requests.
- `PRBarApp` injects fake auth for UI tests and Keychain/device-flow auth for normal launches.
- `PRBarStore` now calls auth service methods for restore, connect, and disconnect.
- Unit and UI verification passed.

## Rationale

This is not merely cosmetic: the prototype connect method is gone, session persistence is behind a secure storage abstraction, and CI proves the signed-out path with deterministic fakes. It is intentionally not the full live OAuth loop yet, but it creates the right boundary for repo fetching and selection persistence.

## Next Worker Objective

Implement GitHub repository fetching, repository selection persistence, and SwiftUI wiring so onboarding/settings use the real service boundary while tests stay deterministic.

## Allowed Files For T007

- `apple/PRBarShared/GitHubAuth.swift`
- `apple/PRBarShared/GitHubRepositories.swift`
- `apple/PRBarShared/PRBarModels.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBarShared/SampleData.swift`
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBar/Onboarding/OnboardingView.swift`
- `apple/PRBar/More/RepositorySetupView.swift`
- `apple/PRBar/More/MoreView.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- `apple/PRBarUITests/PRBarUITests.swift`
- `Docs/goals/ios-github-auth-integration/state.yaml`
- `Docs/goals/ios-github-auth-integration/notes/T006-auth-slice-judge.md`
- `Docs/goals/ios-github-auth-integration/notes/T007-repo-api-worker.md`

## Verification For T007

- `./scripts/format-check.sh`
- `git diff --check`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build -resultBundlePath apple/SignedOutOnly.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:PRBarUITests/PRBarUITests/testSignedOutGitHubConnectShowsRepoSelection`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`

## Stop If

- Repo fetching needs real GitHub credentials to pass tests.
- Selection persistence would store private repo names in a public/share state.
- Repository IDs become ambiguous or break existing PR/release fixture filtering without a migration choice.
- Files outside the allowed list become necessary.
