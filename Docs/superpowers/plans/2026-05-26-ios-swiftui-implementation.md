# PRBar iOS SwiftUI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the reviewed PRBar iOS prototype as a native SwiftUI iPhone app, keep it isolated from the existing macOS menu bar app, and add CI plus physical-device preview smoke testing.

**Architecture:** Add a new `apple/` subtree managed by XcodeGen, with iOS production and preview app targets plus iOS unit/UI test targets. Keep the current macOS app in `Sources/` and `Tests/` for now, and copy only the shared domain concepts needed by iOS into `apple/PRBarShared` so the first iOS implementation does not destabilize the menu bar app.

**Tech Stack:** SwiftUI, Observation, XCTest, XCUITest, XcodeGen, GitHub Actions, `xcodebuild`, iOS Simulator, optional self-hosted physical iPhone runner modeled after `mean-weasel/issuectl`.

---

## Scope And Repository Decisions

This plan intentionally separates the first SwiftUI app from the existing macOS menu bar target.

- Existing macOS app stays in:
  - `Sources/`
  - `Tests/PRMenuBarTests/`
  - root `project.yml`
  - root `Makefile` targets
- New iOS app lives in:
  - `apple/project.yml`
  - `apple/PRBar/`
  - `apple/PRBarShared/`
  - `apple/PRBarTests/`
  - `apple/PRBarUITests/`
  - `apple/PRBarPreviewUITests/`
- New iOS scripts live in:
  - `scripts/ios-generate.sh`
  - `scripts/ios-build.sh`
  - `scripts/ios-test.sh`
  - `scripts/ios-ui-smoke.sh`
  - `scripts/ios-preview-runner-preflight.sh`
  - `scripts/ios-resolve-preview-device.sh`
  - `scripts/ios-list-devices.sh`
  - `scripts/ios-preview-install.sh`
  - `scripts/ios-preview-device-smoke.sh`
- New workflows live in:
  - `.github/workflows/ios.yml`
  - `.github/workflows/ios-physical-preview.yml`
  - `.github/workflows/ios-preview-install.yml`
  - `.github/workflows/ios-preview-runner-health.yml`
- Current root CI should continue to own macOS. The new iOS workflow should run only when iOS-relevant paths change, except for manual dispatch and merge queue.

The physical preview target is a separate app target, `PRBarPreview`, with a separate bundle ID and display name. It uses the same source files as production but gets a different bundle identifier and can safely be installed on a dedicated iPhone without overwriting any future production app.

## SwiftUI View Mapping

Map the HTML prototype to native view files as follows.

| Prototype Area | SwiftUI View | Responsibility |
| --- | --- | --- |
| App shell and tab bar | `PRBarApp.swift`, `RootTabView.swift` | App entry, dependency injection, bottom tabs |
| PRs tab | `PRsView.swift` | Activity summary, range picker, repo distribution, selected repo drill-in |
| PR calendar | `CalendarStripView.swift`, `MonthHeatMapView.swift` | Day/week strip and month heat map used by PRs and Releases |
| Releases tab | `ReleasesView.swift` | Calendar-first release browsing, selected release detail, date-grouped rows |
| Share tab | `ShareView.swift` | Work-card source, privacy warning, preview, export entry |
| Work card preview | `WorkCardView.swift`, `WorkCardEvidenceView.swift` | Public side and evidence side rendering |
| Export sheet | `ExportCardSheet.swift`, `WorkCardRenderer.swift` | Output actions, PNG rendering, share sheet bridge |
| More tab | `MoreView.swift`, `RepositorySetupView.swift`, `PrivacyDefaultsView.swift`, `SettingsView.swift` | Repo inclusion, privacy defaults, settings and sample data |
| Onboarding | `OnboardingView.swift` | GitHub sign-in rationale, repo setup, privacy defaults, sync states |
| Shared fixtures | `SampleData.swift` | Fixture-backed app state matching the HTML mockup |
| Shared domain | `PRBarModels.swift`, `PRBarStore.swift` | Value types and deterministic state transforms |

## Data Model Baseline

Implement the first SwiftUI app from fixture data, not live GitHub calls. The app should be built so a live provider can replace fixtures later.

```swift
struct Repository: Identifiable, Equatable {
  enum Visibility: String, CaseIterable, Codable {
    case `public`
    case `private`
  }

  enum Access: String, CaseIterable, Codable {
    case ready
    case sso
  }

  var id: String
  var owner: String
  var name: String
  var visibility: Visibility
  var colorHex: String
  var included: Bool
  var recommended: Bool
  var access: Access
  var reason: String
}

struct PullRequest: Identifiable, Equatable {
  var id: String
  var title: String
  var repoID: Repository.ID
  var number: Int
  var mergedAt: Date
}

struct ReleaseMoment: Identifiable, Equatable {
  enum Source: String, CaseIterable, Codable {
    case release
    case tag
  }

  var id: String
  var repoID: Repository.ID
  var title: String
  var tag: String
  var date: Date
  var source: Source
  var notes: String
  var url: URL
}

enum ActivityRange: String, CaseIterable, Identifiable {
  case day
  case week
  case month

  var id: String { rawValue }
}

enum CardSide: String, CaseIterable, Identifiable {
  case publicSide
  case evidenceSide

  var id: String { rawValue }
}

struct WorkCardDraft: Equatable {
  enum Source: Equatable {
    case shippingSnapshot
    case releaseReceipt(ReleaseMoment.ID)
  }

  enum Theme: String, CaseIterable, Identifiable {
    case clean
    case terminal
    case launch
    case hype
    case minimal

    var id: String { rawValue }
  }

  var source: Source
  var theme: Theme
  var side: CardSide
  var showRepos: Bool
  var showHandle: Bool
  var exactCounts: Bool
  var showPrivateLabels: Bool
}
```

## Task 1: Create iOS XcodeGen Project Skeleton

**Files:**
- Create: `apple/project.yml`
- Create: `apple/PRBar/PRBarApp.swift`
- Create: `apple/PRBar/Info.plist`
- Create: `apple/PRBarShared/PRBarModels.swift`
- Create: `apple/PRBarShared/SampleData.swift`
- Create: `apple/PRBarTests/PRBarModelTests.swift`
- Create: `scripts/ios-generate.sh`
- Modify: `.gitignore`

