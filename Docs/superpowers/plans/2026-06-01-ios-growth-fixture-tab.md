# iOS Growth Fixture Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fixture-backed iOS Growth tab that shows PostHog and Search Console movement near shipped PRs/releases without adding live OAuth, tokens, or network calls.

**Architecture:** Add provider-agnostic Growth models to `apple/PRBarShared`, seed them through `SampleData`, expose Growth state and range selection through `PRBarStore`, and render the new tab with small SwiftUI views under `apple/PRBar/Growth`. Keep Growth refresh separate from GitHub activity refresh and keep Growth metrics private-only: no share-card integration in this slice.

**Tech Stack:** Swift 6, SwiftUI, Observation, XCTest, XcodeGen project generation.

---

## Scope

This plan implements **Issue #109 Slice 1 only**:

- Included: fixture-backed Growth tab, shared models, sample PostHog/Search Console data, connection/setup states, shipping context, range picker, partial provider issue state, tests.
- Excluded: real PostHog API calls, Google OAuth, Search Console API calls, Keychain storage, alerts, background refresh, public sharing of Growth metrics.

## File Structure

- Create `apple/PRBarShared/GrowthModels.swift`
  - Owns Growth domain types: `GrowthProviderKind`, `GrowthMetricKind`, `GrowthConnection`, `GrowthMetric`, `GrowthDashboardSnapshot`, `GrowthShippingContext`, row models.
- Create `apple/PRBarShared/GrowthProvider.swift`
  - Defines `GrowthDashboardProviding`, `StaticGrowthDashboardProvider`, and `FailingGrowthDashboardProvider` for tests.
- Modify `apple/PRBarShared/SampleData.swift`
  - Adds fixture project, connections, metrics, top events, top queries, top pages, and dashboard variants.
- Modify `apple/PRBarShared/PRBarStore.swift`
  - Adds `growthSnapshot`, `growthRange`, `selectedGrowthProjectID`, `isRefreshingGrowth`, `growthRefreshIssue`, and methods `refreshGrowth()`, `setGrowthRange(_:)`, `selectGrowthProject(_:)`.
- Create `apple/PRBar/Growth/GrowthView.swift`
  - Owns selected metric UI state and renders header, project row, source badges, range picker, summary tiles, chart, shipping context, provider sections, setup cards.
- Create `apple/PRBar/Growth/GrowthMetricTileView.swift`
  - Renders one summary metric.
- Create `apple/PRBar/Growth/GrowthTrendChartView.swift`
  - Renders stable daily bars for the selected metric.
- Create `apple/PRBar/Growth/GrowthProviderSectionView.swift`
  - Renders PostHog top events and Search Console top queries/pages.
- Create `apple/PRBar/Growth/GrowthSetupCardView.swift`
  - Renders unavailable provider setup affordances.
- Modify `apple/PRBar/RootTabView.swift`
  - Adds `GrowthView(store: store)` between Releases and Share.
- Modify `apple/PRBarUITests/PRBarUITests.swift`
  - Adds Growth tab smoke and fixture assertions.
- Modify `apple/PRBarTests/PRBarModelTests.swift`
  - Adds Growth model/store behavior tests.

## Acceptance Criteria

- Authenticated iOS users see bottom tabs: `PRs`, `Releases`, `Growth`, `Share`, `More`.
- Growth tab shows fixture metrics for PostHog and Search Console.
- Growth range can switch between `Day`, `Week`, and `Month`.
- Growth chart updates its visible point count when range changes.
- Growth screen shows shipping context from existing PR/release fixture data.
- If one provider has an issue, the other provider's metrics remain visible.
- If a provider is not connected, the screen shows a setup card instead of zero-value metrics.
- Growth refresh has its own loading/error state and does not flip `isRefreshingActivity`.
- Growth data is not added to share cards in this slice.
- Local simulator unit/UI tests pass.

---

### Task 1: Create Growth Models

**Files:**
- Create: `apple/PRBarShared/GrowthModels.swift`
- Test: `apple/PRBarTests/PRBarModelTests.swift`

- [ ] **Step 1: Write failing model tests**

Add these tests near the other model-level tests in `apple/PRBarTests/PRBarModelTests.swift`:

