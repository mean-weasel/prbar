# Mac Share Release Cards Native Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add native macOS menu bar Releases and fixed share-card preview/export flows for PR activity and release notes.

**Architecture:** Extend the existing SwiftUI popover with a Releases tab, source-specific share actions, and a shared preview sheet. Keep release data, card payload construction, rendering, and export actions separated so Activity, Releases, and tests do not depend on view internals.

**Tech Stack:** Swift, SwiftUI, AppKit image/export APIs, XCTest.

---

## File Structure

- `Sources/Models/ReleaseMoment.swift`: release/tag model and source labels.
- `Sources/Models/ReleaseMomentProvider.swift`: provider protocol plus sample provider.
- `Sources/Models/ReleaseMomentStore.swift`: filters releases by included repositories.
- `Sources/Models/ShareCardPayload.swift`: PR and release card payloads.
- `Sources/Models/ShareCardBuilder.swift`: converts current app state into card payloads.
- `Sources/Views/ReleasesView.swift`: Releases tab list, selected details, empty state, and share action.
- `Sources/Views/ShareCardView.swift`: fixed card visuals for PR and release payloads.
- `Sources/Views/ShareCardPreviewSheet.swift`: preview, privacy row, Share/Copy/Save actions.
- `Sources/Views/ShareCardRenderer.swift`: renders `ShareCardView` to `NSImage`.
- `Sources/Views/PRPopoverView.swift`: adds Releases tab and Activity share action.
- `Tests/PRMenuBarTests/*`: focused tests for models, filtering, payloads, and privacy masking.

## Task 1: Release Moment Model And Filtering

**Files:**
- Create: `Sources/Models/ReleaseMoment.swift`
- Create: `Sources/Models/ReleaseMomentStore.swift`
- Test: `Tests/PRMenuBarTests/ReleaseMomentStoreTests.swift`

- [ ] **Step 1: Add release model**

Create `Sources/Models/ReleaseMoment.swift`:

```swift
import Foundation

struct ReleaseMoment: Identifiable, Equatable, Codable {
  enum Source: String, Codable {
    case githubRelease
    case tag

    var badgeText: String {
      switch self {
      case .githubRelease: "Release"
      case .tag: "Tag"
      }
    }

    var notesTitle: String {
      switch self {
      case .githubRelease: "Original release notes"
      case .tag: "Generated tag summary"
      }
    }
  }

  var id: String
  var repositoryID: String
  var title: String
  var tag: String
  var date: Date
  var notes: String
  var url: URL?
  var source: Source
}
```

- [ ] **Step 2: Add release store filtering**

Create `Sources/Models/ReleaseMomentStore.swift`:

```swift
import Foundation

struct ReleaseMomentStore: Equatable {
  var releases: [ReleaseMoment]

  func visibleReleases(for repositories: [RepositoryActivity]) -> [ReleaseMoment] {
    let includedIDs = Set(repositories.filter(\.isIncluded).map(\.id))
    return releases
      .filter { includedIDs.contains($0.repositoryID) }
      .sorted { $0.date > $1.date }
  }
}
```

- [ ] **Step 3: Add filtering tests**

Create `Tests/PRMenuBarTests/ReleaseMomentStoreTests.swift` with tests for included repo filtering, date sorting, and source badge labels.

- [ ] **Step 4: Run tests**

Run:

```bash
swift test --filter ReleaseMomentStoreTests
```

Expected: all tests pass.

## Task 2: Sample Release Provider

**Files:**
- Create: `Sources/Models/ReleaseMomentProvider.swift`
- Modify: `Sources/App/PRMenuBarApp.swift`
- Test: `Tests/PRMenuBarTests/ReleaseMomentProviderTests.swift`

- [ ] **Step 1: Add provider protocol and sample data**

Create a provider protocol that can later be backed by GitHub:

```swift
import Foundation

protocol ReleaseMomentProvider {
  func fetchReleaseMoments(now: Date) throws -> [ReleaseMoment]
}

struct SampleReleaseMomentProvider: ReleaseMomentProvider {
  func fetchReleaseMoments(now: Date = Date()) throws -> [ReleaseMoment] {
    [
      ReleaseMoment(
        id: "rel-prbar-140",
        repositoryID: "prbar",
        title: "Live data polish",
        tag: "v1.4.0",
        date: now,
        notes: "Connects GitHub auth fallback, improves live data startup behavior, and preserves the last useful activity view.",
        url: URL(string: "https://github.com/neonwatty/prbar/releases/tag/v1.4.0"),
        source: .githubRelease
      )
    ]
  }
}
```

- [ ] **Step 2: Wire sample store into app state**

Add `@State private var releaseStore = ReleaseMomentStore(releases: (try? SampleReleaseMomentProvider().fetchReleaseMoments(now: Date())) ?? [])` to `PRMenuBarApp`.

- [ ] **Step 3: Pass release store to popover**

Update `PRPopoverView` initializer to accept `releaseStore: ReleaseMomentStore`.

