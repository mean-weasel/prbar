# Release Readiness

## Current Release Candidate

PRBar is ready to cut a source-only GitHub release for `v1.1.0`.

This release includes the Mac menu bar share and release-card work:

- Activity share cards with repository distribution.
- Release share cards based on GitHub Releases, with tag fallback.
- Copy image, Save PNG, and native share-sheet actions.
- Release loading, empty, error, and cache behavior.
- Web proof and iOS GitHub activity follow-up work that landed after `v1.0.0`.

## Versioning

- GitHub releases are produced by `semantic-release`.
- The latest existing tag is `v1.0.0`.
- The Mac bundle version is `MARKETING_VERSION=1.1.0` and `CURRENT_PROJECT_VERSION=2`.
- PRs that should create a release must use a conventional squash title, such as `feat: ...` or `fix: ...`.

## Distribution Status

The GitHub release flow publishes release notes with `semantic-release`. A separate
`Release Artifact` workflow now runs when a GitHub release is published and can
attach a signed, notarized `PRMenuBar-macOS.zip` asset to that release.

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
2. `.github/workflows/release-artifact.yml` starts on the `release.published`
   event.
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
- `APPLE_ID`: Apple ID email used for notarization.
- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password for notarization.

Manual artifact rebuild for an existing release:

```bash
gh workflow run release-artifact.yml --repo mean-weasel/prbar -f tag=v1.1.0
```