```swift
func testGrowthSnapshotOrdersVisibleMetricsByConnectedProviderPriority() {
  let snapshot = GrowthDashboardSnapshot.fixture(range: .week)

  XCTAssertEqual(
    snapshot.visibleMetrics.map(\.kind),
    [.activeUsers, .keyEventCount, .searchClicks, .searchImpressions]
  )
  XCTAssertEqual(snapshot.defaultMetric?.kind, .activeUsers)
}

func testGrowthSnapshotKeepsPartialProviderDataVisible() {
  let snapshot = GrowthDashboardSnapshot.fixture(
    range: .week,
    connections: [
      GrowthConnection(
        id: "posthog-main",
        provider: .postHog,
        displayName: "PostHog",
        status: .needsAttention,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
        issue: "API key needs attention"
      ),
      GrowthConnection(
        id: "gsc-main",
        provider: .searchConsole,
        displayName: "Search Console",
        status: .connected,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
        issue: nil
      ),
    ]
  )

  XCTAssertTrue(snapshot.visibleMetrics.contains { $0.provider == .searchConsole })
  XCTAssertFalse(snapshot.visibleMetrics.contains { $0.provider == .postHog })
  XCTAssertEqual(snapshot.connection(for: .postHog)?.status, .needsAttention)
}

func testGrowthMetricNormalizesMissingDaysForSelectedRange() {
  let metric = GrowthMetric(
    id: "search-clicks",
    provider: .searchConsole,
    kind: .searchClicks,
    title: "Search clicks",
    value: 42,
    formattedValue: "42",
    unit: .count,
    delta: GrowthDelta(value: 0.12, formattedValue: "+12%", direction: .positive),
    series: [
      GrowthMetricPoint(date: SampleData.date("2026-05-20"), value: 10),
      GrowthMetricPoint(date: SampleData.date("2026-05-22"), value: 32),
    ]
  )

  let normalized = metric.normalizedSeries(endingAt: SampleData.date("2026-05-24"), range: .week)

  XCTAssertEqual(normalized.count, 7)
  XCTAssertEqual(normalized.first?.date, SampleData.date("2026-05-18"))
  XCTAssertEqual(normalized.last?.date, SampleData.date("2026-05-24"))
  XCTAssertEqual(normalized.first { CalendarDay.isSameDay($0.date, SampleData.date("2026-05-21")) }?.value, 0)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PRBarModelTests/testGrowthSnapshotOrdersVisibleMetricsByConnectedProviderPriority -only-testing:PRBarTests/PRBarModelTests/testGrowthSnapshotKeepsPartialProviderDataVisible -only-testing:PRBarTests/PRBarModelTests/testGrowthMetricNormalizesMissingDaysForSelectedRange
```

Expected: FAIL because `GrowthDashboardSnapshot`, `GrowthConnection`, `GrowthMetric`, and related types do not exist.

- [ ] **Step 3: Add Growth model types**

Create `apple/PRBarShared/GrowthModels.swift`:

```swift
import Foundation

enum GrowthProviderKind: String, CaseIterable, Identifiable, Codable, Sendable {
  case postHog
  case searchConsole

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .postHog: "PostHog"
    case .searchConsole: "Search Console"
    }
  }
}

enum GrowthConnectionStatus: String, Codable, Sendable {
  case connected
  case notConnected
  case needsAttention
  case refreshing
}

struct GrowthConnection: Identifiable, Codable, Equatable, Sendable {
  var id: String
  var provider: GrowthProviderKind
  var displayName: String
  var status: GrowthConnectionStatus
  var lastRefreshedAt: Date?
  var issue: String?
}

struct GrowthProject: Identifiable, Codable, Equatable, Sendable {
  var id: String
  var name: String
  var repositoryIDs: [Repository.ID]
  var postHogConnectionID: GrowthConnection.ID?
  var searchConsoleConnectionID: GrowthConnection.ID?
}

enum GrowthMetricKind: String, CaseIterable, Identifiable, Codable, Sendable {
  case activeUsers
  case keyEventCount
  case conversionRate
  case searchClicks
  case searchImpressions
  case searchCTR
  case averagePosition

  var id: String { rawValue }
}

enum GrowthMetricUnit: String, Codable, Sendable {
  case count
  case percent
  case position
}

struct GrowthDelta: Codable, Equatable, Sendable {
  enum Direction: String, Codable, Sendable {
    case positive
    case negative
    case neutral
  }

  var value: Double
  var formattedValue: String
  var direction: Direction
}

struct GrowthMetricPoint: Identifiable, Codable, Equatable, Sendable {
  var date: Date
  var value: Double

  var id: Date { date }
}

struct GrowthMetric: Identifiable, Codable, Equatable, Sendable {
  var id: String
  var provider: GrowthProviderKind
  var kind: GrowthMetricKind
  var title: String
  var value: Double
  var formattedValue: String
  var unit: GrowthMetricUnit
  var delta: GrowthDelta?
  var series: [GrowthMetricPoint]

  func normalizedSeries(endingAt endDate: Date, range: ActivityRange) -> [GrowthMetricPoint] {
    CalendarDay.days(endingAt: endDate, range: range).map { day in
      let matching = series.first { CalendarDay.isSameDay($0.date, day.date) }
      return GrowthMetricPoint(date: day.date, value: matching?.value ?? 0)
    }
  }
}

struct GrowthListRow: Identifiable, Codable, Equatable, Sendable {
  var id: String
  var title: String
  var detail: String
  var value: String
}

struct GrowthShippingContext: Codable, Equatable, Sendable {
  var pullRequestCount: Int
  var releaseCount: Int
  var topRepositoryName: String?

  var summary: String {
    let releaseWord = releaseCount == 1 ? "release" : "releases"
    let pullRequestWord = pullRequestCount == 1 ? "PR" : "PRs"
    return "\(releaseCount) \(releaseWord) and \(pullRequestCount) \(pullRequestWord) landed during this window."
  }
}

struct GrowthDashboardIssue: Identifiable, Codable, Equatable, Sendable {
  var id: String
  var provider: GrowthProviderKind?
  var title: String
  var detail: String
}

struct GrowthDashboardSnapshot: Codable, Equatable, Sendable {
  var project: GrowthProject
  var range: ActivityRange
  var anchorDate: Date
  var connections: [GrowthConnection]
  var metrics: [GrowthMetric]
  var topEvents: [GrowthListRow]
  var topQueries: [GrowthListRow]
  var topPages: [GrowthListRow]
  var shippingContext: GrowthShippingContext
  var issues: [GrowthDashboardIssue]

  var visibleMetrics: [GrowthMetric] {
    let connectedProviders = Set(
      connections
        .filter { $0.status == .connected || $0.status == .refreshing }
        .map(\.provider)
    )
    let priority: [GrowthMetricKind] = [.activeUsers, .keyEventCount, .searchClicks, .searchImpressions, .conversionRate, .searchCTR, .averagePosition]

    return metrics
      .filter { connectedProviders.contains($0.provider) }
      .sorted { lhs, rhs in
        let lhsIndex = priority.firstIndex(of: lhs.kind) ?? priority.count
        let rhsIndex = priority.firstIndex(of: rhs.kind) ?? priority.count
        return lhsIndex < rhsIndex
      }
  }

  var defaultMetric: GrowthMetric? {
    visibleMetrics.first
  }

  func connection(for provider: GrowthProviderKind) -> GrowthConnection? {
    connections.first { $0.provider == provider }
  }
}
```

