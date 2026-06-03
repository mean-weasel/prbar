# iOS Growth Live Loading and Multi-Day PostHog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the iOS Growth tab clearly load live PostHog data, show cached live data on relaunch, and fetch multi-day daily buckets for the configured Bleep dashboard.

**Architecture:** Keep the existing build-time PostHog configuration path for this iteration, but make it visible and understandable in the app. Add explicit Growth refresh state and a Growth cache to `PRBarStore`, then extend the dashboard-backed PostHog provider to augment sparse dashboard tile responses with daily HogQL series for the selected `day/week/month` range.

**Tech Stack:** SwiftUI, Observation, XCTest, Xcode UI tests, PostHog dashboard API, PostHog HogQL query API, existing GitHub Actions physical iPhone workflows.

---

## Scope

This plan covers the current configured PostHog dashboard only:

- Auto-load Growth when live PostHog configuration exists.
- Make Growth loading/refresh/cached state explicit in the UI.
- Cache successful live Growth snapshots.
- Fetch daily PostHog buckets for `day`, `week`, and `month`.
- Verify on simulator/unit tests and production physical iPhone Growth smoke.

This plan deliberately does not add:

- In-app PostHog API key entry.
- In-app PostHog project/dashboard picker.
- A backend token proxy.
- Search Console live data.

Those are separate follow-up plans once the current configured-dashboard experience feels good.

## File Structure

- Create `apple/PRBarShared/GrowthRefreshStatus.swift`
  - Owns user-visible Growth loading state: idle, loading, loaded, failed.
- Create `apple/PRBarShared/GrowthDashboardCacheStore.swift`
  - Owns persistence of the last successful live Growth snapshot.
- Modify `apple/PRBarShared/PRBarStore.swift`
  - Adds `growthRefreshStatus`, `growthCacheStore`, `restoreGrowthSnapshot()`, `refreshGrowthIfNeeded()`, and cache writes on successful refresh.
- Modify `apple/PRBar/PRBarApp.swift`
  - Injects a file-backed Growth cache for normal app launches and restores cached Growth before the first render.
- Modify `apple/PRBar/Growth/GrowthView.swift`
  - Auto-refreshes Growth on first appearance, labels the refresh affordance as Growth/PostHog-specific, and shows loading/cached/last refreshed state.
- Modify `apple/PRBar/Growth/GrowthTrendChartView.swift`
  - Keeps existing bar chart but exposes clearer accessibility values for daily point counts and empty points.
- Create `apple/PRBarShared/PostHogDashboardDailySeries.swift`
  - Encapsulates daily Bleep dashboard HogQL queries and response decoding.
- Modify `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
  - After dashboard `run_insights`, augments Weekly Visitors and Daily Pageviews with daily series from HogQL when live query data is available.
- Modify `apple/PRBarShared/PostHogGrowthProvider.swift`
  - Reuse existing PostHog request/transport primitives where possible by moving shared query request/response helpers into `PostHogDashboardDailySeries.swift`.
- Modify `apple/PRBarTests/PRBarModelTests.swift`
  - Adds store/cache/status tests.
- Modify `apple/PRBarTests/PostHogGrowthProviderTests.swift`
  - Adds dashboard sparse-response plus daily-series augmentation tests.
- Modify `apple/PRBarUITests/PRBarUITests.swift`
  - Adds/updates Growth UI tests for auto-load, explicit status, and multi-day chart point counts.
- Modify `.github/workflows/ios-physical-production.yml` only if needed
  - Keep `smoke_profile=growth` as the focused production Growth check; do not fold stale broader production tests into this PR.
- Modify `Docs/ios-posthog-dashboard-config.md`
  - Documents current UX and the fact that dashboard selection is still build/config driven.

---

### Task 1: Add Growth Refresh Status Model

**Files:**
- Create: `apple/PRBarShared/GrowthRefreshStatus.swift`
- Modify: `apple/PRBarShared/PRBarStore.swift`
- Test: `apple/PRBarTests/PRBarModelTests.swift`

- [ ] **Step 1: Write failing unit tests for Growth refresh status**

Add these tests near the existing Growth tests in `apple/PRBarTests/PRBarModelTests.swift`:

```swift
@MainActor
func testGrowthRefreshStatusMovesFromLoadingToLoaded() async {
  let now = SampleData.dateTime("2026-05-24T18:45:00Z")
  let provider = StaticGrowthDashboardProvider(snapshot: .fixture(range: .week))
  let store = PRBarStore.sample(growthProvider: provider, currentDate: { now })

  XCTAssertEqual(store.growthRefreshStatus, .idle)

  await store.refreshGrowth()

  XCTAssertEqual(store.growthRefreshStatus, .loaded(lastRefreshedAt: now, source: .livePostHog))
  XCTAssertFalse(store.isRefreshingGrowth)
}