- [ ] **Step 1: Add a minimal iOS XcodeGen project**

Create `apple/project.yml`:

```yaml
name: PRBar
options:
  bundleIdPrefix: com.neonwatty
  deploymentTarget:
    iOS: "18.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "6.0"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"

targets:
  PRBar:
    type: application
    supportedDestinations: [iOS]
    sources:
      - path: PRBar
      - path: PRBarShared
    info:
      path: PRBar/Info.plist
      properties:
        CFBundleDisplayName: PRBar
        UILaunchScreen: {}
        UIRequiresFullScreen: true
        "UISupportedInterfaceOrientations~iphone":
          - UIInterfaceOrientationPortrait
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.neonwatty.PRBar.ios
        PRODUCT_NAME: PRBar
        GENERATE_INFOPLIST_FILE: true
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
        CODE_SIGN_STYLE: Automatic

  PRBarPreview:
    type: application
    supportedDestinations: [iOS]
    sources:
      - path: PRBar
      - path: PRBarShared
    info:
      path: PRBar/Info.plist
      properties:
        CFBundleDisplayName: PRBar Preview
        UILaunchScreen: {}
        UIRequiresFullScreen: true
        "UISupportedInterfaceOrientations~iphone":
          - UIInterfaceOrientationPortrait
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.neonwatty.PRBar.ios.preview
        PRODUCT_NAME: PRBarPreview
        GENERATE_INFOPLIST_FILE: true
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
        CODE_SIGN_STYLE: Automatic

  PRBarTests:
    type: bundle.unit-test
    supportedDestinations: [iOS]
    sources:
      - path: PRBarTests
    dependencies:
      - target: PRBar
    settings:
      base:
        GENERATE_INFOPLIST_FILE: true
        PRODUCT_BUNDLE_IDENTIFIER: com.neonwatty.PRBar.ios.tests
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/PRBar.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PRBar"
        BUNDLE_LOADER: "$(TEST_HOST)"

schemes:
  PRBar:
    build:
      targets:
        PRBar: all
    test:
      gatherCoverageData: false
      targets:
        - PRBarTests

  PRBarPreview:
    build:
      targets:
        PRBarPreview: all
```

- [ ] **Step 2: Add the minimal app entry**

Create `apple/PRBar/PRBarApp.swift`:

```swift
import SwiftUI

@main
struct PRBarApp: App {
  var body: some Scene {
    WindowGroup {
      Text("PRBar")
        .font(.largeTitle.bold())
    }
  }
}
```

Create `apple/PRBar/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

- [ ] **Step 3: Add script and gitignore entries**

Create `scripts/ios-generate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command -v xcodegen >/dev/null 2>&1 || {
  echo "xcodegen is required. Install with: brew install xcodegen" >&2
  exit 69
}

xcodegen generate --spec apple/project.yml
```

Run:

```bash
chmod +x scripts/ios-generate.sh
```

Append to `.gitignore` if missing:

```gitignore
apple/PRBar.xcodeproj
apple/build
apple/TestResults.xcresult
```

- [ ] **Step 4: Generate the iOS project**

Run:

```bash
./scripts/ios-generate.sh
```

Expected: `apple/PRBar.xcodeproj` exists and is ignored by git.

- [ ] **Step 5: Build the empty app on simulator**

Run:

```bash
xcodebuild build \
  -project apple/PRBar.xcodeproj \
  -scheme PRBar \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath apple/build \
  CODE_SIGNING_ALLOWED=NO
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add .gitignore apple/project.yml apple/PRBar apple/PRBarShared apple/PRBarTests scripts/ios-generate.sh
git commit -m "feat: add iOS app project skeleton"
```

## Task 2: Add Fixture Models And Store

**Files:**
- Modify: `apple/PRBarShared/PRBarModels.swift`
- Create: `apple/PRBarShared/PRBarStore.swift`
- Create: `apple/PRBarShared/SampleData.swift`
- Modify: `apple/PRBarTests/PRBarModelTests.swift`

- [ ] **Step 1: Add model tests**

Create `apple/PRBarTests/PRBarModelTests.swift`:

```swift
import XCTest
@testable import PRBar

final class PRBarModelTests: XCTestCase {
  func testIncludedRepositoriesFilterPrivateAndPublicRepos() {
    let store = PRBarStore.sample()

    XCTAssertEqual(store.includedRepositories.map(\.id), ["prbar", "launch-kit", "client-api"])
    XCTAssertTrue(store.includedRepositories.contains { $0.visibility == .private })
  }

  func testSelectedDayPullRequestsAreFilteredByCalendarDate() {
    var store = PRBarStore.sample()
    store.selectedPRDate = SampleData.date("2026-05-24")

    XCTAssertEqual(store.filteredPullRequests.map(\.id), ["pr-39", "pr-38"])
  }

  func testReleaseMomentsAreFilteredBySelectedDate() {
    var store = PRBarStore.sample()
    store.selectedReleaseDate = SampleData.date("2026-05-21")

    XCTAssertEqual(store.filteredReleases.map(\.id), ["tag-launch-100"])
  }

  func testPrivateEvidenceRequiresExportWarning() {
    let store = PRBarStore.sample()

    XCTAssertTrue(store.cardHasPrivateEvidence)
  }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test \
  -project apple/PRBar.xcodeproj \
  -scheme PRBar \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath apple/build \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:PRBarTests/PRBarModelTests
```

Expected: FAIL because `PRBarStore`, `SampleData`, and models are not defined.

- [ ] **Step 3: Implement models and store**

Implement the data model from the **Data Model Baseline** section in `apple/PRBarShared/PRBarModels.swift`.

Create `apple/PRBarShared/SampleData.swift`:

```swift
import Foundation

enum SampleData {
  static let today = date("2026-05-24")

  static func date(_ value: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: value)!
  }

  static func dateTime(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
  }