- [ ] **Step 4: Add test fixture factory**

Add this extension to the bottom of `apple/PRBarShared/GrowthModels.swift` so tests can build controlled snapshots without depending on `SampleData` yet:

```swift
extension GrowthDashboardSnapshot {
  static func fixture(
    range: ActivityRange,
    connections: [GrowthConnection]? = nil
  ) -> GrowthDashboardSnapshot {
    let anchorDate = SampleData.date("2026-05-24")
    let project = GrowthProject(
      id: "prbar-product",
      name: "PRBar",
      repositoryIDs: ["prbar", "launch-kit"],
      postHogConnectionID: "posthog-main",
      searchConsoleConnectionID: "gsc-main"
    )
    let resolvedConnections = connections ?? [
      GrowthConnection(id: "posthog-main", provider: .postHog, displayName: "PostHog", status: .connected, lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"), issue: nil),
      GrowthConnection(id: "gsc-main", provider: .searchConsole, displayName: "Search Console", status: .connected, lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"), issue: nil),
    ]

    return GrowthDashboardSnapshot(
      project: project,
      range: range,
      anchorDate: anchorDate,
      connections: resolvedConnections,
      metrics: [
        GrowthMetric(id: "active-users", provider: .postHog, kind: .activeUsers, title: "Active users", value: 184, formattedValue: "184", unit: .count, delta: GrowthDelta(value: 0.18, formattedValue: "+18%", direction: .positive), series: Self.fixtureSeries([18, 22, 21, 24, 31, 34, 34])),
        GrowthMetric(id: "key-event-count", provider: .postHog, kind: .keyEventCount, title: "Key events", value: 61, formattedValue: "61", unit: .count, delta: GrowthDelta(value: 0.08, formattedValue: "+8%", direction: .positive), series: Self.fixtureSeries([4, 7, 6, 8, 10, 12, 14])),
        GrowthMetric(id: "search-clicks", provider: .searchConsole, kind: .searchClicks, title: "Search clicks", value: 96, formattedValue: "96", unit: .count, delta: GrowthDelta(value: 0.12, formattedValue: "+12%", direction: .positive), series: Self.fixtureSeries([9, 11, 10, 13, 16, 19, 18])),
        GrowthMetric(id: "search-impressions", provider: .searchConsole, kind: .searchImpressions, title: "Impressions", value: 4200, formattedValue: "4.2K", unit: .count, delta: GrowthDelta(value: -0.03, formattedValue: "-3%", direction: .negative), series: Self.fixtureSeries([510, 540, 530, 610, 620, 690, 700])),
      ],
      topEvents: [
        GrowthListRow(id: "signup", title: "signup completed", detail: "Configured key event", value: "61"),
        GrowthListRow(id: "project-created", title: "project created", detail: "Activation event", value: "29"),
      ],
      topQueries: [
        GrowthListRow(id: "pr stats app", title: "pr stats app", detail: "query", value: "31 clicks"),
        GrowthListRow(id: "github release proof", title: "github release proof", detail: "query", value: "18 clicks"),
      ],
      topPages: [
        GrowthListRow(id: "home", title: "/product", detail: "top page", value: "43 clicks"),
        GrowthListRow(id: "docs", title: "/docs/share-proof", detail: "top page", value: "22 clicks"),
      ],
      shippingContext: GrowthShippingContext(pullRequestCount: 18, releaseCount: 2, topRepositoryName: "prbar"),
      issues: []
    )
  }

  private static func fixtureSeries(_ values: [Double]) -> [GrowthMetricPoint] {
    let dates = CalendarDay.days(endingAt: SampleData.date("2026-05-24"), range: .week).map(\.date)
    return zip(dates, values).map { GrowthMetricPoint(date: $0.0, value: $0.1) }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apple/PRBarShared/GrowthModels.swift apple/PRBarTests/PRBarModelTests.swift
git commit -m "feat: add growth dashboard models"
```

