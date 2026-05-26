# T004 Auth Architecture Decision

## Decision

Approve a first Worker slice that implements the iOS auth/session foundation around GitHub OAuth device flow, a Keychain-facing session store, and deterministic fakes.

This does not mean the UI has to expose the full device-code experience in polished final form immediately. It means the code shape should stop pretending that `connectGitHubForPrototype()` is auth and should instead route through real boundaries:

- `GitHubAuthProviding` or equivalent protocol for sign-in/sign-out/session restoration.
- `GitHubSessionStoring` protocol with in-memory and Keychain-backed implementations.
- Device-flow models and coordinator that can later call GitHub's device-code/token endpoints.
- Store state that can represent signed out, signing in, connected, missing configuration, failed, and possibly pending device authorization.
- Tests that prove tokens are never stored in plain app model state and that the UI can use fake auth to move through the signed-out-to-repo-selection flow.

## Rationale

- GitHub device flow is OAuth, does not require shipping a client secret, and has explicit polling/error semantics that are testable.
- `ASWebAuthenticationSession` remains the more native long-term UX if there is a safe token exchange strategy, but implementing that now would either require a backend or risk putting secrets in the app.
- Keychain storage should be introduced before repo fetching so every later GitHub API path consumes session state through a secure boundary.
- The iOS app currently has a single store created in `PRBarApp`, which is enough for initial dependency injection without broad project restructuring.
- The existing macOS GitHub request/transport code is useful evidence, but the first iOS slice should keep a small local API/auth boundary under `apple/PRBarShared` instead of prematurely extracting a cross-platform module.

## First Worker Objective

Implement the real GitHub auth/session foundation selected by Judge:

- Replace prototype-only connect/disconnect behavior with an injectable auth/session service boundary.
- Add device-flow request/token models and a coordinator that can be backed by fake responses in tests.
- Add Keychain-facing token/session persistence behind a protocol, plus in-memory storage for unit/UI tests.
- Add route/connection states for loading, connected, signed out, missing configuration, and recoverable auth failure.
- Update signed-out onboarding and More sign-out to call the service boundary.
- Keep repo fetching fixture-backed for this slice, but make successful auth advance into repo setup through the same UI path as #43.
- Add unit tests for session restore, fake sign-in, sign-out clearing, Keychain-store query construction or behavior, and missing configuration/failure states.
- Add or adjust a UI test using launch arguments/fakes so CI can prove the signed-out auth path without real GitHub credentials.

## Allowed Files For T005

- `apple/PRBarShared/PRBarModels.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBarShared/SampleData.swift`
- New Swift files under `apple/PRBarShared/` for auth/session/device-flow/keychain/fake service types.
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBar/Onboarding/OnboardingView.swift`
- `apple/PRBar/More/MoreView.swift`
- `apple/PRBar/More/RepositorySetupView.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- New Swift files under `apple/PRBarTests/`
- `apple/PRBarUITests/PRBarUITests.swift`
- `apple/project.yml` only if new source grouping is needed.
- `Docs/goals/ios-github-auth-integration/state.yaml`
- `Docs/goals/ios-github-auth-integration/notes/`

## Verification For T005

- `./scripts/format-check.sh`
- `git diff --check`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- A targeted UI test for signed-out auth with fakes, for example `xcodebuild test ... -only-testing:PRBarUITests/PRBarUITests/testSignedOutGitHubConnectShowsRepoSelection`
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`

## Stop If

- A real GitHub client secret would need to be committed or embedded.
- A real user token would be needed to pass unit/UI tests.
- The implementation requires repo fetching before auth/session boundaries compile and pass tests.
- Keychain access cannot be abstracted away from CI and unit tests.
- Files outside the allowed set become necessary.

## Deferred Work

- Actual repository API fetching and selection persistence belong to T007 after auth/session foundation review.
- Real PR/release fetching remains out of scope until auth and repo selection are verified.
- Native `ASWebAuthenticationSession` web OAuth can be revisited after deciding whether a backend/token-exchange service exists.
- Private repo sharing UX remains conservative and should be refined after repo API results are real.