  static let repositories: [Repository] = [
    Repository(id: "prbar", owner: "neonwatty", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: true, access: .ready, reason: "Most active this week"),
    Repository(id: "launch-kit", owner: "neonwatty", name: "launch-kit", visibility: .public, colorHex: "#16a34a", included: true, recommended: true, access: .ready, reason: "Recent releases"),
    Repository(id: "client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: true, access: .ready, reason: "Private repo included"),
    Repository(id: "docs-site", owner: "neonwatty", name: "docs-site", visibility: .public, colorHex: "#7c3aed", included: false, recommended: false, access: .ready, reason: "Documentation releases"),
    Repository(id: "ops-console", owner: "example", name: "ops-console", visibility: .private, colorHex: "#ef4444", included: false, recommended: false, access: .sso, reason: "Needs SSO authorization"),
  ]

  static let pullRequests: [PullRequest] = [
    PullRequest(id: "pr-39", title: "Connect GitHub auth fallback", repoID: "prbar", number: 39, mergedAt: dateTime("2026-05-24T17:42:00Z")),
    PullRequest(id: "pr-38", title: "Update GitHub Pages actions", repoID: "prbar", number: 38, mergedAt: dateTime("2026-05-24T16:18:00Z")),
    PullRequest(id: "pr-36", title: "Expand app smoke coverage", repoID: "prbar", number: 36, mergedAt: dateTime("2026-05-23T21:04:00Z")),
    PullRequest(id: "pr-44", title: "Add release smoke harness", repoID: "launch-kit", number: 44, mergedAt: dateTime("2026-05-22T18:20:00Z")),
    PullRequest(id: "pr-77", title: "Harden webhook signature checks", repoID: "client-api", number: 77, mergedAt: dateTime("2026-05-21T15:15:00Z")),
    PullRequest(id: "pr-81", title: "Refresh launch notes template", repoID: "launch-kit", number: 81, mergedAt: dateTime("2026-05-20T12:30:00Z")),
    PullRequest(id: "pr-61", title: "Document release card workflow", repoID: "docs-site", number: 61, mergedAt: dateTime("2026-05-19T10:00:00Z")),
    PullRequest(id: "pr-90", title: "Add incident export view", repoID: "ops-console", number: 90, mergedAt: dateTime("2026-05-18T11:10:00Z")),
  ]
}
```

Create `apple/PRBarShared/PRBarStore.swift`:

```swift
import Foundation
import Observation

@Observable
final class PRBarStore {
  var repositories: [Repository]
  var pullRequests: [PullRequest]
  var releases: [ReleaseMoment]
  var selectedPRDate: Date
  var selectedReleaseDate: Date
  var prRange: ActivityRange
  var releaseRange: ActivityRange
  var selectedRepositoryID: Repository.ID?
  var selectedReleaseID: ReleaseMoment.ID?
  var cardDraft: WorkCardDraft

  init(
    repositories: [Repository],
    pullRequests: [PullRequest],
    releases: [ReleaseMoment],
    selectedPRDate: Date,
    selectedReleaseDate: Date,
    prRange: ActivityRange = .week,
    releaseRange: ActivityRange = .week,
    selectedRepositoryID: Repository.ID? = nil,
    selectedReleaseID: ReleaseMoment.ID? = "rel-prbar-140",
    cardDraft: WorkCardDraft = WorkCardDraft(source: .shippingSnapshot, theme: .clean, side: .publicSide, showRepos: true, showHandle: true, exactCounts: true, showPrivateLabels: false)
  ) {
    self.repositories = repositories
    self.pullRequests = pullRequests
    self.releases = releases
    self.selectedPRDate = selectedPRDate
    self.selectedReleaseDate = selectedReleaseDate
    self.prRange = prRange
    self.releaseRange = releaseRange
    self.selectedRepositoryID = selectedRepositoryID
    self.selectedReleaseID = selectedReleaseID
    self.cardDraft = cardDraft
  }

  static func sample() -> PRBarStore {
    PRBarStore(
      repositories: SampleData.repositories,
      pullRequests: SampleData.pullRequests,
      releases: SampleData.releases,
      selectedPRDate: SampleData.today,
      selectedReleaseDate: SampleData.today
    )
  }

  var includedRepositories: [Repository] {
    repositories.filter(\.included)
  }

  var filteredPullRequests: [PullRequest] {
    let includedIDs = Set(includedRepositories.map(\.id))
    return pullRequests.filter { includedIDs.contains($0.repoID) && Calendar.current.isDate($0.mergedAt, inSameDayAs: selectedPRDate) }
  }

  var filteredReleases: [ReleaseMoment] {
    let includedIDs = Set(includedRepositories.map(\.id))
    return releases.filter { includedIDs.contains($0.repoID) && Calendar.current.isDate($0.date, inSameDayAs: selectedReleaseDate) }
  }