@MainActor
func testGrowthRefreshStatusReportsFailureWithoutClearingCurrentSnapshot() async {
  let original = GrowthDashboardSnapshot.fixture(range: .week)
  let store = PRBarStore.sample(
    growthSnapshot: original,
    growthProvider: FailingGrowthDashboardProvider(error: .providerUnavailable("PostHog is unavailable"))
  )

  await store.refreshGrowth()

  XCTAssertEqual(store.growthSnapshot, original)
  XCTAssertEqual(store.growthRefreshStatus, .failed(message: "PostHog is unavailable"))
  XCTAssertEqual(store.growthRefreshIssue?.title, "Growth refresh failed")
}
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
./scripts/ios-test.sh
```

Expected: fails because `growthRefreshStatus` and `GrowthRefreshStatus` do not exist.

- [ ] **Step 3: Add `GrowthRefreshStatus`**

Create `apple/PRBarShared/GrowthRefreshStatus.swift`:

```swift
import Foundation

enum GrowthRefreshStatus: Equatable, Sendable {
  case idle
  case loading(message: String)
  case loaded(lastRefreshedAt: Date, source: GrowthDataSource)
  case failed(message: String)

  var isLoading: Bool {
    if case .loading = self {
      return true
    }
    return false
  }

  var displayMessage: String? {
    switch self {
    case .idle:
      return nil
    case let .loading(message):
      return message
    case let .loaded(lastRefreshedAt, source):
      return "\(source.displayName) refreshed \(Self.relativeFormatter.localizedString(for: lastRefreshedAt, relativeTo: Date()))"
    case let .failed(message):
      return message
    }
  }

  private static let relativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter
  }()
}
```

- [ ] **Step 4: Wire status into `PRBarStore.refreshGrowth()`**

In `apple/PRBarShared/PRBarStore.swift`, add:

```swift
var growthRefreshStatus: GrowthRefreshStatus = .idle
```

Update `refreshGrowth()`:

```swift
@MainActor
func refreshGrowth() async {
  guard isRefreshingGrowth == false else {
    return
  }

  isRefreshingGrowth = true
  growthRefreshStatus = .loading(message: "Refreshing PostHog...")
  growthRefreshIssue = nil
  defer { isRefreshingGrowth = false }

  do {
    let snapshot = try await growthProvider.dashboard(
      projectID: selectedGrowthProjectID,
      range: growthRange,
      anchorDate: growthSnapshot.anchorDate
    )
    growthSnapshot = snapshot
    growthRefreshStatus = .loaded(lastRefreshedAt: currentDate(), source: snapshot.dataSource)
  } catch {
    let message = error.localizedDescription
    growthRefreshStatus = .failed(message: message)
    growthRefreshIssue = AuthIssue(
      id: "growth-refresh-failed",
      title: "Growth refresh failed",
      message: message
    )
  }
}
```

Use the existing `currentDate` closure already present in `PRBarStore.sample(currentDate:)`; if `PRBarStore` does not store it for Growth, add `private let currentDate: @Sendable () -> Date` and initialize it from the existing initializer parameter.

- [ ] **Step 5: Run tests**

Run:

```bash
./scripts/ios-test.sh
```

Expected: Growth status tests pass.

- [ ] **Step 6: Commit**

```bash
git add apple/PRBarShared/GrowthRefreshStatus.swift apple/PRBarShared/PRBarStore.swift apple/PRBarTests/PRBarModelTests.swift
git commit -m "feat: track growth refresh status"
```

---

### Task 2: Cache Successful Live Growth Snapshots

**Files:**
- Create: `apple/PRBarShared/GrowthDashboardCacheStore.swift`
- Modify: `apple/PRBarShared/PRBarStore.swift`
- Modify: `apple/PRBar/PRBarApp.swift`
- Test: `apple/PRBarTests/PRBarModelTests.swift`

- [ ] **Step 1: Write failing cache tests**

Add tests to `apple/PRBarTests/PRBarModelTests.swift`:

```swift
@MainActor
func testGrowthRefreshPersistsSuccessfulSnapshotToCache() async throws {
  let cache = InMemoryGrowthDashboardCacheStore()
  let snapshot = GrowthDashboardSnapshot.fixture(range: .week).withDataSource(.livePostHog)
  let store = PRBarStore.sample(growthProvider: StaticGrowthDashboardProvider(snapshot: snapshot), growthCacheStore: cache)

  await store.refreshGrowth()

  let cached = try cache.load()
  XCTAssertEqual(cached?.snapshot.dataSource, .livePostHog)
  XCTAssertEqual(cached?.snapshot.project.name, snapshot.project.name)
}

