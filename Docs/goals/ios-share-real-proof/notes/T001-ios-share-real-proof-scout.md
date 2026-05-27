# T001 Scout: iOS Share Real Proof

## Current Share Surface

- `apple/PRBar/Share/ShareView.swift` is the active iOS Share tab.
- It already reads `PRBarStore` through `WorkCardRenderer.source(for:)` and `WorkCardRenderer.evidence(for:)`.
- It shows:
  - a source panel,
  - a private-work warning if `store.cardHasPrivateEvidence`,
  - public/evidence side previews,
  - a style/privacy placeholder button,
  - an `Export card` button that opens `ExportCardSheet`.
- The export sheet currently contains action rows only. Selecting an action dismisses the sheet and shows an alert title. It does not render an image, invoke the native share sheet, copy a caption/image, save a PNG, or create a real transferable artifact.

## Data Provenance

- `apple/PRBar/Share/WorkCardRenderer.swift` is already activity-backed:
  - shipping snapshot counts `store.pullRequests` scoped to `store.includedRepositories` and `store.prRange`;
  - release receipt uses `store.releases`, `store.selectedReleaseID`, and repository lookup;
  - evidence side uses included releases or release-adjacent PRs from the same store.
- Prior live-data receipts explicitly state that `ShareView` and `WorkCardRenderer` render provider-backed data after GitHub sign-in and repo selection.
- The current card does not explicitly expose enough provenance for sharing:
  - no last-refreshed/stale-cache label,
  - no selected repo/date-scope summary on the export sheet beyond a short caption,
  - handle is hardcoded as `@neonwatty` in the card views instead of derived from `store.githubConnection.user?.login`,
  - private repo risk is only broad, not tied to the exact export action.

## Existing Renderer And Export Mechanisms

- iOS has no native export bridge today.
- `apple/PRBar/Share/WorkCardView.swift` and `WorkCardEvidenceView.swift` are SwiftUI card views that could be rendered with `ImageRenderer`.
- The macOS menu bar app has a separate native export implementation:
  - `Sources/Views/ShareCardRenderer.swift` renders `ShareCardView` to `NSImage` via `ImageRenderer`.
  - `Sources/Views/ShareCardPreviewSheet.swift` uses `NSSharingServicePicker`, `NSPasteboard`, and `NSSavePanel`.
- That macOS implementation is useful evidence but should not be edited in this iOS tranche unless Judge explicitly approves shared model work.
- On iOS, the likely implementation should use:
  - `ImageRenderer` to produce `UIImage`/PNG for the current public/evidence card;
  - `ShareLink` with a transferable image URL or a small `UIActivityViewController` bridge for deterministic native share invocation;
  - `UIPasteboard` for caption copy, if included in the first slice.

## Activity And Freshness Metadata

- `PRBarStore` owns:
  - `pullRequests`, `releases`, `repositories`, `includedRepositories`;
  - `cardDraft`;
  - `lastActivityRefreshAt`;
  - `lastActivityRefreshAttemptAt`;
  - `activityRefreshIssue`;
  - `githubConnection`.
- Offline-cache work means cards may be generated from restored cached data. That can be useful, but the exported artifact should not imply freshness if `activityRefreshIssue != nil` and `lastActivityRefreshAt` is older than the failed attempt.
- PRs/Releases already display sync state through `ActivitySyncStatusView`; Share has no equivalent provenance/freshness row.

## Privacy Risks

- `cardHasPrivateEvidence` currently returns true whenever any included repo is private.
- `WorkCardView.repoLine` can reveal repository names if `draft.showRepos` is true.
- `WorkCardEvidenceView` can reveal:
  - private PR titles,
  - private release/tag titles,
  - release notes,
  - repo names,
  - exact counts if enabled.
- Privacy controls already exist in `More/PrivacyDefaultsView.swift` and `WorkCardDraft`:
  - show repos,
  - show handle,
  - exact counts,
  - show private labels.
- The first export slice should make the exact exported content obvious before invoking native sharing, and should keep private/public warning copy close to the export action.

## Deterministic Verification Hooks

- `apple/PRBarUITests/PRBarUITests.swift` has `testShareTabExplainsWorkCardExport`, currently asserting placeholder export actions.
- UI tests can use:
  - `--ui-testing` for sample-backed authenticated state;
  - `--ui-testing-refresh-data` to prove refreshed provider-backed data reaches PRs/Releases and can be extended to Share;
  - `--ui-testing-cached-activity` to prove stale/cached Share provenance if needed.
- Unit tests belong in `apple/PRBarTests/PRBarModelTests.swift` or a new focused PRBar test file.
- A deterministic first slice can test:
  - card source uses current store activity and selected included repos;
  - source/evidence expose release and PR details from a refreshed snapshot;
  - caption/provenance/freshness text is generated without live credentials;
  - UI exposes a native share/export affordance and generated caption/provenance text.
- It is risky to assert that a real iOS share sheet destination appears in simulator UI tests. Prefer a test seam that proves the native export item is prepared, plus a UI test that opens the export sheet and verifies the action copy/provenance.

## Relevant Files

- `apple/PRBar/Share/ShareView.swift`
- `apple/PRBar/Share/WorkCardView.swift`
- `apple/PRBar/Share/WorkCardEvidenceView.swift`
- `apple/PRBar/Share/ExportCardSheet.swift`
- `apple/PRBar/Share/WorkCardRenderer.swift`
- `apple/PRBarShared/PRBarStore.swift`
- `apple/PRBarShared/PRBarModels.swift`
- `apple/PRBarShared/GitHubActivity.swift`
- `apple/PRBarShared/SampleData.swift`
- `apple/PRBar/More/PrivacyDefaultsView.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- `apple/PRBarUITests/PRBarUITests.swift`
- `apple/project.yml`
- `scripts/ios-test.sh`
- `scripts/ios-ui-smoke.sh`
- `.github/workflows/ios.yml`
- `.github/workflows/ios-physical-preview.yml`

## Recommended Implementation Options

1. Preferred vertical slice:
   - Add an iOS `WorkCardExport`/`WorkCardExportBuilder` model that derives caption, privacy warning, freshness/provenance, handle, and selected side from `PRBarStore`.
   - Add iOS image rendering for `WorkCardView`/`WorkCardEvidenceView` using `ImageRenderer`.
   - Replace placeholder alert-only export actions with a real native share path for at least image+caption and caption copy.
   - Update Share UI to show source/date/repo/freshness provenance before export.
   - Add unit tests for export builder and UI tests for the real-data/provenance/export controls.

2. Smaller safe slice if native image export proves flaky:
   - Add export builder, real-data provenance UI, and caption copy through `UIPasteboard`.
   - Leave image rendering/share sheet to a follow-up.
   - This is weaker because the goal oracle asks for a native share artifact, so it should only be chosen if image/share plumbing blocks deterministic verification.

3. Avoid for this tranche:
   - Public profile/social upload.
   - Backend receipt hosting.
   - New GitHub scopes.
   - Editing macOS share-card files beyond read-only comparison.
