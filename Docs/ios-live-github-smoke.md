# iOS Live GitHub Smoke Test

Use this when closing the live-data tranche. It verifies the production provider path without committing a GitHub token, client secret, or account-specific data.

## Prerequisites

- A GitHub App client ID that is allowed to use GitHub's device authorization flow.
- The GitHub App installed or allowed for any organization repositories you want to include.
- An active SSO session before authorizing PRBar when testing SSO-protected organization repositories.
- An unlocked simulator or physical preview device.
- No client secret in the app, repo, logs, screenshots, or workflow output.
- For repeatable physical-device live smoke, a repo secret named `PRBAR_IOS_LIVE_GITHUB_TOKEN` with the smallest practical GitHub read scope for the target repository.

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

For SSO-protected organization repositories, start an SSO session in GitHub before authorizing the app. If PRBar was already authorized without that SSO session, disconnect and authorize again after visiting the organization's SSO page, for example `https://github.com/orgs/ORG_NAME/sso`.

For repeat checks after the first successful authorization, preserve the simulator app install and Keychain state:

```sh
xcrun simctl terminate booted com.neonwatty.PRBar.ios
xcrun simctl launch booted com.neonwatty.PRBar.ios
```

Do not uninstall the app or launch with `--signed-out` unless you intentionally want to test first-run authorization again.

## Physical Preview Live Smoke

Use the physical live smoke when a PR needs proof that the preview app can use a
real GitHub session, include exactly one repository, and refresh PR/release data
on `iPhone-preview`.

Normal preview installs should stay install-only. Do not seed `neonwatty`,
`mean-weasel/prbar`, or any other repo during ordinary install workflows. The
one-repo setup belongs in the explicit live smoke workflow.

Preferred repeatable path:

1. Add `PRBAR_IOS_LIVE_GITHUB_TOKEN` as a GitHub Actions repo secret. Use a
   fine-grained token limited to the repository under test when possible. Do not
   print or store the token outside GitHub secrets and the preview app Keychain.
2. Keep `PRBAR_IOS_GITHUB_CLIENT_ID`, `IOS_DEVELOPMENT_TEAM`, and
   `IOS_PREVIEW_KEYCHAIN_PASSWORD` configured for the repo.
3. Make sure the runner iPhone named `iPhone-preview` is connected, trusted,
   unlocked, and awake.
4. Dispatch the live-headless workflow from the branch or main ref under test:

```sh
gh workflow run ios-physical-preview.yml \
  --repo mean-weasel/prbar \
  --ref codex/ios-live-github-preview-smoke \
  -f smoke_profile=live-headless \
  -f device_name=iPhone-preview \
  -f github_login=neonwatty \
  -f included_repo=mean-weasel/prbar
```

The successful run must emit a marker like:

```text
PRBAR_LIVE_SMOKE_RESULT success login=neonwatty repo=mean-weasel/prbar selected_repo_count=1 pull_requests=<count> releases=<count>
```

Acceptable blocker markers are precise and actionable, for example:

- `missing-github-session`: configure `PRBAR_IOS_LIVE_GITHUB_TOKEN` or manually
  sign in to GitHub inside the preview app on `iPhone-preview`.
- GitHub API permission, SSO, or rate-limit errors: adjust the token or account
  access, then rerun the same workflow.
- Device readiness failures: unlock, trust, or reconnect `iPhone-preview`, then
  rerun.

Fallback manual-auth path:

1. Install or open the preview app on `iPhone-preview`.
2. Complete GitHub device authorization in the app.
3. Rerun the same `live-headless` workflow without adding a token secret.

The manual path is useful for diagnosis, but it is less repeatable because a
reinstall or Keychain reset can remove the session.

## Evidence For Final Audit

Record:

- The exact build command with the client ID value redacted.
- Screenshots or notes showing repo setup after real GitHub authorization.
- PRs screen with fetched PR distribution.
- Releases screen with fetched releases or tags.
- Share screen showing a card generated from selected repo activity.
- For physical live smoke, the workflow run URL and the
  `PRBAR_LIVE_SMOKE_RESULT success` line.
- `git diff --check`
- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- `IOS_UI_SMOKE_PROFILE=pr ./scripts/ios-ui-smoke.sh`

Do not record:

- Access tokens.
- OAuth client secrets.
- Private repo names or PR/release titles unless they are intentionally part of the evidence.