@MainActor
func testRestoreGrowthSnapshotUsesCachedLiveDataBeforeRefresh() throws {
  let cache = InMemoryGrowthDashboardCacheStore()
  let live = GrowthDashboardSnapshot.fixture(range: .week).withDataSource(.livePostHog)
  try cache.save(GrowthDashboardCacheRecord(snapshot: live, savedAt: SampleData.dateTime("2026-05-24T18:45:00Z")))
  let store = PRBarStore.sample(growthCacheStore: cache)

  store.restoreGrowthSnapshot()

  XCTAssertEqual(store.growthSnapshot.dataSource, .livePostHog)
  XCTAssertEqual(store.growthRefreshStatus, .loaded(lastRefreshedAt: SampleData.dateTime("2026-05-24T18:45:00Z"), source: .livePostHog))
}
```

Add a test helper extension in the same test file:

```swift
private extension GrowthDashboardSnapshot {
  func withDataSource(_ dataSource: GrowthDataSource) -> GrowthDashboardSnapshot {
    var copy = self
    copy.dataSource = dataSource
    return copy
  }
}
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
./scripts/ios-test.sh
```

Expected: fails because the cache store and `growthCacheStore` injection do not exist.

- [ ] **Step 3: Add Growth cache store**

Create `apple/PRBarShared/GrowthDashboardCacheStore.swift`:

```swift
import Foundation

struct GrowthDashboardCacheRecord: Codable, Equatable, Sendable {
  var snapshot: GrowthDashboardSnapshot
  var savedAt: Date
}

protocol GrowthDashboardCacheStoring: Sendable {
  func load() throws -> GrowthDashboardCacheRecord?
  func save(_ record: GrowthDashboardCacheRecord) throws
  func clear() throws
}

final class InMemoryGrowthDashboardCacheStore: GrowthDashboardCacheStoring, @unchecked Sendable {
  private var record: GrowthDashboardCacheRecord?

  func load() throws -> GrowthDashboardCacheRecord? {
    record
  }

  func save(_ record: GrowthDashboardCacheRecord) throws {
    self.record = record
  }

  func clear() throws {
    record = nil
  }
}

struct FileGrowthDashboardCacheStore: GrowthDashboardCacheStoring {
  var fileURL: URL

  init(fileURL: URL = Self.defaultFileURL) {
    self.fileURL = fileURL
  }

