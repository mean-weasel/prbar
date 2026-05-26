# T005 Auth Session Worker Receipt

## Result

Implemented the first auth/session foundation slice.

## Changed Files

- `apple/PRBarShared/GitHubAuth.swift`
- `apple/PRBarShared/PRBarModels.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBar/Onboarding/OnboardingView.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- `Docs/goals/ios-github-auth-integration/state.yaml`
- `Docs/goals/ios-github-auth-integration/notes/`

## Behavior

- Added `GitHubAuthSession`, `GitHubAuthError`, device authorization models, OAuth configuration, device-flow request builders, session-store protocol, in-memory session store, and Keychain-backed session store.
- Added `GitHubAuthServicing` with a deterministic static test service and a production-facing device-flow service that fails closed when no client ID is configured.
- Replaced `connectGitHubForPrototype()` with `connectGitHub()` through the auth service boundary.
- Added `restoreGitHubSession()` and made app launch restore from Keychain in non-UI-test launches.
- Kept UI tests deterministic by injecting `StaticGitHubAuthService` when `--ui-testing` is present.
- Sign-out now clears the auth service/session store before returning to signed out.

## Verification

- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
  - Pass: 18 tests, 0 failures.
- `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build -resultBundlePath apple/SignedOutOnly.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:PRBarUITests/PRBarUITests/testSignedOutGitHubConnectShowsRepoSelection`
  - Pass: 1 UI test, 0 failures.
- `./scripts/format-check.sh`
  - Pass.
- `git diff --check`
  - Pass.
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`
  - Pass: 2 UI tests, 0 failures.

## Deferred

- The production device-flow service has request construction and configuration failure handling, but does not yet perform network polling. Repo fetching and selection persistence remain queued for T007 after Judge review.
