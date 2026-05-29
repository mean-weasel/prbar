# Release Readiness

## Current Release Candidate

PRBar is ready to cut a GitHub release and notarized macOS artifact for `v1.2.0`.

This release includes the production app updates that landed after `v1.1.0`:

- Persisted GitHub discovery and merged-PR caches for faster refreshes.
- A one-request warm refresh path when cached repository and PR data is still current.
- iOS setup, sync, install, and share-proof follow-up work.
- Web proof mockup and navigation follow-up work.
- Mac share-card and release-card work from `v1.1.0`.

## Versioning

- GitHub releases are produced by `semantic-release`.
- The latest existing tag is `v1.1.0`.
- The Mac bundle version is `MARKETING_VERSION=1.2.0` and `CURRENT_PROJECT_VERSION=3`.
- PRs that should create a release must use a conventional squash title, such as `feat: ...` or `fix: ...`.

## Distribution Status

The GitHub release flow publishes release notes with `semantic-release`, then
explicitly dispatches the `Release Artifact` workflow for the published tag. The
artifact workflow also keeps its manual dispatch fallback for rebuilding an
existing tag.

GitHub release events created by the workflow's `GITHUB_TOKEN` do not trigger
other workflows, except `workflow_dispatch` and `repository_dispatch`, so the
release workflow must dispatch the artifact workflow directly instead of relying
only on `release.published`. See GitHub's documented `GITHUB_TOKEN` trigger
behavior:
<https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow#triggering-a-workflow-from-a-workflow>.

The `Release Artifact` workflow attaches a signed, notarized
`PRMenuBar-macOS.zip` asset to the release.

The local Release build is suitable for smoke validation:

- Bundle identifier: `com.neonwatty.PRMenuBar`
- Minimum macOS: `14.0`
- Menu bar app: `LSUIElement=true`
- Hardened runtime: enabled
- Signing: ad-hoc local signing unless `PRBAR_SIGNING_IDENTITY` is set

Public downloadable app artifacts require the GitHub repository secrets listed in
the packaging section below. Without those secrets, the source release still
publishes, but the release-asset workflow fails loudly instead of attaching an
unsigned app.

## Pre-Release Verification

Run these before merging a release-prep PR:

```bash
./scripts/format-check.sh
./scripts/file-size-check.sh
git diff --check
make test
make app-smoke
GH_TOKEN="$(gh auth token)" npm run release -- --dry-run
```

Run local packaging validation:

```bash
./scripts/package-macos-release.sh
```

That local command creates `dist/PRMenuBar-macOS.zip` with ad-hoc signing unless
Developer ID signing and notarization environment variables are provided.

Manual QA for the Mac app:

- Launch the Release or Debug app bundle with `open -n`.
- Open the menu bar popover.
- Create an Activity share card.
- Create a Release share card.
- Verify Copy Image, Save PNG, and Share actions are present.
- Verify private repository names remain masked in exported card text.

## Release Artifact Packaging

The installable Mac app path is:

1. `semantic-release` publishes a GitHub release from `main`.
2. `.github/workflows/release.yml` dispatches
   `.github/workflows/release-artifact.yml` for the newly published tag.
3. The workflow checks out the release tag, imports the Developer ID
   certificate, builds `PRMenuBar.app`, signs with hardened runtime, submits the
   app for notarization, staples the ticket, zips the app, and uploads:
   - `PRMenuBar-macOS.zip`
   - `PRMenuBar-macOS.zip.sha256`

Required GitHub repository secrets:

- `MACOS_CERTIFICATE_P12_BASE64`: Base64-encoded Developer ID Application
  certificate export.
- `MACOS_CERTIFICATE_PASSWORD`: Password for that `.p12` export.
- `MACOS_KEYCHAIN_PASSWORD`: Temporary CI keychain password.
- `MACOS_DEVELOPER_ID_APPLICATION`: Full signing identity name, for example
  `Developer ID Application: Example, Inc. (TEAMID1234)`.
- `APPLE_TEAM_ID`: Apple Developer Team ID.

Notarization can use either App Store Connect API key secrets:

- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API key ID.
- `APP_STORE_CONNECT_API_ISSUER_ID`: App Store Connect issuer ID.
- `APP_STORE_CONNECT_API_KEY_P8`: Private `.p8` key for that API key.

Or Apple ID credentials:

- `APPLE_ID`: Apple ID email used for notarization.
- `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password for notarization.

Manual artifact rebuild for an existing release:

```bash
gh workflow run release-artifact.yml --repo mean-weasel/prbar -f tag=v1.2.0
```

Release operator checklist:

- Confirm `Release` completed successfully on `main`.
- Confirm `Release Artifact` started for the new tag.
- Confirm the release has `PRMenuBar-macOS.zip` and
  `PRMenuBar-macOS.zip.sha256` assets.
- Download the release asset, verify the SHA-256 checksum, and inspect the app
  signature/notarization before installing.
- Run only `/Applications/PRMenuBar.app` for production use; repo build
  products are development-only.