  var cardHasPrivateEvidence: Bool {
    includedRepositories.contains { $0.visibility == .private }
  }
}
```

- [ ] **Step 4: Add release fixtures**

Extend `SampleData.swift` with:

```swift
static let releases: [ReleaseMoment] = [
  ReleaseMoment(id: "rel-prbar-140", repoID: "prbar", title: "GitHub auth fallback", tag: "v1.4.0", date: date("2026-05-24"), source: .release, notes: "Connects GitHub auth fallback, improves live data startup behavior, and preserves the last useful activity view.", url: URL(string: "https://github.com/neonwatty/prbar/releases/tag/v1.4.0")!),
  ReleaseMoment(id: "rel-prbar-130", repoID: "prbar", title: "Pages deployment cleanup", tag: "v1.3.0", date: date("2026-05-22"), source: .release, notes: "Updates GitHub Pages Actions, refreshes the landing page, and keeps the public preview current.", url: URL(string: "https://github.com/neonwatty/prbar/releases/tag/v1.3.0")!),
  ReleaseMoment(id: "tag-launch-100", repoID: "launch-kit", title: "Tagged v1.0.0", tag: "v1.0.0", date: date("2026-05-21"), source: .tag, notes: "Generated from merged PRs around this tag: release smoke harness and launch notes template.", url: URL(string: "https://github.com/neonwatty/launch-kit/releases/tag/v1.0.0")!),
  ReleaseMoment(id: "rel-launch-092", repoID: "launch-kit", title: "Smoke test expansion", tag: "v0.9.2", date: date("2026-05-18"), source: .release, notes: "Expands release smoke coverage and adds a clearer fixture baseline for launch checks.", url: URL(string: "https://github.com/neonwatty/launch-kit/releases/tag/v0.9.2")!),
  ReleaseMoment(id: "tag-prbar-121", repoID: "prbar", title: "Tagged v1.2.1", tag: "v1.2.1", date: date("2026-05-16"), source: .tag, notes: "No GitHub Release notes found. PRBar summarized merged PRs around this tag.", url: URL(string: "https://github.com/neonwatty/prbar/releases/tag/v1.2.1")!),
  ReleaseMoment(id: "rel-client-210", repoID: "client-api", title: "Webhook reliability update", tag: "v2.1.0", date: date("2026-05-14"), source: .release, notes: "Hardens webhook signature checks and adds clearer retry handling for customer integrations.", url: URL(string: "https://github.com/example/client-api/releases/tag/v2.1.0")!),
]
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
xcodebuild test \
  -project apple/PRBar.xcodeproj \
  -scheme PRBar \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath apple/build \
  CODE_SIGNING_ALLOWED=NO
```

Expected: `** TEST SUCCEEDED **`.

Commit:

```bash
git add apple/PRBarShared apple/PRBarTests
git commit -m "feat: add iOS fixture store"
```

## Task 3: Implement App Shell And Core Tabs

**Files:**
- Modify: `apple/PRBar/PRBarApp.swift`
- Create: `apple/PRBar/RootTabView.swift`
- Create: `apple/PRBar/Design/PRBarTheme.swift`
- Create: `apple/PRBar/PRs/PRsView.swift`
- Create: `apple/PRBar/Releases/ReleasesView.swift`
- Create: `apple/PRBar/Share/ShareView.swift`
- Create: `apple/PRBar/More/MoreView.swift`
- Modify: `apple/PRBarTests/PRBarModelTests.swift`

- [ ] **Step 1: Add a shell smoke UI test target to project.yml**

Modify `apple/project.yml` to add:

```yaml
  PRBarUITests:
    type: bundle.ui-testing
    supportedDestinations: [iOS]
    sources:
      - path: PRBarUITests
    dependencies:
      - target: PRBar
    settings:
      base:
        GENERATE_INFOPLIST_FILE: true
        PRODUCT_BUNDLE_IDENTIFIER: com.neonwatty.PRBar.ios.uitests
        TEST_TARGET_NAME: PRBar
        CODE_SIGN_STYLE: Automatic
        BUNDLE_LOADER: ""
```

Add `PRBarUITests` to the `PRBar` scheme test targets.

- [ ] **Step 2: Write tab UI tests**

Create `apple/PRBarUITests/PRBarUITests.swift`:

```swift
import XCTest

final class PRBarUITests: XCTestCase {
  func testTabsExposeReviewedPrototypeSurfaces() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))

    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))

    app.tabBars.buttons["Share"].tap()
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))

    app.tabBars.buttons["More"].tap()
    XCTAssertTrue(app.staticTexts["Menu"].waitForExistence(timeout: 2))
  }
}
```

- [ ] **Step 3: Run UI test and verify failure**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test \
  -project apple/PRBar.xcodeproj \
  -scheme PRBar \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath apple/build \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces
```

Expected: FAIL because `RootTabView` does not exist.

- [ ] **Step 4: Implement the tab shell**

Create `apple/PRBar/RootTabView.swift`:

```swift
import SwiftUI

struct RootTabView: View {
  @State var store: PRBarStore

  var body: some View {
    TabView {
      PRsView(store: store)
        .tabItem { Label("PRs", systemImage: "chart.bar.xaxis") }
      ReleasesView(store: store)
        .tabItem { Label("Releases", systemImage: "tag") }
      ShareView(store: store)
        .tabItem { Label("Share", systemImage: "square.and.arrow.up") }
      MoreView(store: store)
        .tabItem { Label("More", systemImage: "ellipsis") }
    }
  }
}
```

Modify `PRBarApp.swift`:

```swift
import SwiftUI

@main
struct PRBarApp: App {
  var body: some Scene {
    WindowGroup {
      RootTabView(store: .sample())
    }
  }
}
```

Create minimal views that satisfy the UI test:

```swift
import SwiftUI

struct PRsView: View {
  var store: PRBarStore
  var body: some View { NavigationStack { Text("Shipping rhythm").navigationTitle("PRs") } }
}

struct ReleasesView: View {
  var store: PRBarStore
  var body: some View { NavigationStack { Text("Shipping moments").navigationTitle("Releases") } }
}

struct ShareView: View {
  var store: PRBarStore
  var body: some View { NavigationStack { Text("Create a work card").navigationTitle("Share") } }
}

struct MoreView: View {
  var store: PRBarStore
  var body: some View { NavigationStack { Text("Menu").navigationTitle("More") } }
}
```

- [ ] **Step 5: Run UI test and commit**

Run the same UI test command. Expected: PASS.

Commit:

```bash
git add apple/project.yml apple/PRBar apple/PRBarUITests
git commit -m "feat: add iOS tab shell"
```

## Task 4: Implement Shared Calendar Components

**Files:**
- Create: `apple/PRBar/Components/RangePickerView.swift`
- Create: `apple/PRBar/Components/CalendarStripView.swift`
- Create: `apple/PRBar/Components/MonthHeatMapView.swift`
- Create: `apple/PRBarTests/CalendarSelectionTests.swift`

- [ ] **Step 1: Add calendar selection tests**

Create `apple/PRBarTests/CalendarSelectionTests.swift`:

```swift
import XCTest
@testable import PRBar

final class CalendarSelectionTests: XCTestCase {
  func testWeekDaysEndOnToday() {
    let days = CalendarDay.days(endingAt: SampleData.today, range: .week)
    XCTAssertEqual(days.count, 7)
    XCTAssertEqual(days.last?.date, SampleData.today)
  }

  func testMonthDaysCoverMayFixtureMonth() {
    let days = CalendarDay.days(endingAt: SampleData.today, range: .month)
    XCTAssertEqual(days.count, 31)
    XCTAssertEqual(days.first?.dayNumber, 1)
    XCTAssertEqual(days.last?.dayNumber, 31)
  }
}
```