  func load() throws -> GrowthDashboardCacheRecord? {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return nil
    }
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(GrowthDashboardCacheRecord.self, from: data)
  }

  func save(_ record: GrowthDashboardCacheRecord) throws {
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(record)
    try data.write(to: fileURL, options: [.atomic])
  }

  func clear() throws {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: fileURL)
  }

  private static var defaultFileURL: URL {
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("PRBar", isDirectory: true)
    return directory.appendingPathComponent("growth-dashboard-cache.json")
  }
}
```

- [ ] **Step 4: Inject cache store into `PRBarStore`**

Modify the `PRBarStore` initializer and `.sample(...)` factory to accept:

```swift
growthCacheStore: GrowthDashboardCacheStoring = InMemoryGrowthDashboardCacheStore()
```

Store it as:

```swift
private let growthCacheStore: GrowthDashboardCacheStoring
```

- [ ] **Step 5: Restore and save cache in store**

Add to `PRBarStore`:

```swift
@MainActor
func restoreGrowthSnapshot() {
  guard let record = try? growthCacheStore.load() else {
    return
  }
  growthSnapshot = record.snapshot
  growthRefreshStatus = .loaded(lastRefreshedAt: record.savedAt, source: record.snapshot.dataSource)
}
```

In successful `refreshGrowth()`, after assigning `growthSnapshot`, add:

```swift
let refreshedAt = currentDate()
try? growthCacheStore.save(GrowthDashboardCacheRecord(snapshot: snapshot, savedAt: refreshedAt))
growthRefreshStatus = .loaded(lastRefreshedAt: refreshedAt, source: snapshot.dataSource)
```

- [ ] **Step 6: Restore cached Growth on normal app launch**

In `apple/PRBar/PRBarApp.swift`, normal app path should create:

```swift
let growthCacheStore = FileGrowthDashboardCacheStore()
```

Pass it into `PRBarStore.sample(...)`:

```swift
growthCacheStore: growthCacheStore
```

After `store.restoreGitHubSession()` in the non-UI-testing normal launch path, call:

```swift
store.restoreGrowthSnapshot()
```

Keep UI tests on `InMemoryGrowthDashboardCacheStore()` unless a test explicitly asks for persistent state.

- [ ] **Step 7: Run tests**

Run:

```bash
./scripts/ios-test.sh
```

Expected: cache tests pass; existing store tests pass.

- [ ] **Step 8: Commit**

```bash
git add apple/PRBarShared/GrowthDashboardCacheStore.swift apple/PRBarShared/PRBarStore.swift apple/PRBar/PRBarApp.swift apple/PRBarTests/PRBarModelTests.swift
git commit -m "feat: cache live growth snapshots"
```

---

### Task 3: Make Growth Loading and Refresh UX Explicit

**Files:**
- Modify: `apple/PRBar/Growth/GrowthView.swift`
- Modify: `apple/PRBar/Growth/GrowthTrendChartView.swift`
- Modify: `apple/PRBarShared/PRBarStore.swift`
- Test: `apple/PRBarUITests/PRBarUITests.swift`

- [ ] **Step 1: Write failing UI tests**

Add to `apple/PRBarUITests/PRBarUITests.swift`:

```swift
@MainActor
func testGrowthShowsExplicitPostHogRefreshState() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing", "--ui-testing-bleep-posthog-dashboard"]
  app.launch()

  app.tapTab("Growth")

  XCTAssertTrue(app.buttons["Refresh PostHog growth"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Bleep Blog KPI Dashboard"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Live PostHog"].exists)
  XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Last refreshed")).firstMatch.exists)
}
```

- [ ] **Step 2: Run the failing UI test on simulator**

Run:

```bash
xcodegen generate --spec apple/project.yml
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PRBarUITests/PRBarUITests/testGrowthShowsExplicitPostHogRefreshState
```

Expected: fails because the button label/status text do not match yet.

- [ ] **Step 3: Add `refreshGrowthIfNeeded()`**

In `apple/PRBarShared/PRBarStore.swift`, add:

```swift
@MainActor
func refreshGrowthIfNeeded() async {
  guard isRefreshingGrowth == false else {
    return
  }
  guard growthSnapshot.dataSource != .livePostHog || growthRefreshStatus == .idle else {
    return
  }
  await refreshGrowth()
}
```

If this produces unwanted refreshes in fixture UI tests, gate it with a stored boolean:

```swift
private var hasAttemptedAutomaticGrowthRefresh = false
```

and update the method:

```swift
@MainActor
func refreshGrowthIfNeeded() async {
  guard hasAttemptedAutomaticGrowthRefresh == false else {
    return
  }
  hasAttemptedAutomaticGrowthRefresh = true
  await refreshGrowth()
}
```

- [ ] **Step 4: Update Growth toolbar and status copy**

In `apple/PRBar/Growth/GrowthView.swift`, change the toolbar label:

```swift
Label("Refresh PostHog growth", systemImage: "arrow.clockwise")
```

Add an automatic refresh task to the `ScrollView` or `NavigationStack`:

```swift
.task {
  selectedMetricID = selectedMetricID ?? snapshot.defaultMetric?.id
  await store.refreshGrowthIfNeeded()
}
```

Add a status view below `RangePickerView`:

```swift
growthStatusView
```

Implement:

```swift
@ViewBuilder
private var growthStatusView: some View {
  switch store.growthRefreshStatus {
  case .idle:
    EmptyView()
  case let .loading(message):
    HStack(spacing: 8) {
      ProgressView()
      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  case let .loaded(lastRefreshedAt, source):
    Label("Last refreshed \(formattedRefreshDate(lastRefreshedAt)) from \(source.displayName)", systemImage: "checkmark.circle")
      .font(.caption)
      .foregroundStyle(.secondary)
  case let .failed(message):
    Label(message, systemImage: "exclamationmark.triangle")
      .font(.caption)
      .foregroundStyle(.orange)
  }
}

private func formattedRefreshDate(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateStyle = .none
  formatter.timeStyle = .short
  return formatter.string(from: date)
}
```

- [ ] **Step 5: Make chart point count visible to UI tests**

In `apple/PRBar/Growth/GrowthTrendChartView.swift`, keep:

```swift
.accessibilityValue("\(points.count) points")
```

Add a visible caption below the chart:

```swift
Text("\(points.count) daily points")
  .font(.caption)
  .foregroundStyle(.secondary)
```

Acceptance: this is visible enough to answer the user’s “why only one day?” question in the current app and gives tests a stable assertion.

- [ ] **Step 6: Run UI and unit tests**

Run:

```bash
./scripts/ios-test.sh
xcodegen generate --spec apple/project.yml
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PRBarUITests/PRBarUITests/testGrowthShowsExplicitPostHogRefreshState
```

Expected: both pass.

- [ ] **Step 7: Commit**

```bash
git add apple/PRBar/Growth/GrowthView.swift apple/PRBar/Growth/GrowthTrendChartView.swift apple/PRBarShared/PRBarStore.swift apple/PRBarUITests/PRBarUITests.swift
git commit -m "feat: clarify growth refresh ux"
```

---

### Task 4: Add Multi-Day PostHog Daily Series Queries

**Files:**
- Create: `apple/PRBarShared/PostHogDashboardDailySeries.swift`
- Modify: `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
- Modify: `apple/PRBarShared/PostHogGrowthProvider.swift`
- Test: `apple/PRBarTests/PostHogGrowthProviderTests.swift`

- [ ] **Step 1: Write failing provider test for sparse dashboard tile augmentation**

Add to `apple/PRBarTests/PostHogGrowthProviderTests.swift`:

```swift
func testDashboardProviderAugmentsSparseDashboardTilesWithDailyPostHogSeries() async throws {
  let transport = FixturePostHogQueryTransport(responses: [
    PostHogFixtures.dashboardMetadata,
    PostHogFixtures.dashboardRunInsightsWithSingleDayMetrics,
    PostHogFixtures.bleepDailySeriesRows,
  ])
  let provider = PostHogDashboardGrowthProvider(configuration: .fixture, transport: transport)
  let snapshot = try await provider.dashboard(
    projectID: "bleep-that-sht",
    range: .week,
    anchorDate: SampleData.date("2026-05-24")
  )

  let visitors = try XCTUnwrap(snapshot.metrics.first { $0.title == "Weekly visitors" })
  let pageviews = try XCTUnwrap(snapshot.metrics.first { $0.title == "Daily pageviews" })

  XCTAssertEqual(snapshot.dataSource, .livePostHog)
  XCTAssertEqual(visitors.normalizedSeries(endingAt: snapshot.anchorDate, range: .week).count, 7)
  XCTAssertEqual(pageviews.normalizedSeries(endingAt: snapshot.anchorDate, range: .week).count, 7)
  XCTAssertEqual(visitors.series.map(\.value), [2, 3, 4, 5, 6, 7, 8])
  XCTAssertEqual(pageviews.series.map(\.value), [10, 12, 14, 16, 18, 20, 22])
}
```

Add fixtures in the same file:

```swift
private enum PostHogFixtures {
  static let dashboardMetadata = Data(#"{"id":1362888,"name":"Bleep Blog KPI Dashboard"}"#.utf8)

  static let dashboardRunInsightsWithSingleDayMetrics = Data("""
  {
    "results": [
      {
        "id": 1,
        "order": 1,
        "insight": {
          "name": "Weekly Visitors",
          "result": [{"days": ["2026-05-24"], "data": [8], "count": 8}]
        }
      },
      {
        "id": 2,
        "order": 2,
        "insight": {
          "name": "Daily Pageviews",
          "result": [{"days": ["2026-05-24"], "data": [22], "count": 22}]
        }
      }
    ]
  }
  """.utf8)

  static let bleepDailySeriesRows = Data("""
  {
    "results": [
      ["2026-05-18", 2, 10],
      ["2026-05-19", 3, 12],
      ["2026-05-20", 4, 14],
      ["2026-05-21", 5, 16],
      ["2026-05-22", 6, 18],
      ["2026-05-23", 7, 20],
      ["2026-05-24", 8, 22]
    ]
  }
  """.utf8)
}
```

- [ ] **Step 2: Run the failing provider test**

Run:

```bash
./scripts/ios-test.sh
```

Expected: fails because the dashboard provider only consumes `run_insights`.

- [ ] **Step 3: Create daily series query helper**

Create `apple/PRBarShared/PostHogDashboardDailySeries.swift`:

```swift
import Foundation

struct PostHogDashboardDailySeries: Equatable, Sendable {
  var day: Date
  var visitors: Double
  var pageviews: Double
}

enum PostHogDashboardDailySeriesQuery {
  static func request(configuration: PostHogConfiguration, range: ActivityRange, anchorDate: Date) throws -> URLRequest {
    try PostHogQueryRequest.query(
      configuration: configuration,
      sql: sql(range: range, anchorDate: anchorDate)
    )
  }

  static func decode(_ data: Data) throws -> [PostHogDashboardDailySeries] {
    try PostHogQueryResponse(data: data).dashboardDailySeriesRows()
  }

  private static func sql(range: ActivityRange, anchorDate: Date) -> String {
    let interval = PostHogDateInterval.range(range: range, anchorDate: anchorDate)
    return """
    SELECT
      toDate(timestamp) AS day,
      uniq(person_id) AS visitors,
      countIf(event = '$pageview') AS pageviews
    FROM events
    WHERE event = '$pageview'
      AND timestamp >= toDateTime('\(interval.start)')
      AND timestamp < toDateTime('\(interval.end)')
    GROUP BY day
    ORDER BY day ASC
    """
  }
}

enum PostHogDateInterval {
  static func range(range: ActivityRange, anchorDate: Date) -> (start: String, end: String) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: anchorDate))!
    let start: Date
    switch range {
    case .day:
      start = calendar.startOfDay(for: anchorDate)
    case .week:
      start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: anchorDate))!
    case .month:
      let components = calendar.dateComponents([.year, .month], from: anchorDate)
      start = calendar.date(from: components)!
    }
    return (formatter.string(from: start), formatter.string(from: end))
  }

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()
}
```

- [ ] **Step 4: Make existing query helpers reusable**

In `apple/PRBarShared/PostHogGrowthProvider.swift`, change these private types to internal file/module-visible by removing `private`:

```swift
struct PostHogQueryBody: Encodable { ... }
struct PostHogHogQLQuery: Encodable { ... }
struct PostHogQueryResponse { ... }
struct PostHogQueryPayload: Decodable { ... }
enum PostHogJSONValue: Decodable { ... }
```

Add to `PostHogQueryResponse`:

```swift
func dashboardDailySeriesRows() throws -> [PostHogDashboardDailySeries] {
  try rows.map { row in
    guard row.count >= 3,
      let dayString = row[0].stringValue,
      let date = Self.dayFormatter.date(from: dayString),
      let visitors = row[1].doubleValue,
      let pageviews = row[2].doubleValue
    else {
      throw PostHogAPIError.invalidResponse
    }
    return PostHogDashboardDailySeries(day: date, visitors: visitors, pageviews: pageviews)
  }
}

private static let dayFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter
}()
```

If `PostHogJSONValue` does not expose `stringValue` and `doubleValue`, add:

```swift
var stringValue: String? {
  if case let .string(value) = self {
    return value
  }
  return nil
}

var doubleValue: Double? {
  switch self {
  case let .number(value):
    return value
  case let .string(value):
    return Double(value)
  case .null:
    return nil
  }
}
```

- [ ] **Step 5: Augment dashboard provider with daily series**

In `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`, after decoding `run_insights`, request daily series:

```swift
let dailySeriesRequest = try PostHogDashboardDailySeriesQuery.request(
  configuration: configuration,
  range: range,
  anchorDate: anchorDate
)
let dailySeriesData = try await transport.data(for: dailySeriesRequest)
let dailySeries = try PostHogDashboardDailySeriesQuery.decode(dailySeriesData)
return BleepBlogDashboardNormalizer.snapshot(
  response: response,
  range: range,
  anchorDate: anchorDate,
  dailySeries: dailySeries
)
```

Update the normalizer signature:

```swift
static func snapshot(
  response: PostHogDashboardRunResponse,
  range: ActivityRange,
  anchorDate: Date,
  dailySeries: [PostHogDashboardDailySeries] = []
) -> GrowthDashboardSnapshot
```

When building `Weekly Visitors`, prefer `dailySeries` if non-empty:

```swift
metrics.append(
  metric(
    id: "posthog-weekly-visitors",
    kind: .weeklyVisitors,
    title: "Weekly visitors",
    value: dailySeries.reduce(0) { $0 + $1.visitors },
    series: dailySeries.map { GrowthMetricPoint(date: $0.day, value: $0.visitors) },
    fallbackSeries: series
  )
)
```

When building `Daily Pageviews`, prefer:

```swift
metrics.append(
  metric(
    id: "posthog-page-views",
    kind: .pageViews,
    title: "Daily pageviews",
    value: dailySeries.reduce(0) { $0 + $1.pageviews },
    series: dailySeries.map { GrowthMetricPoint(date: $0.day, value: $0.pageviews) },
    fallbackSeries: series
  )
)
```

Replace the existing `metric(id:kind:title:series:)` helper with:

```swift
private static func metric(
  id: String,
  kind: GrowthMetricKind,
  title: String,
  value: Double,
  series: [GrowthMetricPoint],
  fallbackSeries: PostHogDashboardSeries
) -> GrowthMetric {
  let finalSeries = series.isEmpty ? metricPoints(from: fallbackSeries) : series
  let finalValue = series.isEmpty ? count(from: fallbackSeries) : value
  return GrowthMetric(
    id: id,
    provider: .postHog,
    kind: kind,
    title: title,
    value: finalValue,
    formattedValue: formattedCount(finalValue),
    unit: .count,
    delta: nil,
    series: finalSeries
  )
}
```

- [ ] **Step 6: Run provider tests**

Run:

```bash
./scripts/ios-test.sh
```

Expected: new augmentation test passes; existing tolerant decoder tests pass.

- [ ] **Step 7: Commit**

```bash
git add apple/PRBarShared/PostHogDashboardDailySeries.swift apple/PRBarShared/PostHogDashboardGrowthProvider.swift apple/PRBarShared/PostHogGrowthProvider.swift apple/PRBarTests/PostHogGrowthProviderTests.swift
git commit -m "feat: fetch daily posthog growth series"
```

---

### Task 5: Verify Multi-Day Growth in UI and Physical Device Smoke

**Files:**
- Modify: `apple/PRBarUITests/PRBarUITests.swift`
- Modify: `Docs/ios-posthog-dashboard-config.md`

- [ ] **Step 1: Update live Growth smoke assertions**

In `apple/PRBarUITests/PRBarUITests.swift`, extend `testLivePostHogGrowthMetricsRender()` after the existing metric assertions:

```swift
let chart = app.otherElements["growth-trend-chart"]
XCTAssertTrue(chart.waitForExistence(timeout: 4))
XCTAssertTrue(
  chart.value as? String == "7 points" ||
    chart.value as? String == "31 points" ||
    app.staticTexts["7 daily points"].exists ||
    app.staticTexts["31 daily points"].exists,
  "Growth chart did not expose a multi-day PostHog series."
)
```

- [ ] **Step 2: Add simulator fixture UI test for multi-day chart labels**

Add:

```swift
@MainActor
func testGrowthFixtureShowsMultiDayPointCount() {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing", "--ui-testing-bleep-posthog-dashboard"]
  app.launch()

  app.tapTab("Growth")

  XCTAssertTrue(app.otherElements["growth-trend-chart"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "daily points")).firstMatch.exists)
}
```

- [ ] **Step 3: Run simulator UI test**

Run:

```bash
xcodegen generate --spec apple/project.yml
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PRBarUITests/PRBarUITests/testGrowthFixtureShowsMultiDayPointCount
```

Expected: passes.

- [ ] **Step 4: Update docs**

In `Docs/ios-posthog-dashboard-config.md`, add a section:

```markdown
## Current iOS Growth UX

The Growth tab uses the PostHog dashboard configuration embedded in the iOS app build:

- `PRBAR_IOS_POSTHOG_HOST`
- `PRBAR_IOS_POSTHOG_PROJECT_ID`
- `PRBAR_IOS_POSTHOG_PERSONAL_API_KEY`
- `PRBAR_IOS_POSTHOG_DASHBOARD_ID`

On app launch, Growth restores the last successful live snapshot when one exists. Opening the Growth tab starts a live refresh. The toolbar refresh button is labeled `Refresh PostHog growth`; pull-to-refresh performs the same action.

The configured Bleep dashboard currently maps:

- `Weekly Visitors` to daily unique visitors from `$pageview`
- `Daily Pageviews` to daily `$pageview` counts
- `Traffic Sources` to dashboard-provided source rows
- `Top Pages` to dashboard-provided page rows

Dashboard selection is not yet editable in-app.
```

- [ ] **Step 5: Run all local iOS tests**

Run:

```bash
./scripts/ios-test.sh
```

Expected: passes.

- [ ] **Step 6: Run production Growth smoke after PR branch is pushed**

After the branch is pushed and CI passes, dispatch:

```bash
gh workflow run ios-physical-production.yml --repo mean-weasel/prbar --ref <branch-name> -f device_name=iPhone-prod -f smoke_profile=growth -f live_repository=mean-weasel/prbar
```

Expected:

- Runner preflight passes.
- PostHog dashboard metadata preflight passes with HTTP 200.
- PostHog dashboard `run_insights` preflight passes with HTTP 200.
- `testLivePostHogGrowthMetricsRender()` passes.
- Logs show `Bleep Blog KPI Dashboard`, `Live PostHog`, `Weekly visitors`, and `Daily pageviews`.

- [ ] **Step 7: Commit**

```bash
git add apple/PRBarUITests/PRBarUITests.swift Docs/ios-posthog-dashboard-config.md
git commit -m "test: verify live growth multiday rendering"
```

---

## Acceptance Criteria

- Opening Growth does not require the user to guess that the generic refresh button loads PostHog data.
- Growth automatically attempts one live refresh when the tab opens and live PostHog config exists.
- Growth shows a clear loading row while refreshing.
- Growth shows `Last refreshed ... from Live PostHog` after a successful refresh.
- Growth restores cached live data on app relaunch before the next network refresh.
- Week view shows 7 daily points for PostHog visitor/pageview metrics.
- Month view shows daily points for the current month through the anchor date.
- A sparse dashboard tile response with only one day no longer limits the Growth chart to one live point when HogQL daily series succeeds.
- If HogQL daily series fails but dashboard `run_insights` succeeds, the app still displays dashboard tile data and surfaces a Growth issue rather than blanking the screen.
- Production physical iPhone `smoke_profile=growth` passes.

## Manual Verification Checklist

Run on `iPhone-prod` after install:

1. Open PRBar.
2. Tap `Growth`.
3. Confirm a loading row appears, or cached `Live PostHog` data is visible immediately.
4. Confirm the header says `Bleep Blog KPI Dashboard`.
5. Confirm the data source badge says `Live PostHog`.
6. Confirm the refresh affordance is discoverable as Growth/PostHog-specific.
7. Tap/pull refresh and confirm `Last refreshed` updates.
8. Select `Week`; confirm the chart reports 7 daily points.
9. Select `Month`; confirm the chart reports month daily points.
10. Quit and reopen the app; confirm cached live Growth data appears before refresh completes.

## Self-Review

**Spec coverage:** The plan covers the confusing refresh UX, the hidden load action, caching so production launches do not fall back to sample data, and the one-day data problem through daily HogQL augmentation.

**Placeholder scan:** The plan avoids placeholder steps. Each code-changing task includes concrete files, snippets, commands, and expected outcomes.

**Type consistency:** New types are consistently named `GrowthRefreshStatus`, `GrowthDashboardCacheRecord`, `GrowthDashboardCacheStoring`, `PostHogDashboardDailySeries`, and `PostHogDashboardDailySeriesQuery`.

## Execution Options

Plan complete and saved to `docs/superpowers/plans/2026-06-02-ios-growth-live-loading-and-multiday-posthog.md`.

1. **Subagent-Driven (recommended)** - Dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - Execute tasks in this session using executing-plans, with checkpoints after each task.