- [ ] **Step 4: Run app smoke**

Run:

```bash
make app-smoke
```

Expected: app builds and bundle verification passes.

## Task 3: Share Card Payloads

**Files:**
- Create: `Sources/Models/ShareCardPayload.swift`
- Create: `Sources/Models/ShareCardBuilder.swift`
- Test: `Tests/PRMenuBarTests/ShareCardBuilderTests.swift`

- [ ] **Step 1: Add payload models**

Create `ShareCardPayload` with `prActivity` and `release` cases. Include repo distribution rows with masked display names when repositories are private.

- [ ] **Step 2: Build PR payloads**

Create `ShareCardBuilder.prActivityPayload(store:)` that includes range, total merged PRs, active repo count, bucket totals, and repo rows sorted by visible count descending.

- [ ] **Step 3: Build release payloads**

Create `ShareCardBuilder.releasePayload(release:repository:)` that includes title, tag, notes excerpt, source label, date, and masked repository display name when private.

- [ ] **Step 4: Test privacy and distribution**

Add tests proving private repo names become `Private repo`, public repos keep their names, and repo rows are sorted by count.

- [ ] **Step 5: Run tests**

Run:

```bash
swift test --filter ShareCardBuilderTests
```

Expected: all tests pass.

## Task 4: Native Share Card Preview Sheet

**Files:**
- Create: `Sources/Views/ShareCardView.swift`
- Create: `Sources/Views/ShareCardPreviewSheet.swift`
- Create: `Sources/Views/ShareCardRenderer.swift`

- [ ] **Step 1: Implement fixed card view**

Create a SwiftUI card view with two fixed layouts:

- PR card: headline count, range, active repo count, compact bars, repo distribution rows, PRBar mark.
- Release card: tag/title, repo display name, date, notes excerpt, source label, PRBar mark.

- [ ] **Step 2: Implement preview sheet**

Create `ShareCardPreviewSheet` with rendered card preview, privacy row, and three buttons: `Share`, `Copy Image`, `Save PNG`.

- [ ] **Step 3: Implement renderer**

Create a renderer using `ImageRenderer` where available for SwiftUI-to-image rendering. Use an AppKit fallback only if the deployment target requires it.

- [ ] **Step 4: Add export actions**

Wire:

- `Share`: `NSSharingServicePicker`
- `Copy Image`: `NSPasteboard`
- `Save PNG`: `NSSavePanel`

Keep failures visible through a local alert message.

## Task 5: Activity Share Action

**Files:**
- Modify: `Sources/Views/PRPopoverView.swift`
- Test: existing Swift tests plus app smoke

- [ ] **Step 1: Add Activity share button**

Add `Share PR Card` below Activity repo mix/bucket detail.

- [ ] **Step 2: Open preview before export**

Build a PR payload from the current `PRActivityStore` and present `ShareCardPreviewSheet`.

- [ ] **Step 3: Run smoke**

Run:

```bash
make app-smoke
```

Expected: app builds and Activity still opens.

## Task 6: Releases Tab

**Files:**
- Create: `Sources/Views/ReleasesView.swift`
- Modify: `Sources/Views/PRPopoverView.swift`
- Test: model tests and app smoke

- [ ] **Step 1: Add Releases tab**

Insert `Releases` between Activity and Settings in `PRPopoverView`.

- [ ] **Step 2: Render release list**

Show visible releases from `ReleaseMomentStore.visibleReleases(for: store.repositories)`.

- [ ] **Step 3: Render selected detail**

Show notes title, release/tag title, notes excerpt, source badge, `Share Release Card`, `Copy Notes`, and `Open on GitHub` where URL exists.

- [ ] **Step 4: Render empty state**

When no visible releases exist, show `No releases in included repositories` and an `Edit Repos` affordance.

- [ ] **Step 5: Wire release card preview**

Build release payload and present `ShareCardPreviewSheet`.

- [ ] **Step 6: Run smoke**

Run:

```bash
make app-smoke
```

Expected: app builds and the menu bar bundle exists.

## Task 7: Final Verification

**Files:**
- Verify all touched files.

- [ ] **Step 1: Run focused tests**

Run:

```bash
swift test --filter ReleaseMomentStoreTests
swift test --filter ShareCardBuilderTests
```

Expected: all focused tests pass.

- [ ] **Step 2: Run full tests**

Run:

```bash
swift test
```

Expected: full suite passes.

- [ ] **Step 3: Run app smoke**

Run:

```bash
make app-smoke
```

Expected: Release build succeeds and app bundle verification passes.

- [ ] **Step 4: Manual UI smoke**

Launch the app and verify:

- Activity tab has `Share PR Card`.
- PR preview appears before export.
- PR preview shows repo distribution.
- Releases tab lists official releases and tag fallbacks.
- Tag fallback is clearly labeled as generated.
- Private release cards hide private repo names.
- No releases state is readable.
- Share, Copy Image, and Save PNG actions produce visible success or error feedback.
