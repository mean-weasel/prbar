# T007 Repo API Worker Receipt

## Result

Done.

## Summary

Implemented the first real GitHub repository service boundary for iOS:

- Added authenticated `/user/repos` request construction with GitHub API headers and page support.
- Added a repository client that loads the current GitHub session, fetches repository pages, decodes owner/name/privacy/permission payloads, and maps them into `Repository` models.
- Added deterministic repository providers and transports for unit/UI testing.
- Added repository selection persistence through a protocol-backed store with in-memory and `UserDefaults` implementations.
- Wired app launch to use Keychain-backed auth sessions, live repository fetching, and persisted repo selections in normal mode, while UI testing still uses static fakes.
- Updated store connection/restore flow so fetched repos are privacy-filtered and fetch failures surface as recoverable issues instead of incorrectly routing to setup.

## Privacy Defaults

Without a saved selection, the store includes only public, ready repositories that GitHub says are pullable and that the provider marks included or recommended. Private repos remain excluded by default. If a saved selection exists, the store restores exactly those repository IDs, allowing intentional private repo inclusion later.

## Tests Added

- Authenticated repository request endpoint and headers.
- GitHub repository payload mapping for public/private repos.
- Repository pagination across a full first page.
- Connection flow loading fetched repos with privacy defaults.
- Connection flow restoring persisted repo selection.
- Connection flow surfacing repository fetch failures.
- Repository setup persistence.

## Verification

- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh` passed: 25 tests, 0 failures.
- `./scripts/format-check.sh` passed.
- `git diff --check` passed.
- `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build -resultBundlePath apple/SignedOutOnly-T007.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:PRBarUITests/PRBarUITests/testSignedOutGitHubConnectShowsRepoSelection` passed: 1 UI test, 0 failures.
- `IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17' IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh` passed: 2 UI tests, 0 failures.

## Notes

The `GitHubDeviceFlowAuthService.connect()` method still stops at the configured service boundary and does not perform live device-code polling yet. That was intentionally deferred by T006 so this PR can establish secure session storage, repository fetching, selection persistence, and deterministic tests first.