- [ ] **Step 2: Implement calendar day helper**

Add to `PRBarModels.swift`:

```swift
struct CalendarDay: Identifiable, Equatable {
  var date: Date
  var count: Int

  var id: Date { date }
  var dayNumber: Int { Calendar.current.component(.day, from: date) }

  static func days(endingAt endDate: Date, range: ActivityRange) -> [CalendarDay] {
    let calendar = Calendar.current
    if range == .month {
      let components = calendar.dateComponents([.year, .month], from: endDate)
      let start = calendar.date(from: components)!
      let interval = calendar.range(of: .day, in: .month, for: endDate)!
      return interval.compactMap { offset in
        calendar.date(byAdding: .day, value: offset - 1, to: start).map { CalendarDay(date: $0, count: 0) }
      }
    }

    let count = range == .day ? 5 : 7
    return (0..<count).compactMap { offset in
      calendar.date(byAdding: .day, value: offset - count + 1, to: endDate).map { CalendarDay(date: $0, count: 0) }
    }
  }
}
```

- [ ] **Step 3: Add SwiftUI components**

Create `RangePickerView`, `CalendarStripView`, and `MonthHeatMapView` with these public initializers:

```swift
struct RangePickerView: View {
  @Binding var selection: ActivityRange
  var body: some View { Picker("Range", selection: $selection) { ForEach(ActivityRange.allCases) { Text($0.rawValue.capitalized).tag($0) } }.pickerStyle(.segmented) }
}

struct CalendarStripView: View {
  var days: [CalendarDay]
  @Binding var selectedDate: Date
  var body: some View { Text("Calendar") }
}

struct MonthHeatMapView: View {
  var days: [CalendarDay]
  @Binding var selectedDate: Date
  var body: some View { Text("May 2026") }
}
```

Replace the temporary `Text` bodies with seven equal day tiles for day/week and a seven-column grid for month. Each date button must expose an accessibility label such as `May 23`, show the day number, and show the item count when the count is greater than zero.

- [ ] **Step 4: Run tests and commit**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO -only-testing:PRBarTests/CalendarSelectionTests
```

Expected: PASS.

Commit:

```bash
git add apple/PRBar/Components apple/PRBarShared/PRBarModels.swift apple/PRBarTests/CalendarSelectionTests.swift
git commit -m "feat: add iOS calendar components"
```

## Task 5: Implement PRs And Releases Tabs

**Files:**
- Modify: `apple/PRBar/PRs/PRsView.swift`
- Modify: `apple/PRBar/Releases/ReleasesView.swift`
- Create: `apple/PRBar/Components/RepoDistributionView.swift`
- Create: `apple/PRBar/Components/ReleaseRowView.swift`
- Modify: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Add UI tests for PR and release interactions**

Append to `PRBarUITests.swift`:

```swift
func testPRCalendarAndRepoDistributionAreReachable() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launch()

  XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
  XCTAssertTrue(app.staticTexts["Distribution by repo"].exists)
  app.buttons["May 23"].tap()
  XCTAssertTrue(app.staticTexts["1 merged"].waitForExistence(timeout: 2))
}