---

### Task 2: Add Growth Provider and Store State

**Files:**
- Create: `apple/PRBarShared/GrowthProvider.swift`
- Modify: `apple/PRBarShared/PRBarStore.swift`
- Modify: `apple/PRBarShared/SampleData.swift`
- Test: `apple/PRBarTests/PRBarModelTests.swift`

- [ ] **Step 1: Write failing store tests**

Add these tests to `apple/PRBarTests/PRBarModelTests.swift`:

```swift
func testGrowthRangeRefreshesSnapshotWithoutRefreshingGitHubActivity() async {
  let provider = StaticGrowthDashboardProvider(snapshot: .fixture(range: .week))
  let store = PRBarStore.sample(growthProvider: provider)

  store.setGrowthRange(.month)
  await store.refreshGrowth()

  XCTAssertEqual(store.growthRange, .month)
  XCTAssertEqual(store.growthSnapshot.range, .month)
  XCTAssertFalse(store.isRefreshingActivity)
  XCTAssertFalse(store.isRefreshingGrowth)
}

func testGrowthRefreshPreservesLastSnapshotOnFailure() async {
  let original = GrowthDashboardSnapshot.fixture(range: .week)
  let store = PRBarStore.sample(
    growthProvider: FailingGrowthDashboardProvider(error: GrowthProviderError.providerUnavailable("PostHog is unavailable"))
  )
  store.growthSnapshot = original

  await store.refreshGrowth()

  XCTAssertEqual(store.growthSnapshot, original)
  XCTAssertEqual(store.growthRefreshIssue?.title, "Growth refresh failed")
}

func testSelectingGrowthProjectRefreshesFixtureProject() async {
  let store = PRBarStore.sample(
    growthProvider: StaticGrowthDashboardProvider(snapshot: .fixture(range: .week))
  )

  store.selectGrowthProject("prbar-product")
  await store.refreshGrowth()

  XCTAssertEqual(store.selectedGrowthProjectID, "prbar-product")
  XCTAssertEqual(store.growthSnapshot.project.id, "prbar-product")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PRBarModelTests/testGrowthRangeRefreshesSnapshotWithoutRefreshingGitHubActivity -only-testing:PRBarTests/PRBarModelTests/testGrowthRefreshPreservesLastSnapshotOnFailure -only-testing:PRBarTests/PRBarModelTests/testSelectingGrowthProjectRefreshesFixtureProject
```

Expected: FAIL because the store does not have Growth provider/state methods.

- [ ] **Step 3: Add provider protocol and static providers**

Create `apple/PRBarShared/GrowthProvider.swift`:

```swift
import Foundation

protocol GrowthDashboardProviding: Sendable {
  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot
}

enum GrowthProviderError: LocalizedError, Equatable {
  case providerUnavailable(String)

  var errorDescription: String? {
    switch self {
    case let .providerUnavailable(message): message
    }
  }
}

struct StaticGrowthDashboardProvider: GrowthDashboardProviding {
  var snapshot: GrowthDashboardSnapshot

  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot {
    var updated = snapshot
    updated.project.id = projectID
    updated.range = range
    updated.anchorDate = anchorDate
    return updated
  }
}

struct FailingGrowthDashboardProvider: GrowthDashboardProviding {
  var error: GrowthProviderError

  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot {
    throw error
  }
}
```

- [ ] **Step 4: Add sample Growth data**

Add this to `apple/PRBarShared/SampleData.swift`, before the closing brace:

```swift
static let growthDashboard = GrowthDashboardSnapshot.fixture(range: .week)
```

- [ ] **Step 5: Wire Growth into `PRBarStore`**

Modify `apple/PRBarShared/PRBarStore.swift`:

