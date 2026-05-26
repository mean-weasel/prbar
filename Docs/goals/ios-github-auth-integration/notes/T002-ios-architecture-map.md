# T002 iOS Architecture Map

## Current iOS Shape

- `apple/PRBar/PRBarApp.swift` creates a single `PRBarStore.sample()` and switches to signed-out state only through launch arguments. This is the natural dependency injection point for test fakes and future app services.
- `apple/PRBar/RootTabView.swift` routes `.authenticated` to the tab app and `.signedOut`, `.onboarding`, or `.issue` to `OnboardingView`.
- `apple/PRBarShared/PRBarStore.swift` is an `@Observable` reference store. It owns repositories, PRs, releases, selected dates, share-card state, `routeState`, and `githubConnection`.
- `apple/PRBarShared/PRBarModels.swift` contains the iOS-only app route, GitHub connection, user, repository, PR, release, calendar, and card models.
- `apple/PRBarShared/SampleData.swift` is the current data source for repositories, PRs, releases, and user-visible fixture URLs.

## Prototype Auth And Repo Flow

- `GitHubConnection` has only `.signedOut` and `.connected`, with no loading, failed, expired, or permission state.
- `PRBarStore.connectGitHubForPrototype()` hard-codes `neonwatty`, includes recommended public ready repos, and routes to `.onboarding(.repositories)`.
- `PRBarStore.disconnectGitHub()` clears included repos and routes back to `.signedOut`.
- `OnboardingView` calls `connectGitHubForPrototype()` from the "Continue with GitHub" button.
- `RepositorySetupView` reads/writes `store.repositories` directly through toggle bindings and shows the connected user if present.

## Existing Test Seams

- UI tests already use launch arguments: `--ui-testing` and `--signed-out`.
- Unit tests directly instantiate `PRBarStore.sample()` and exercise the prototype connect/disconnect behavior.
- The current UI smoke profile runs only two UI tests for PR checks; full profile is available through `IOS_UI_SMOKE_PROFILE=full`.
- `scripts/ios-build.sh`, `scripts/ios-test.sh`, and `scripts/ios-ui-smoke.sh` regenerate the Xcode project, target `PRBar`, and default to simulator code-signing disabled.

## CI And Merge Queue

- `.github/workflows/ios.yml` now runs on `pull_request`, `push`, `workflow_dispatch`, and `merge_group`.
- The required iOS job is named `Build, Test, UI Smoke`; it builds, runs `PRBarTests`, then runs the PR UI smoke profile.
- `.github/workflows/ci.yml` also runs on `merge_group`; the queue now has both required checks available.

## Existing GitHub Code Outside iOS

- The macOS app already has `GitHubAPIRequest`, `URLSessionGitHubAPITransport`, `GitHubRepository`, `GitHubPRActivityProvider`, fixture transports, and request/decoding tests under `Sources/Models` and `Tests/PRMenuBarTests`.
- `Docs/GitHubIntegration.md` documents the current macOS token path and explicitly says OAuth, device flow, and keychain storage were deferred.
- The iOS target does not compile `Sources/Models`, so reuse requires either copying/adapting the relevant API boundary into `apple/PRBarShared` or extracting a shared module in `apple/project.yml`.

## Likely Allowed Files

- `apple/PRBarShared/PRBarModels.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBarShared/SampleData.swift`
- New files under `apple/PRBarShared/` for auth session, Keychain abstraction, GitHub API client, repository fetching, persistence, and fakes.
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBar/Onboarding/OnboardingView.swift`
- `apple/PRBar/More/RepositorySetupView.swift`
- `apple/PRBar/More/MoreView.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- New focused unit tests under `apple/PRBarTests/`
- `apple/PRBarUITests/PRBarUITests.swift`
- `apple/project.yml` only if a new app target setting or source grouping is needed.
- `.github/workflows/ios.yml` only if CI behavior changes again.

## Verification Commands

- `./scripts/format-check.sh`
- `git diff --check`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' ./scripts/ios-build.sh`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`
- For new signed-out/auth UI behavior, add a targeted `xcodebuild test ... -only-testing:PRBarUITests/PRBarUITests/<test>` run before relying on the PR smoke subset.

## Risks For Judge

- Authentication flow decision is still open: device flow may be easier to test, while `ASWebAuthenticationSession` is more native for OAuth web authorization.
- Keychain must be abstracted because CI and unit tests should not depend on the real user keychain.
- Current store is synchronous; real auth and repo fetch need async state, loading/error routes, and deterministic fake services.
- Repository `id` should likely become `owner/name` for GitHub data. Sample IDs currently include short names like `prbar`, which affects persistence and cross-linking to PR/release fixtures.
- Private repo defaults need to remain conservative: fetched private repos should not auto-appear in share evidence without explicit user inclusion.
- Reusing macOS provider code directly could accidentally pull macOS assumptions into iOS. The safer first move is a small iOS service protocol shaped by the existing request/transport tests.