func testReleasesCalendarShowsSelectedReleaseDetail() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launch()

  app.tabBars.buttons["Releases"].tap()
  XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))
  app.buttons["May 21"].tap()
  XCTAssertTrue(app.staticTexts["v1.0.0 Tagged v1.0.0"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO -only-testing:PRBarUITests/PRBarUITests
```

Expected: FAIL because the detailed tab UI is not implemented.

- [ ] **Step 3: Implement PRsView**

Implement `PRsView` as:

- `NavigationStack`
- title `PRs`
- page heading `Shipping rhythm`
- repo button to navigate to `RepositorySetupView`
- `RangePickerView`
- calendar strip or heat map based on `store.prRange`
- selected day metric
- simple bar chart from daily counts
- `Distribution by repo` section
- recent PR list
- repo drill-in with back button

Use accessibility labels on date buttons like `May 23`.

- [ ] **Step 4: Implement ReleasesView**

Implement `ReleasesView` as:

- title `Releases`
- page heading `Shipping moments`
- repo count button
- `RangePickerView`
- shared calendar
- selected release card
- date-grouped release rows
- no action buttons in release detail

- [ ] **Step 5: Run UI tests and commit**

Run UI tests. Expected: PASS.

Commit:

```bash
git add apple/PRBar/PRs apple/PRBar/Releases apple/PRBar/Components apple/PRBarUITests
git commit -m "feat: implement iOS PR and release tabs"
```

## Task 6: Implement Share Work-Card Flow

**Files:**
- Modify: `apple/PRBar/Share/ShareView.swift`
- Create: `apple/PRBar/Share/WorkCardView.swift`
- Create: `apple/PRBar/Share/WorkCardEvidenceView.swift`
- Create: `apple/PRBar/Share/ExportCardSheet.swift`
- Create: `apple/PRBar/Share/WorkCardRenderer.swift`
- Modify: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Add UI tests for export language**

Append:

```swift
func testShareTabExplainsWorkCardExport() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launch()

  app.tabBars.buttons["Share"].tap()
  XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Public side"].exists)
  app.buttons["Export card"].tap()
  XCTAssertTrue(app.staticTexts["Choose what leaves the app"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.buttons["Share public-side image"].exists)
  XCTAssertTrue(app.buttons["Copy caption"].exists)
}
```

- [ ] **Step 2: Implement visible Share flow**

Build `ShareView` from the HTML model:

- title `Share`
- heading `Create a work card`
- source panel
- private warning panel when `store.cardHasPrivateEvidence`
- export summary rows: `Image` and `Caption`
- `WorkCardView` for public/evidence sides
- buttons: `Show evidence` / `Show public card`, `Style & Privacy`, `Export card`
- sheet: `ExportCardSheet`

- [ ] **Step 3: Implement export sheet actions as safe stubs**

In `ExportCardSheet`, wire actions as local state toasts or alerts first:

```swift
enum ExportAction: String, CaseIterable, Identifiable {
  case sharePublicImage = "Share public-side image"
  case saveImage = "Save image"
  case copyImage = "Copy image"
  case copyCaption = "Copy caption"
  case exportEvidenceSide = "Export evidence side"
  case exportBothSides = "Export both sides"

  var id: String { rawValue }
}
```

Each button should dismiss the sheet and set an alert message matching the action. This first pass intentionally verifies export semantics before wiring native sharing APIs; native `ShareLink`, `UIActivityViewController`, Photos save, and pasteboard behavior should be implemented in a later export-focused plan.

- [ ] **Step 4: Run tests and commit**

Run UI tests. Expected: PASS.

Commit:

```bash
git add apple/PRBar/Share apple/PRBarUITests
git commit -m "feat: implement iOS share work cards"
```

## Task 7: Implement More, Repo Setup, Privacy, And Onboarding

**Files:**
- Modify: `apple/PRBar/More/MoreView.swift`
- Create: `apple/PRBar/More/RepositorySetupView.swift`
- Create: `apple/PRBar/More/PrivacyDefaultsView.swift`
- Create: `apple/PRBar/More/SettingsView.swift`
- Create: `apple/PRBar/Onboarding/OnboardingView.swift`
- Modify: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Add UI tests**

Append:

```swift
func testMoreMenuContainsRepositoryAndPrivacySettings() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launch()

  app.tabBars.buttons["More"].tap()
  XCTAssertTrue(app.buttons["Repos"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.buttons["Privacy"].exists)
  app.buttons["Repos"].tap()
  XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
}
```

- [ ] **Step 2: Implement More screens**

Implement:

- `MoreView` list with `Repos`, `Settings`, `Privacy`, `Sample Data`, `About`
- `RepositorySetupView` with included repo toggles, SSO disabled row, search field
- `PrivacyDefaultsView` with toggles matching the Share card draft
- `SettingsView` with fixture-only GitHub/status rows

- [ ] **Step 3: Implement first-run onboarding as a separate app state**

Add `AppRouteState` to `PRBarStore`:

```swift
enum AppRouteState: Equatable {
  case authenticated
  case signedOut
  case onboarding(OnboardingStep)
  case issue(AuthIssue)
}
```

Use launch arguments for UI tests:

```swift
if ProcessInfo.processInfo.arguments.contains("--signed-out") {
  store.routeState = .signedOut
}
```

- [ ] **Step 4: Run tests and commit**

Run all iOS tests. Expected: PASS.

Commit:

```bash
git add apple/PRBar/More apple/PRBar/Onboarding apple/PRBarShared apple/PRBarUITests
git commit -m "feat: implement iOS repo privacy and onboarding flows"
```

## Task 8: Add iOS Make Targets And Local Scripts

**Files:**
- Modify: `Makefile`
- Create: `scripts/ios-build.sh`
- Create: `scripts/ios-test.sh`
- Create: `scripts/ios-ui-smoke.sh`

- [ ] **Step 1: Add script wrappers**

Create `scripts/ios-build.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/ios-generate.sh
xcodebuild build \
  -project apple/PRBar.xcodeproj \
  -scheme "${IOS_SCHEME:-PRBar}" \
  -configuration "${IOS_CONFIGURATION:-Debug}" \
  -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 16}" \
  -derivedDataPath apple/build \
  CODE_SIGNING_ALLOWED="${IOS_CODE_SIGNING_ALLOWED:-NO}"
```

Create `scripts/ios-test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/ios-generate.sh
rm -rf apple/TestResults.xcresult
xcodebuild test \
  -project apple/PRBar.xcodeproj \
  -scheme "${IOS_SCHEME:-PRBar}" \
  -configuration "${IOS_CONFIGURATION:-Debug}" \
  -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 16}" \
  -derivedDataPath apple/build \
  -resultBundlePath apple/TestResults.xcresult \
  CODE_SIGNING_ALLOWED="${IOS_CODE_SIGNING_ALLOWED:-NO}"
```

Create `scripts/ios-ui-smoke.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${IOS_UI_SMOKE_PROFILE:-pr}"
case "$PROFILE" in
  fast) TESTS=("PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces") ;;
  pr) TESTS=("PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces" "PRBarUITests/PRBarUITests/testShareTabExplainsWorkCardExport") ;;
  full) TESTS=() ;;
  *) echo "Unknown IOS_UI_SMOKE_PROFILE '$PROFILE'" >&2; exit 64 ;;
esac

args=(
  test
  -project apple/PRBar.xcodeproj
  -scheme "${IOS_SCHEME:-PRBar}"
  -configuration "${IOS_CONFIGURATION:-Debug}"
  -destination "${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
  -derivedDataPath apple/build
)

if [[ "${IOS_DESTINATION:-}" != *"platform=iOS,"* ]]; then
  args+=("CODE_SIGNING_ALLOWED=${IOS_CODE_SIGNING_ALLOWED:-NO}")
fi

for test_id in "${TESTS[@]}"; do
  args+=("-only-testing:$test_id")
done

./scripts/ios-generate.sh
xcodebuild "${args[@]}"
```

Run:

```bash
chmod +x scripts/ios-build.sh scripts/ios-test.sh scripts/ios-ui-smoke.sh
```

- [ ] **Step 2: Add Makefile targets**

Append:

```make
.PHONY: ios-generate ios-build ios-test ios-ui-smoke ios-ci-local

ios-generate:
	./scripts/ios-generate.sh

ios-build:
	./scripts/ios-build.sh

ios-test:
	./scripts/ios-test.sh

ios-ui-smoke:
	./scripts/ios-ui-smoke.sh

ios-ci-local: ios-build ios-test ios-ui-smoke
```

- [ ] **Step 3: Run local target and commit**

Run:

```bash
make ios-ci-local
```

Expected: build, tests, and simulator smoke pass.

Commit:

```bash
git add Makefile scripts/ios-*.sh
git commit -m "ci: add local iOS build and smoke scripts"
```

## Task 9: Add iOS CI With Path Filtering

**Files:**
- Create: `.github/workflows/ios.yml`
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Add dedicated iOS workflow**

Create `.github/workflows/ios.yml`:

```yaml
name: iOS

