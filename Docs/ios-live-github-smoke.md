# iOS Live GitHub Smoke Test

Use this when closing the live-data tranche. It verifies the production provider path without committing a GitHub token, client secret, or account-specific data.

## Prerequisites

- A GitHub OAuth client ID that is allowed to use GitHub's device authorization flow.
- An unlocked simulator or physical preview device.
- No client secret in the app, repo, logs, screenshots, or workflow output.

## Simulator Walkthrough

Generate the project, then build with the client ID supplied as a transient build setting:

```sh
./scripts/ios-generate.sh
xcodebuild build \
  -project apple/PRBar.xcodeproj \
  -scheme PRBar \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath apple/build \
  PRBAR_IOS_GITHUB_CLIENT_ID="$PRBAR_IOS_GITHUB_CLIENT_ID"
```

For the first authorization attempt, install and launch the built app signed out:

```sh
xcrun simctl install booted apple/build/Build/Products/Debug-iphonesimulator/PRBar.app
xcrun simctl launch booted com.neonwatty.PRBar.ios --signed-out
```

In the app:

1. Tap **Continue with GitHub**.
2. Tap **Copy code**.
3. Tap **Copy link**, then open that link in the Mac Chrome profile that is already signed into GitHub. Avoid using Simulator Safari for repeat smoke runs because it usually requires a separate GitHub login.
4. Paste the copied device code into GitHub and approve access.
5. If GitHub asks for sudo-mode confirmation, complete it in GitHub Mobile, an authenticator app, or email before returning to PRBar.
6. Return to PRBar and tap **I authorized GitHub**.
7. Confirm repo setup shows fetched GitHub repositories.
8. Keep public repos selected by default; opt into private repos only intentionally.
9. Finish setup and confirm PRs, Releases, and Share render from the selected repos.

For repeat checks after the first successful authorization, preserve the simulator app install and Keychain state:

```sh
xcrun simctl terminate booted com.neonwatty.PRBar.ios
xcrun simctl launch booted com.neonwatty.PRBar.ios
```

Do not uninstall the app or launch with `--signed-out` unless you intentionally want to test first-run authorization again.

## Evidence For Final Audit

Record:

- The exact build command with the client ID value redacted.
- Screenshots or notes showing repo setup after real GitHub authorization.
- PRs screen with fetched PR distribution.
- Releases screen with fetched releases or tags.
- Share screen showing a card generated from selected repo activity.
- `git diff --check`
- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- `IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`

Do not record:

- Access tokens.
- OAuth client secrets.
- Private repo names or PR/release titles unless they are intentionally part of the evidence.
