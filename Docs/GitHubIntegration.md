# GitHub Integration Plan

The first real GitHub path uses a personal access token supplied outside the repo.
OAuth, device flow, keychain storage, signing, and distribution are intentionally out
of scope until the local product loop proves the provider and refresh behavior.

## Authentication

- Read the token from `PR_MENU_BAR_GITHUB_TOKEN` when explicitly supplied.
- Fall back to `gh auth token` so normal local app launches can connect when the
  GitHub CLI is already authenticated.
- Treat missing credentials as a recoverable configuration state and keep sample data usable.
- Send authenticated requests with `Authorization: Bearer <token>`.
- Keep token persistence out of the app model for now; later UI can choose keychain storage.

## Repository Discovery

- Discover repositories with the REST `/user/repos` endpoint.
- Include repositories where the authenticated user has pull access.
- Use `owner/name` as the stable repository ID.
- Preserve user include/exclude choices by ID when fetched repositories change.
- Default newly discovered repositories to included so first refreshes show useful data.
- Drop removed repositories from the fetched activity list, while keeping settings resilient
  to stale IDs.

## Activity Fetching

- Query merged pull requests per repository for the app's visible history range.
- Bucket merged pull requests by calendar week first, matching the current model.
- Keep API decoding isolated behind `PRActivityProviding` so tests can use fixture JSON.
- Surface provider failures as app state instead of silently replacing real data with samples.
- Paginate GitHub Search results until all reported items are fetched.
- Fail closed when GitHub reports incomplete search results, keeping the previous app state.

## Rate Limits

- Refresh only on manual action or when `RefreshPolicy` says a scheduled refresh is due.
- Keep daily refresh as the default automatic interval.
- Record response metadata later if rate-limit UI becomes necessary.

## Verification Plan

- Unit-test request construction and payload decoding with fixture transport.
- Unit-test settings reconciliation when repositories are added or removed.
- Unit-test scheduled refresh decisions without waiting for wall-clock time.
- Keep `make ci-local` green after each implementation step.

## iOS Preview Runner

Physical iPhone preview testing uses a repo-level self-hosted macOS runner,
mirroring the `issuectl` preview-device pattern. The intended runner is named
`prbar-iphone-preview` and has labels `self-hosted`, `macOS`, `ARM64`,
`prbar-ios`, and `iphone-preview`.

The runner Mac needs:

- Xcode with iOS device support installed.
- XcodeGen available on `PATH`.
- `jq` available on `PATH`.
- A trusted, unlocked physical iPhone named `iPhone-preview`.
- A signing identity visible to the GitHub Actions runner service.
- The secret `IOS_DEVELOPMENT_TEAM` when the runner should pass an explicit Apple development team to `xcodebuild`.
- The secret `IOS_PREVIEW_KEYCHAIN_PASSWORD` when the signing keychain must be unlocked non-interactively.
- Automation Mode enabled without local authentication when available.

Physical preview workflows are manual by default, run only the checked-out
workflow ref, and share one concurrency group so the preview iPhone is not used
by multiple jobs at the same time. Pull requests use simulator CI unless a
maintainer explicitly dispatches the physical preview workflow.

Use the default `device_name` input when the phone is named `iPhone-preview`.
If Xcode reports a different name, pass that exact value to the manual workflow:

```bash
gh workflow run "iOS Preview Runner Health" --ref main -f device_name="iPhone-preview"
gh workflow run "iOS Physical Preview" --ref main -f smoke_profile=pr -f device_name="iPhone-preview"
gh workflow run "iOS Preview Install" --ref main -f device_name="iPhone-preview"
```

The health and preview workflows list attached devices even when preflight
fails, which makes it easier to distinguish runner-label problems from a
locked, untrusted, offline, or differently named iPhone.

For live GitHub proof on the physical preview iPhone, use the explicit
`live-headless` smoke profile instead of the install workflow:

```bash
gh workflow run ios-physical-preview.yml \
  --ref main \
  -f smoke_profile=live-headless \
  -f device_name="iPhone-preview" \
  -f github_login="neonwatty" \
  -f included_repo="mean-weasel/prbar"
```

Repeatable live smoke requires the repo secret `PRBAR_IOS_LIVE_GITHUB_TOKEN`.
Use the narrowest practical read-only GitHub token for the target repository,
and never log it. The app receives the token only as launch environment for the
preview smoke and stores it in the preview app Keychain on the device. Without
that secret, the same workflow can still pass if the preview app already has a
manual GitHub session, but that path is intentionally less repeatable.
