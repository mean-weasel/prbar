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

The current GitHub release flow publishes release notes only. It does not attach a signed `.app`, `.zip`, or `.dmg`.

The local Release build is suitable for smoke validation:

- Bundle identifier: `com.neonwatty.PRMenuBar`
- Minimum macOS: `14.0`
- Menu bar app: `LSUIElement=true`
- Hardened runtime: enabled
- Signing: ad-hoc local signing

It is not yet a notarized public Mac distribution artifact. Shipping a downloadable app still needs a Developer ID signing identity, archive/export automation, notarization, stapling, and an attached release asset.

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

Manual QA for the Mac app:

- Launch the Release or Debug app bundle with `open -n`.
- Open the menu bar popover.
- Create an Activity share card.
- Create a Release share card.
- Verify Copy Image, Save PNG, and Share actions are present.
- Verify private repository names remain masked in exported card text.

## Next Packaging Step

Add a dedicated packaging workflow that archives `PRMenuBar.app`, signs with Developer ID, notarizes, staples, zips the artifact, and attaches it to the semantic-release GitHub release.