on:
  pull_request:
    branches: [main]
    paths:
      - apple/**
      - scripts/ios-*.sh
      - .github/workflows/ios.yml
      - project.yml
      - package.json
      - package-lock.json
  push:
    branches: [main]
    paths:
      - apple/**
      - scripts/ios-*.sh
      - .github/workflows/ios.yml
  merge_group:
  workflow_dispatch:
    inputs:
      smoke_profile:
        description: iOS UI smoke profile
        required: true
        default: pr
        type: choice
        options: [fast, pr, full]

concurrency:
  group: ios-${{ github.head_ref || github.sha }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  build-test-smoke:
    name: Build, Test, UI Smoke
    runs-on: macos-15
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v6
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.3.app/Contents/Developer
      - name: Install xcodegen
        run: brew install xcodegen
      - name: Build
        run: ./scripts/ios-build.sh
      - name: Unit and UI tests
        run: ./scripts/ios-test.sh
      - name: UI smoke
        env:
          IOS_UI_SMOKE_PROFILE: ${{ inputs.smoke_profile || 'pr' }}
        run: ./scripts/ios-ui-smoke.sh
      - name: Upload iOS test results
        if: failure()
        uses: actions/upload-artifact@v7
        with:
          name: ios-test-results
          path: apple/TestResults.xcresult
          retention-days: 14
```

- [ ] **Step 2: Keep root CI scoped to macOS**

Modify `.github/workflows/ci.yml` detect-changes grep from:

```bash
'^(Sources/|Tests/|scripts/|project.yml|Makefile|\.github/)'
```

to:

```bash
'^(Sources/|Tests/|scripts/(?!ios-).*|project.yml|Makefile|\.github/workflows/(ci|auto-merge|release)\.yml$)'
```

Because bash grep does not support negative lookahead in ERE, implement with two filters:

```bash
changed_files="$(git diff --name-only "$BASE_SHA" "$HEAD_SHA")"
if printf '%s\n' "$changed_files" | grep -Eq '^(Sources/|Tests/|project.yml|Makefile|\.github/workflows/(ci|auto-merge|release)\.yml$)'; then
  echo "code=true" >> "$GITHUB_OUTPUT"
elif printf '%s\n' "$changed_files" | grep -Eq '^scripts/' && ! printf '%s\n' "$changed_files" | grep -Evq '^scripts/ios-'; then
  echo "code=false" >> "$GITHUB_OUTPUT"
elif printf '%s\n' "$changed_files" | grep -Eq '^scripts/'; then
  echo "code=true" >> "$GITHUB_OUTPUT"
elif printf '%s\n' "$changed_files" | grep -Eq '^(\.releaserc\.json|package-lock\.json|package\.json)$'; then
  echo "code=true" >> "$GITHUB_OUTPUT"
else
  echo "code=false" >> "$GITHUB_OUTPUT"
fi
```

- [ ] **Step 3: Verify workflow syntax locally**

Run:

```bash
ruby -e 'require "yaml"; Dir[".github/workflows/*.yml"].each { |f| YAML.load_file(f); puts f }'
```

Expected: all workflow files print without YAML parse errors.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ios.yml .github/workflows/ci.yml
git commit -m "ci: add path-filtered iOS workflow"
```

## Task 10: Add Physical Preview E2E Testing

**Files:**
- Modify: `apple/project.yml`
- Create: `apple/PRBarPreviewUITests/PRBarPreviewUITests.swift`
- Create: `scripts/ios-resolve-preview-device.sh`
- Create: `scripts/ios-list-devices.sh`
- Create: `scripts/ios-preview-runner-preflight.sh`
- Create: `scripts/ios-preview-install.sh`
- Create: `scripts/ios-preview-device-smoke.sh`
- Create: `.github/workflows/ios-physical-preview.yml`
- Create: `.github/workflows/ios-preview-install.yml`
- Create: `.github/workflows/ios-preview-runner-health.yml`
- Modify: `Docs/GitHubIntegration.md`

- [ ] **Step 1: Add preview UI test target**

Add to `apple/project.yml`:

```yaml
  PRBarPreviewUITests:
    type: bundle.ui-testing
    supportedDestinations: [iOS]
    sources:
      - path: PRBarPreviewUITests
    dependencies:
      - target: PRBarPreview
    settings:
      base:
        GENERATE_INFOPLIST_FILE: true
        PRODUCT_BUNDLE_IDENTIFIER: com.neonwatty.PRBar.ios.preview.uitests
        TEST_TARGET_NAME: PRBarPreview
        CODE_SIGN_STYLE: Automatic
        BUNDLE_LOADER: ""
```

Create `apple/PRBarPreviewUITests/PRBarPreviewUITests.swift`:

```swift
import XCTest

final class PRBarPreviewUITests: XCTestCase {
  func testPreviewDeviceCanLaunchCoreTabs() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 8))
    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 4))
    app.tabBars.buttons["Share"].tap()
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 4))
  }
}
```

- [ ] **Step 2: Add physical-device scripts**

Use the `issuectl` pattern with PRBar names:

- `IOS_DEVICE_NAME=iPhone-preview`
- `IOS_PROJECT=apple/PRBar.xcodeproj`
- `IOS_SCHEME=PRBarPreview`
- `IOS_UI_SCHEME=PRBarPreview`
- `IOS_UI_TEST_TARGET=PRBarPreviewUITests`
- `PRODUCT_BUNDLE_IDENTIFIER=com.neonwatty.PRBar.ios.preview`

Create PRBar-specific physical preview scripts using the `issuectl` script interfaces as the reference shape and these defaults:

```bash
PROJECT="${IOS_PROJECT:-apple/PRBar.xcodeproj}"
SCHEME="${IOS_SCHEME:-PRBarPreview}"
DEVICE_NAME="${IOS_DEVICE_NAME:-iPhone-preview}"
```

In `ios-preview-install.sh`, verify the built app path:

```bash
app_path="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/PRBarPreview.app"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"
if [ "$bundle_id" != "com.neonwatty.PRBar.ios.preview" ]; then
  echo "Refusing to install unexpected bundle id '$bundle_id' from $app_path" >&2
  exit 70
fi
```

- [ ] **Step 3: Add manual physical preview workflows**

Create `.github/workflows/ios-physical-preview.yml`:

```yaml
name: iOS Physical Preview

on:
  workflow_dispatch:
    inputs:
      ref:
        description: Git ref or SHA to test
        required: false
        type: string
      smoke_profile:
        description: Physical iPhone smoke profile
        required: true
        default: pr
        type: choice
        options: [fast, pr, full]

concurrency:
  group: ios-physical-preview
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  physical-preview:
    name: Physical iPhone Preview Smoke
    runs-on: [self-hosted, macOS, prbar-ios, iphone-preview]
    timeout-minutes: 25
    env:
      IOS_DEVICE_NAME: iPhone-preview
      IOS_SCHEME: PRBarPreview
      IOS_UI_TEST_TARGET: PRBarPreviewUITests
      IOS_CONFIGURATION: Debug
      IOS_DEVICE_READY_TIMEOUT: 60
      IOS_XCODEBUILD_EXTRA_ARGS: -allowProvisioningUpdates -allowProvisioningDeviceRegistration
      IOS_PREVIEW_KEYCHAIN_PASSWORD: ${{ secrets.IOS_PREVIEW_KEYCHAIN_PASSWORD }}
      IOS_PREVIEW_SET_KEY_PARTITION_LIST: "1"
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          ref: ${{ inputs.ref || github.ref }}
      - name: Preflight runner, signing, and iPhone-preview
        run: ./scripts/ios-preview-runner-preflight.sh
      - name: Resolve iPhone-preview
        run: ./scripts/ios-resolve-preview-device.sh
      - name: Run physical preview smoke
        env:
          IOS_UI_SMOKE_PROFILE: ${{ inputs.smoke_profile || 'pr' }}
        run: ./scripts/ios-preview-device-smoke.sh
```

Create `.github/workflows/ios-preview-install.yml` and `.github/workflows/ios-preview-runner-health.yml` with the same runner labels and the PRBar scripts named above. The install workflow must call `scripts/ios-preview-install.sh`; the health workflow must call `scripts/ios-preview-runner-preflight.sh`.

- [ ] **Step 4: Document runner prerequisites**

Append to `Docs/GitHubIntegration.md`:

```markdown
## iOS Preview Runner

Physical iPhone preview testing uses a self-hosted macOS runner with labels
`self-hosted`, `macOS`, `prbar-ios`, and `iphone-preview`.

The runner Mac needs:

- Xcode with iOS device support installed.
- A trusted, unlocked physical iPhone named `iPhone-preview`.
- A signing identity visible to the GitHub Actions runner service.
- The secret `IOS_PREVIEW_KEYCHAIN_PASSWORD` when the signing keychain must be unlocked non-interactively.
- Automation Mode enabled without local authentication when available.

Physical preview workflows are manual by default. Pull requests use simulator CI
unless a maintainer explicitly dispatches the physical preview workflow.
```

- [ ] **Step 5: Verify scripts and commit**

Run on a local Mac with no device attached:

```bash
bash -n scripts/ios-resolve-preview-device.sh scripts/ios-list-devices.sh scripts/ios-preview-runner-preflight.sh scripts/ios-preview-install.sh scripts/ios-preview-device-smoke.sh
```

Expected: shell syntax passes.

Commit:

```bash
git add apple/project.yml apple/PRBarPreviewUITests scripts/ios-*.sh .github/workflows/ios-physical-preview.yml .github/workflows/ios-preview-install.yml .github/workflows/ios-preview-runner-health.yml Docs/GitHubIntegration.md
git commit -m "ci: add iOS physical preview workflows"
```

## Task 11: Final Verification And PR Readiness

**Files:**
- Modify: `README.md`
- Modify: `mockups/ios/README.md`

- [ ] **Step 1: Document the new native app location**

Add a short section to `README.md`:

~~~markdown
## iOS Prototype App

The native iOS app lives under `apple/` and is generated with XcodeGen:

```bash
make ios-generate
make ios-ci-local
```

The first implementation is fixture-backed and follows the reviewed HTML mockup in
`mockups/ios/`.
~~~

- [ ] **Step 2: Add the Swift mapping note to the mockup README**

Append to `mockups/ios/README.md`:

```markdown
## Native Mapping

The reviewed HTML surfaces map to the SwiftUI implementation plan in
`Docs/superpowers/plans/2026-05-26-ios-swiftui-implementation.md`.
```

- [ ] **Step 3: Run complete local verification**

Run:

```bash
make ci-local
make ios-ci-local
npm run verify:ios-mockups
bash -n scripts/ios-resolve-preview-device.sh scripts/ios-list-devices.sh scripts/ios-preview-runner-preflight.sh scripts/ios-preview-install.sh scripts/ios-preview-device-smoke.sh
ruby -e 'require "yaml"; Dir[".github/workflows/*.yml"].each { |f| YAML.load_file(f); puts f }'
```

Expected:

- macOS lint/build/tests/smoke pass
- iOS simulator build/tests/smoke pass
- mockup verification passes
- shell syntax passes
- workflow YAML parses

- [ ] **Step 4: Commit docs**

```bash
git add README.md mockups/ios/README.md
git commit -m "docs: document iOS app implementation path"
```

## Self-Review

- Spec coverage: The plan maps every prototype tab to SwiftUI views, creates an iOS app layout, defines path-filtered CI, and adds physical preview e2e workflows modeled after `mean-weasel/issuectl`.
- Placeholder scan: The plan avoids open-ended placeholders; where visual implementation is described, the exact target file and visible behavior are named.
- Type consistency: Model names are consistent across tasks: `Repository`, `PullRequest`, `ReleaseMoment`, `ActivityRange`, `WorkCardDraft`, `PRBarStore`, and `SampleData`.
- Risk callout: The one deliberate product deferral is real GitHub integration. The first Swift app is fixture-backed so view structure, navigation, export semantics, CI, and e2e can land before OAuth and live sync.