Add stored properties next to the existing activity state:

```swift
var growthSnapshot: GrowthDashboardSnapshot
var growthRange: ActivityRange
var selectedGrowthProjectID: GrowthProject.ID
var isRefreshingGrowth = false
var growthRefreshIssue: AuthIssue?
private let growthProvider: GrowthDashboardProviding
```

Add init parameters after `activityCacheStore`:

```swift
growthSnapshot: GrowthDashboardSnapshot = SampleData.growthDashboard,
growthRange: ActivityRange = .week,
selectedGrowthProjectID: GrowthProject.ID = SampleData.growthDashboard.project.id,
growthProvider: GrowthDashboardProviding = StaticGrowthDashboardProvider(snapshot: SampleData.growthDashboard),
```

Assign them in `init`:

```swift
self.growthSnapshot = growthSnapshot
self.growthRange = growthRange
self.selectedGrowthProjectID = selectedGrowthProjectID
self.growthProvider = growthProvider
```

Add `growthProvider` to `sample(...)` parameters:

```swift
growthProvider: GrowthDashboardProviding = StaticGrowthDashboardProvider(snapshot: SampleData.growthDashboard),
```

Pass it through the `PRBarStore(...)` call:

```swift
growthProvider: growthProvider,
```

Add methods near the existing refresh methods:

```swift
func setGrowthRange(_ range: ActivityRange) {
  growthRange = range
}

func selectGrowthProject(_ projectID: GrowthProject.ID) {
  selectedGrowthProjectID = projectID
}

@MainActor
func refreshGrowth() async {
  isRefreshingGrowth = true
  growthRefreshIssue = nil
  defer { isRefreshingGrowth = false }

  do {
    growthSnapshot = try await growthProvider.dashboard(
      projectID: selectedGrowthProjectID,
      range: growthRange,
      anchorDate: activityAnchorDate
    )
  } catch {
    growthRefreshIssue = AuthIssue(
      id: "growth-refresh-failed",
      title: "Growth refresh failed",
      message: error.localizedDescription
    )
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add apple/PRBarShared/GrowthProvider.swift apple/PRBarShared/PRBarStore.swift apple/PRBarShared/SampleData.swift apple/PRBarTests/PRBarModelTests.swift
git commit -m "feat: add fixture growth store"
```

---

### Task 3: Build Growth SwiftUI Components

**Files:**
- Create: `apple/PRBar/Growth/GrowthMetricTileView.swift`
- Create: `apple/PRBar/Growth/GrowthTrendChartView.swift`
- Create: `apple/PRBar/Growth/GrowthProviderSectionView.swift`
- Create: `apple/PRBar/Growth/GrowthSetupCardView.swift`
- Test: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Write failing UI component smoke test through the future tab**

Add this to `apple/PRBarUITests/PRBarUITests.swift`:

```swift
func testGrowthTabRendersFixtureMetrics() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launch()

  app.tapTab("Growth")

  XCTAssertTrue(app.staticTexts["Usage and search movement near shipped work"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Active users"].exists)
  XCTAssertTrue(app.staticTexts["Search clicks"].exists)
  XCTAssertTrue(app.staticTexts["2 releases and 18 PRs landed during this window."].exists)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersFixtureMetrics
```

Expected: FAIL because there is no Growth tab yet.

- [ ] **Step 3: Add metric tile view**

Create `apple/PRBar/Growth/GrowthMetricTileView.swift`:

```swift
import SwiftUI

struct GrowthMetricTileView: View {
  var metric: GrowthMetric
  var isSelected: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(metric.provider.displayName)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        if let delta = metric.delta {
          Text(delta.formattedValue)
            .font(.caption.weight(.bold))
            .foregroundStyle(deltaColor(delta.direction))
        }
      }

      Text(metric.formattedValue)
        .font(.title2.weight(.bold))
        .monospacedDigit()

      Text(metric.title)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(isSelected ? PRBarTheme.accent.opacity(0.12) : Color(.secondarySystemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(isSelected ? PRBarTheme.accent : Color.clear, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  private func deltaColor(_ direction: GrowthDelta.Direction) -> Color {
    switch direction {
    case .positive: .green
    case .negative: .orange
    case .neutral: .secondary
    }
  }
}
```

- [ ] **Step 4: Add trend chart view**

Create `apple/PRBar/Growth/GrowthTrendChartView.swift`:

```swift
import SwiftUI

struct GrowthTrendChartView: View {
  var metric: GrowthMetric
  var range: ActivityRange
  var anchorDate: Date

  private var points: [GrowthMetricPoint] {
    metric.normalizedSeries(endingAt: anchorDate, range: range)
  }

  private var maxValue: Double {
    max(points.map(\.value).max() ?? 1, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(metric.title)
        .font(.headline)

      HStack(alignment: .bottom, spacing: 8) {
        ForEach(points) { point in
          VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .fill(metric.provider == .postHog ? PRBarTheme.chartPalette[2] : PRBarTheme.chartPalette[0])
              .frame(height: max(CGFloat(point.value / maxValue) * 120, 4))
              .accessibilityLabel("\(shortDateLabel(point.date)), \(formatted(point.value))")

            Text(dayLabel(point.date))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
      }
      .frame(height: 150, alignment: .bottom)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private func formatted(_ value: Double) -> String {
    value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
  }

  private func dayLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  private func shortDateLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }
}
```

- [ ] **Step 5: Add provider section view**

Create `apple/PRBar/Growth/GrowthProviderSectionView.swift`:

```swift
import SwiftUI

struct GrowthProviderSectionView: View {
  var provider: GrowthProviderKind
  var rows: [GrowthListRow]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(provider.displayName)
        .font(.headline)

      ForEach(rows) { row in
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          VStack(alignment: .leading, spacing: 3) {
            Text(row.title)
              .font(.subheadline.weight(.semibold))
            Text(row.detail)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Text(row.value)
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }
}
```

- [ ] **Step 6: Add setup card view**

Create `apple/PRBar/Growth/GrowthSetupCardView.swift`:

```swift
import SwiftUI

struct GrowthSetupCardView: View {
  var provider: GrowthProviderKind
  var issue: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: provider == .postHog ? "chart.xyaxis.line" : "magnifyingglass")
        .font(.headline)

      Text(detail)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      if let issue {
        Text(issue)
          .font(.caption)
          .foregroundStyle(.orange)
      }

      Button(action: {}) {
        Text(actionTitle)
          .font(.subheadline.weight(.semibold))
      }
      .buttonStyle(.bordered)
      .disabled(true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var title: String {
    "Connect \(provider.displayName)"
  }

  private var detail: String {
    switch provider {
    case .postHog:
      "Track active users, key events, and conversion movement."
    case .searchConsole:
      "Track search clicks, impressions, CTR, and top queries."
    }
  }

  private var actionTitle: String {
    switch provider {
    case .postHog: "Add PostHog"
    case .searchConsole: "Add Search Console"
    }
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add apple/PRBar/Growth/GrowthMetricTileView.swift apple/PRBar/Growth/GrowthTrendChartView.swift apple/PRBar/Growth/GrowthProviderSectionView.swift apple/PRBar/Growth/GrowthSetupCardView.swift apple/PRBarUITests/PRBarUITests.swift
git commit -m "feat: add growth dashboard components"
```

---

### Task 4: Add Growth Tab Screen and Navigation

**Files:**
- Create: `apple/PRBar/Growth/GrowthView.swift`
- Modify: `apple/PRBar/RootTabView.swift`
- Test: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Add range UI test**

Add this to `apple/PRBarUITests/PRBarUITests.swift`:

```swift
func testGrowthRangePickerChangesVisibleChartWindow() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launch()

  app.tapTab("Growth")

  XCTAssertTrue(app.segmentedControls.buttons["Week"].waitForExistence(timeout: 2))
  app.segmentedControls.buttons["Month"].tap()

  XCTAssertTrue(app.staticTexts["Growth"].exists)
  XCTAssertTrue(app.staticTexts["Search Console data can lag by a few days."].exists)
}
```

- [ ] **Step 2: Run UI tests to verify failure**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersFixtureMetrics -only-testing:PRBarUITests/PRBarUITests/testGrowthRangePickerChangesVisibleChartWindow
```

Expected: FAIL because `GrowthView` and tab navigation are not wired.

- [ ] **Step 3: Add Growth screen**

Create `apple/PRBar/Growth/GrowthView.swift`:

```swift
import SwiftUI

struct GrowthView: View {
  @Bindable var store: PRBarStore
  @State private var selectedMetricID: GrowthMetric.ID?

  private var snapshot: GrowthDashboardSnapshot {
    store.growthSnapshot
  }

  private var visibleMetrics: [GrowthMetric] {
    Array(snapshot.visibleMetrics.prefix(4))
  }

  private var selectedMetric: GrowthMetric? {
    if let selectedMetricID,
      let metric = visibleMetrics.first(where: { $0.id == selectedMetricID }) {
      return metric
    }
    return snapshot.defaultMetric
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          header

          RangePickerView(selection: $store.growthRange)
            .onChange(of: store.growthRange) { _, range in
              store.setGrowthRange(range)
              Task { await store.refreshGrowth() }
            }

          if let issue = store.growthRefreshIssue {
            issueView(issue)
          }

          metricTiles

          if let selectedMetric {
            GrowthTrendChartView(metric: selectedMetric, range: store.growthRange, anchorDate: snapshot.anchorDate)
          }

          shippingContext

          providerSections

          setupCards
        }
        .padding()
      }
      .refreshable {
        await store.refreshGrowth()
      }
      .navigationTitle("Growth")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task { await store.refreshGrowth() }
          } label: {
            Label("Refresh growth", systemImage: "arrow.clockwise")
          }
          .disabled(store.isRefreshingGrowth)
        }
      }
      .task {
        if selectedMetricID == nil {
          selectedMetricID = snapshot.defaultMetric?.id
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Growth")
          .font(.largeTitle.weight(.bold))
        Text("Usage and search movement near shipped work")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 8) {
        Label(snapshot.project.name, systemImage: "square.stack.3d.up")
          .font(.subheadline.weight(.semibold))
        Spacer()
        ForEach(snapshot.connections) { connection in
          Text(connection.provider.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(connection.status == .connected ? Color.green.opacity(0.14) : Color.orange.opacity(0.14))
            .clipShape(Capsule())
        }
      }
    }
  }

  private var metricTiles: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      ForEach(visibleMetrics) { metric in
        Button {
          selectedMetricID = metric.id
        } label: {
          GrowthMetricTileView(metric: metric, isSelected: selectedMetric?.id == metric.id)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var shippingContext: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Shipping context")
        .font(.headline)
      Text(snapshot.shippingContext.summary)
        .font(.subheadline)
      if let topRepositoryName = snapshot.shippingContext.topRepositoryName {
        Text("Top included repo: \(topRepositoryName)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  @ViewBuilder
  private var providerSections: some View {
    if snapshot.connection(for: .postHog)?.status == .connected {
      GrowthProviderSectionView(provider: .postHog, rows: snapshot.topEvents)
    }

    if snapshot.connection(for: .searchConsole)?.status == .connected {
      GrowthProviderSectionView(provider: .searchConsole, rows: snapshot.topQueries + snapshot.topPages)

      Text("Search Console data can lag by a few days.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var setupCards: some View {
    ForEach(GrowthProviderKind.allCases) { provider in
      if let connection = snapshot.connection(for: provider),
        connection.status == .notConnected || connection.status == .needsAttention {
        GrowthSetupCardView(provider: provider, issue: connection.issue)
      }
    }
  }

  private func issueView(_ issue: AuthIssue) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(issue.title)
        .font(.headline)
      Text(issue.message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color.orange.opacity(0.14))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

#Preview {
  GrowthView(store: .sample())
}
```

- [ ] **Step 4: Wire Growth tab into navigation**

Modify `apple/PRBar/RootTabView.swift`:

```swift
TabView {
  PRsView(store: store)
    .tabItem { Label("PRs", systemImage: "chart.bar.xaxis") }

  ReleasesView(store: store)
    .tabItem { Label("Releases", systemImage: "tag") }

  GrowthView(store: store)
    .tabItem { Label("Growth", systemImage: "chart.line.uptrend.xyaxis") }

  ShareView(store: store)
    .tabItem { Label("Share", systemImage: "square.and.arrow.up") }

  MoreView(store: store)
    .tabItem { Label("More", systemImage: "ellipsis") }
}
```

- [ ] **Step 5: Run UI tests to verify pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apple/PRBar/Growth/GrowthView.swift apple/PRBar/RootTabView.swift apple/PRBarUITests/PRBarUITests.swift
git commit -m "feat: add iOS growth tab"
```

---

### Task 5: Add Provider State Variants and Privacy Guardrails

**Files:**
- Modify: `apple/PRBarShared/SampleData.swift`
- Modify: `apple/PRBarTests/PRBarModelTests.swift`
- Modify: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Add tests for disconnected provider state and share privacy**

Add to `apple/PRBarTests/PRBarModelTests.swift`:

```swift
func testGrowthMetricsDoNotAppearInWorkCardExport() {
  let export = WorkCardExportBuilder.export(for: PRBarStore.sample(), side: .publicSide)

  XCTAssertFalse(export.caption.localizedCaseInsensitiveContains("active users"))
  XCTAssertFalse(export.caption.localizedCaseInsensitiveContains("search clicks"))
}

func testGrowthDashboardWithoutPostHogShowsSearchConsoleOnly() {
  let snapshot = GrowthDashboardSnapshot.fixture(
    range: .week,
    connections: [
      GrowthConnection(id: "posthog-main", provider: .postHog, displayName: "PostHog", status: .notConnected, lastRefreshedAt: nil, issue: nil),
      GrowthConnection(id: "gsc-main", provider: .searchConsole, displayName: "Search Console", status: .connected, lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"), issue: nil),
    ]
  )

  XCTAssertEqual(Set(snapshot.visibleMetrics.map(\.provider)), [.searchConsole])
}
```

Add to `apple/PRBarUITests/PRBarUITests.swift`:

```swift
func testGrowthShowsProviderSetupCardWhenConnectionNeedsAttention() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing", "--growth-posthog-needs-attention"]
  app.launch()

  app.tapTab("Growth")

  XCTAssertTrue(app.staticTexts["Connect PostHog"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Search clicks"].exists)
}
```

- [ ] **Step 2: Run tests to verify failure where needed**

Run:

```bash
./scripts/ios-generate.sh
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PRBarModelTests/testGrowthMetricsDoNotAppearInWorkCardExport -only-testing:PRBarTests/PRBarModelTests/testGrowthDashboardWithoutPostHogShowsSearchConsoleOnly -only-testing:PRBarUITests/PRBarUITests/testGrowthShowsProviderSetupCardWhenConnectionNeedsAttention
```

Expected: the model tests may pass immediately; the UI test fails until launch fixture wiring exists.

- [ ] **Step 3: Add UI-test fixture launch argument**

Modify `apple/PRBar/PRBarApp.swift` where UI testing fixture stores are created. Add this branch alongside existing UI-test launch argument handling:

```swift
if ProcessInfo.processInfo.arguments.contains("--growth-posthog-needs-attention") {
  var snapshot = GrowthDashboardSnapshot.fixture(
    range: .week,
    connections: [
      GrowthConnection(
        id: "posthog-main",
        provider: .postHog,
        displayName: "PostHog",
        status: .needsAttention,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
        issue: "PostHog API key needs attention"
      ),
      GrowthConnection(
        id: "gsc-main",
        provider: .searchConsole,
        displayName: "Search Console",
        status: .connected,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
        issue: nil
      ),
    ]
  )
  snapshot.issues = [
    GrowthDashboardIssue(
      id: "posthog-needs-attention",
      provider: .postHog,
      title: "PostHog needs attention",
      detail: "PostHog API key needs attention"
    )
  ]
  return PRBarStore.sample(
    growthProvider: StaticGrowthDashboardProvider(snapshot: snapshot)
  )
}
```

If the existing `PRBarApp.swift` fixture factory does not use early returns, adapt the exact snippet into the same helper that currently handles `--ui-testing`, preserving existing launch arguments.

- [ ] **Step 4: Run focused tests**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apple/PRBarShared/SampleData.swift apple/PRBar/PRBarApp.swift apple/PRBarTests/PRBarModelTests.swift apple/PRBarUITests/PRBarUITests.swift
git commit -m "test: cover growth provider states"
```

---

### Task 6: Full Verification and PR

**Files:**
- Verify all changed files.
- No new source files unless tests expose a defect.

- [ ] **Step 1: Regenerate project**

Run:

```bash
./scripts/ios-generate.sh
```

Expected: `apple/PRBar.xcodeproj` includes the new Growth files.

- [ ] **Step 2: Run unit and UI tests**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PRBarModelTests -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersFixtureMetrics -only-testing:PRBarUITests/PRBarUITests/testGrowthRangePickerChangesVisibleChartWindow -only-testing:PRBarUITests/PRBarUITests/testGrowthShowsProviderSetupCardWhenConnectionNeedsAttention
```

Expected: PASS.

- [ ] **Step 3: Try to disprove the change**

Strongest realistic failure mode: adding a fifth bottom tab crowds the existing authenticated navigation or breaks existing PRs/Releases/Share tab smoke.

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarUITests/PRBarUITests/testTabsExposeReviewedPrototypeSurfaces
```

Expected: PASS and the test should be updated, if needed, to assert `Growth` is visible while existing tabs still open.

- [ ] **Step 4: Diff and whitespace audit**

Run:

```bash
git diff --check
git diff --stat
```

Expected: `git diff --check` produces no output. Diff stat should be limited to Growth models/views/store/sample/tests/navigation.

- [ ] **Step 5: Open PR**

Run:

```bash
git push -u origin codex/ios-growth-fixture-tab
gh pr create --repo mean-weasel/prbar --base main --head codex/ios-growth-fixture-tab --title "Add fixture-backed iOS Growth tab" --body "Closes #109 for the first fixture-backed Growth slice. Adds shared Growth models, static provider data, iOS Growth UI, and focused tests. Live PostHog/Search Console auth remains out of scope."
```

Expected: PR opens against `main` and references issue #109.

## Self-Review

- Spec coverage: The plan covers the new iOS Growth tab, fixture-backed PostHog/Search Console dashboard data, shared metric model, connection states, static project/source model, daily summaries over Day/Week/Month, shipping context, loading/error/partial states, navigation, privacy guardrails, and unit/UI/manual verification. It intentionally defers real OAuth/API work to later slices.
- Placeholder scan: No task relies on "TBD" or "add tests later"; each code-changing task includes exact file paths, snippets, commands, and expected outcomes.
- Type consistency: `GrowthDashboardSnapshot`, `GrowthConnection`, `GrowthMetric`, `GrowthDashboardProviding`, and `StaticGrowthDashboardProvider` names match across tests, store, and UI tasks.
