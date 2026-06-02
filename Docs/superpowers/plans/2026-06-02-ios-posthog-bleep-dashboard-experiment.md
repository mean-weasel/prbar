# iOS PostHog Bleep Dashboard Experiment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reproduce the `bleep-that-sht` PostHog `Bleep Blog KPI Dashboard` inside the iOS Growth tab as a narrow live-data experiment.

**Architecture:** Add a dashboard-specific PostHog provider that fetches the selected dashboard metadata and dashboard insight results, then normalizes only the supported tile shapes into the existing `GrowthDashboardSnapshot`. The experiment is intentionally scoped to one dashboard ID, no dashboard picker, no backend proxy, and no arbitrary PostHog chart rendering.

**Tech Stack:** Swift 6, SwiftUI, XCTest, PostHog Dashboards API, current `GrowthDashboardProviding` protocol.

---

## Experiment Scope

Use exactly this PostHog source:

- Project/environment ID: `324426`
- Project name: `bleep-that-sht`
- Dashboard ID: `1362888`
- Dashboard name: `Bleep Blog KPI Dashboard`
- Dashboard URL: `/dashboard/1362888`

Support these dashboard tiles:

- `Weekly Visitors`: trend tile with one result row, mapped to a `GrowthMetric` time series.
- `Daily Pageviews`: trend tile with one result row, mapped to a `GrowthMetric` time series.
- `Top Pages`: breakdown trend tile, mapped to `GrowthListRow` rows by `breakdown_value` and `count`.
- `Traffic Sources`: breakdown trend tile, mapped to `GrowthListRow` rows by `breakdown_value` and `count`.

Mark these dashboard tiles unsupported in `GrowthDashboardIssue`:

- `Blog -> Upload Activation`
- `Blog -> Studio Download Activation`
- `Blog -> Studio Start Activation`
- `Blog -> Signup Activation`

Do not build:

- A dashboard selector.
- A project selector.
- Google Search Console.
- A production backend/proxy.
- Funnel visualization UI.
- A generic renderer for all PostHog insight types.

## Files

- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/PostHogGrowthProvider.swift`
  - Add dashboard ID parsing to `PostHogConfiguration`.
  - Add dashboard request builders.
  - Keep the existing HogQL provider path intact.
- Create: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
  - Add decodable dashboard/run-insights response models.
  - Add normalization from the four supported dashboard tiles to current Growth models.
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/GrowthModels.swift`
  - Add `pageViews` and `weeklyVisitors` metric kinds, or use existing kinds only if the UI copy can remain accurate.
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBar/PRBarApp.swift`
  - Select the new provider only when `PRBAR_IOS_POSTHOG_DASHBOARD_ID` is configured.
- Modify: `/Users/neonwatty/Desktop/prbar/apple/project.yml`
  - Pass `PRBAR_IOS_POSTHOG_DASHBOARD_ID` into unit/UI test scheme environments.
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarTests/PostHogGrowthProviderTests.swift`
  - Add request-building and dashboard-provider tests.
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarUITests/PRBarUITests.swift`
  - Add one focused UI test that verifies the Bleep dashboard appears when fixture dashboard data is injected.

## API Calls

The experiment provider must use these endpoints:

```text
GET /api/environments/324426/dashboards/1362888/
Authorization: Bearer <personal API key>
```

Purpose: fetch dashboard name, tile order, insight names, and query metadata.

```text
GET /api/environments/324426/dashboards/1362888/run_insights/?output_format=json&refresh=blocking
Authorization: Bearer <personal API key>
```

Purpose: fetch raw result arrays for all dashboard insights.

For local tests, use fixture JSON from `dashboard-insights-run` with this shape:

```json
{
  "results": [
    {
      "id": 6536095,
      "insight": {
        "id": 7359527,
        "name": "Daily Pageviews",
        "result": [
          {
            "data": [139, 179, 1036],
            "days": ["2026-04-27", "2026-04-28", "2026-04-29"],
            "count": 1314,
            "label": "$pageview"
          }
        ]
      },
      "order": 1
    }
  ]
}
```

For breakdown tiles, use this shape:

```json
{
  "id": 6536096,
  "insight": {
    "id": 7359528,
    "name": "Top Pages",
    "result": [
      {
        "data": [1087, 879],
        "days": ["2026-04-26", "2026-05-03"],
        "count": 1966,
        "label": "/studio",
        "breakdown_value": "/studio"
      }
    ]
  },
  "order": 2
}
```

---

### Task 1: Add Dashboard Configuration And Request Builders

**Files:**
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/PostHogGrowthProvider.swift`
- Test: `/Users/neonwatty/Desktop/prbar/apple/PRBarTests/PostHogGrowthProviderTests.swift`

- [ ] **Step 1: Write failing configuration/request tests**

Add these tests to `PostHogGrowthProviderTests`:

```swift
func testPostHogConfigurationReadsDashboardIDFromEnvironment() {
  let configuration = PostHogConfiguration.live(
    environment: [
      "PRBAR_IOS_POSTHOG_PROJECT_ID": "324426",
      "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
      "PRBAR_IOS_POSTHOG_DASHBOARD_ID": "1362888",
    ]
  )

  XCTAssertEqual(configuration?.projectID, "324426")
  XCTAssertEqual(configuration?.dashboardID, 1362888)
}

func testPostHogConfigurationIgnoresInvalidDashboardID() {
  let configuration = PostHogConfiguration.live(
    environment: [
      "PRBAR_IOS_POSTHOG_PROJECT_ID": "324426",
      "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
      "PRBAR_IOS_POSTHOG_DASHBOARD_ID": "not-a-number",
    ]
  )

  XCTAssertNil(configuration?.dashboardID)
}

func testPostHogDashboardRequestsUseEnvironmentDashboardEndpoints() throws {
  let configuration = PostHogConfiguration(
    host: URL(string: "https://us.posthog.com")!,
    projectID: "324426",
    personalAPIKey: "phx_test",
    dashboardID: 1362888
  )

  let dashboardRequest = try PostHogDashboardRequest.dashboard(configuration: configuration)
  XCTAssertEqual(dashboardRequest.url?.absoluteString, "https://us.posthog.com/api/environments/324426/dashboards/1362888/")
  XCTAssertEqual(dashboardRequest.httpMethod, "GET")
  XCTAssertEqual(dashboardRequest.value(forHTTPHeaderField: "Authorization"), "Bearer phx_test")

  let runRequest = try PostHogDashboardRequest.runInsights(configuration: configuration, refresh: "blocking")
  XCTAssertEqual(runRequest.url?.absoluteString, "https://us.posthog.com/api/environments/324426/dashboards/1362888/run_insights/?output_format=json&refresh=blocking")
  XCTAssertEqual(runRequest.httpMethod, "GET")
  XCTAssertEqual(runRequest.value(forHTTPHeaderField: "Authorization"), "Bearer phx_test")
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PostHogGrowthProviderTests/testPostHogConfigurationReadsDashboardIDFromEnvironment -only-testing:PRBarTests/PostHogGrowthProviderTests/testPostHogConfigurationIgnoresInvalidDashboardID -only-testing:PRBarTests/PostHogGrowthProviderTests/testPostHogDashboardRequestsUseEnvironmentDashboardEndpoints
```

Expected: compile failure because `dashboardID` and `PostHogDashboardRequest` do not exist.

- [ ] **Step 3: Add dashboard ID and request builders**

Update `PostHogConfiguration`:

```swift
struct PostHogConfiguration: Equatable, Sendable {
  var host: URL
  var projectID: String
  var personalAPIKey: String
  var dashboardID: Int?

  static func live(environment: [String: String]) -> PostHogConfiguration? {
    guard let projectID = normalized(environment["PRBAR_IOS_POSTHOG_PROJECT_ID"]),
      let personalAPIKey = normalized(environment["PRBAR_IOS_POSTHOG_PERSONAL_API_KEY"])
    else {
      return nil
    }

    let hostValue = normalized(environment["PRBAR_IOS_POSTHOG_HOST"]) ?? "https://us.posthog.com"
    guard let host = URL(string: hostValue), host.scheme != nil, host.host != nil else {
      return nil
    }

    let dashboardID = normalized(environment["PRBAR_IOS_POSTHOG_DASHBOARD_ID"]).flatMap(Int.init)

    return PostHogConfiguration(
      host: host,
      projectID: projectID,
      personalAPIKey: personalAPIKey,
      dashboardID: dashboardID
    )
  }

  static let fixture = PostHogConfiguration(
    host: URL(string: "https://us.posthog.com")!,
    projectID: "12345",
    personalAPIKey: "phx_fixture",
    dashboardID: 1362888
  )
}
```

Add this request builder in the same file:

```swift
enum PostHogDashboardRequest {
  static func dashboard(configuration: PostHogConfiguration) throws -> URLRequest {
    guard let dashboardID = configuration.dashboardID,
      let url = URL(
        string: "/api/environments/\(configuration.projectID)/dashboards/\(dashboardID)/",
        relativeTo: configuration.host
      )?.absoluteURL
    else {
      throw PostHogAPIError.invalidURL
    }

    return request(url: url, apiKey: configuration.personalAPIKey)
  }

  static func runInsights(configuration: PostHogConfiguration, refresh: String) throws -> URLRequest {
    guard let dashboardID = configuration.dashboardID,
      let url = URL(
        string: "/api/environments/\(configuration.projectID)/dashboards/\(dashboardID)/run_insights/?output_format=json&refresh=\(refresh)",
        relativeTo: configuration.host
      )?.absoluteURL
    else {
      throw PostHogAPIError.invalidURL
    }

    return request(url: url, apiKey: configuration.personalAPIKey)
  }

  private static func request(url: URL, apiKey: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    return request
  }
}
```

- [ ] **Step 4: Run tests to verify pass**

Run the same focused `xcodebuild test` command.

Expected: the three tests pass.

- [ ] **Step 5: Commit**

```bash
git add apple/PRBarShared/PostHogGrowthProvider.swift apple/PRBarTests/PostHogGrowthProviderTests.swift
git commit -m "Add PostHog dashboard configuration"
```

---

### Task 2: Decode Dashboard Run Results

**Files:**
- Create: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
- Test: `/Users/neonwatty/Desktop/prbar/apple/PRBarTests/PostHogGrowthProviderTests.swift`

- [ ] **Step 1: Write failing decode tests**

Add this test:

```swift
func testPostHogDashboardRunResponseDecodesTrendAndBreakdownTiles() throws {
  let data = Data(
    """
    {
      "results": [
        {
          "id": 6536095,
          "insight": {
            "id": 7359527,
            "name": "Daily Pageviews",
            "result": [
              {
                "data": [139, 179, 1036],
                "days": ["2026-04-27", "2026-04-28", "2026-04-29"],
                "count": 1314,
                "label": "$pageview"
              }
            ]
          },
          "order": 1
        },
        {
          "id": 6536096,
          "insight": {
            "id": 7359528,
            "name": "Top Pages",
            "result": [
              {
                "data": [1087, 879],
                "days": ["2026-04-26", "2026-05-03"],
                "count": 1966,
                "label": "/studio",
                "breakdown_value": "/studio"
              }
            ]
          },
          "order": 2
        }
      ]
    }
    """.utf8
  )

  let response = try JSONDecoder().decode(PostHogDashboardRunResponse.self, from: data)

  XCTAssertEqual(response.results.count, 2)
  XCTAssertEqual(response.results[0].insight.name, "Daily Pageviews")
  XCTAssertEqual(response.results[0].insight.result[0].count, 1314)
  XCTAssertEqual(response.results[1].insight.result[0].breakdownValue, "/studio")
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PostHogGrowthProviderTests/testPostHogDashboardRunResponseDecodesTrendAndBreakdownTiles
```

Expected: compile failure because `PostHogDashboardRunResponse` does not exist.

- [ ] **Step 3: Add decoder models**

Create `PostHogDashboardGrowthProvider.swift`:

```swift
import Foundation

struct PostHogDashboardRunResponse: Decodable, Equatable, Sendable {
  var results: [PostHogDashboardTileResult]
}

struct PostHogDashboardTileResult: Decodable, Equatable, Sendable {
  var id: Int
  var insight: PostHogDashboardInsight
  var order: Int?
}

struct PostHogDashboardInsight: Decodable, Equatable, Sendable {
  var id: Int
  var name: String
  var result: [PostHogDashboardSeries]
}

struct PostHogDashboardSeries: Decodable, Equatable, Sendable {
  var data: [Double]
  var days: [String]
  var count: Double
  var label: String
  var breakdownValue: String?

  enum CodingKeys: String, CodingKey {
    case data
    case days
    case count
    case label
    case breakdownValue = "breakdown_value"
  }
}
```

- [ ] **Step 4: Run test to verify pass**

Run the same focused `xcodebuild test` command.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apple/PRBarShared/PostHogDashboardGrowthProvider.swift apple/PRBarTests/PostHogGrowthProviderTests.swift
git commit -m "Decode PostHog dashboard results"
```

---

### Task 3: Normalize Supported Bleep Dashboard Tiles

**Files:**
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/GrowthModels.swift`
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
- Test: `/Users/neonwatty/Desktop/prbar/apple/PRBarTests/PostHogGrowthProviderTests.swift`

- [ ] **Step 1: Write failing normalizer test**

Add this test:

```swift
func testBleepBlogDashboardNormalizerMapsSupportedTilesToGrowthSnapshot() throws {
  let response = PostHogDashboardRunResponse(results: [
    PostHogDashboardTileResult(
      id: 6536094,
      insight: PostHogDashboardInsight(
        id: 7359526,
        name: "Weekly Visitors",
        result: [
          PostHogDashboardSeries(
            data: [128, 205],
            days: ["2026-02-22", "2026-03-01"],
            count: 333,
            label: "$pageview",
            breakdownValue: nil
          )
        ]
      ),
      order: 0
    ),
    PostHogDashboardTileResult(
      id: 6536095,
      insight: PostHogDashboardInsight(
        id: 7359527,
        name: "Daily Pageviews",
        result: [
          PostHogDashboardSeries(
            data: [139, 179, 1036],
            days: ["2026-04-27", "2026-04-28", "2026-04-29"],
            count: 1314,
            label: "$pageview",
            breakdownValue: nil
          )
        ]
      ),
      order: 1
    ),
    PostHogDashboardTileResult(
      id: 6536096,
      insight: PostHogDashboardInsight(
        id: 7359528,
        name: "Top Pages",
        result: [
          PostHogDashboardSeries(data: [1087, 879], days: ["2026-04-26", "2026-05-03"], count: 1966, label: "/studio", breakdownValue: "/studio"),
          PostHogDashboardSeries(data: [331, 382], days: ["2026-04-26", "2026-05-03"], count: 713, label: "/", breakdownValue: "/")
        ]
      ),
      order: 2
    ),
    PostHogDashboardTileResult(
      id: 8008478,
      insight: PostHogDashboardInsight(
        id: 8822775,
        name: "Blog -> Signup Activation",
        result: []
      ),
      order: 7
    ),
  ])

  let snapshot = try BleepBlogDashboardNormalizer.snapshot(
    response: response,
    projectID: "bleep-that-sht",
    range: .month,
    anchorDate: SampleData.date("2026-05-27"),
    baseSnapshot: .fixture(range: .month)
  )

  XCTAssertEqual(snapshot.project.id, "bleep-that-sht")
  XCTAssertEqual(snapshot.project.name, "Bleep Blog KPI Dashboard")
  XCTAssertEqual(snapshot.dataSource, .livePostHog)
  XCTAssertEqual(snapshot.metrics.map(\\.title), ["Weekly visitors", "Daily pageviews"])
  XCTAssertEqual(snapshot.metrics.first?.formattedValue, "333")
  XCTAssertEqual(snapshot.metrics.first?.series.map(\\.value), [128, 205])
  XCTAssertEqual(snapshot.topPages.map(\\.title), ["/studio", "/"])
  XCTAssertEqual(snapshot.topPages.map(\\.value), ["1,966 views", "713 views"])
  XCTAssertTrue(snapshot.issues.contains { $0.title == "Unsupported PostHog tile" && $0.detail.contains("Blog -> Signup Activation") })
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PostHogGrowthProviderTests/testBleepBlogDashboardNormalizerMapsSupportedTilesToGrowthSnapshot
```

Expected: compile failure because `BleepBlogDashboardNormalizer` and new metric kinds do not exist.

- [ ] **Step 3: Add metric kinds**

Add to `GrowthMetricKind`:

```swift
case weeklyVisitors
case pageViews
```

Update the `priority` array in `GrowthDashboardSnapshot.visibleMetrics`:

```swift
let priority: [GrowthMetricKind] = [
  .weeklyVisitors,
  .pageViews,
  .activeUsers,
  .keyEventCount,
  .searchClicks,
  .searchImpressions,
  .conversionRate,
  .searchCTR,
  .averagePosition,
]
```

- [ ] **Step 4: Add normalizer**

Add to `PostHogDashboardGrowthProvider.swift`:

```swift
enum BleepBlogDashboardNormalizer {
  static func snapshot(
    response: PostHogDashboardRunResponse,
    projectID: GrowthProject.ID,
    range: ActivityRange,
    anchorDate: Date,
    baseSnapshot: GrowthDashboardSnapshot
  ) throws -> GrowthDashboardSnapshot {
    var snapshot = baseSnapshot
    snapshot.dataSource = .livePostHog
    snapshot.project = GrowthProject(
      id: projectID,
      name: "Bleep Blog KPI Dashboard",
      repositoryIDs: [],
      postHogConnectionID: "posthog-bleep-blog",
      searchConsoleConnectionID: nil
    )
    snapshot.range = range
    snapshot.anchorDate = anchorDate
    snapshot.connections = [
      GrowthConnection(
        id: "posthog-bleep-blog",
        provider: .postHog,
        displayName: "PostHog",
        status: .connected,
        lastRefreshedAt: Date(),
        issue: nil
      ),
      GrowthConnection(
        id: "gsc-main",
        provider: .searchConsole,
        displayName: "Search Console",
        status: .notConnected,
        lastRefreshedAt: nil,
        issue: nil
      ),
    ]
    snapshot.metrics = supportedMetrics(from: response)
    snapshot.topEvents = topRows(named: "Traffic Sources", in: response, detail: "referrer", valueSuffix: "views")
    snapshot.topQueries = []
    snapshot.topPages = topRows(named: "Top Pages", in: response, detail: "page", valueSuffix: "views")
    snapshot.shippingContext = GrowthShippingContext(pullRequestCount: 0, releaseCount: 0, topRepositoryName: nil)
    snapshot.issues = unsupportedIssues(from: response)
    return snapshot
  }

  private static func supportedMetrics(from response: PostHogDashboardRunResponse) -> [GrowthMetric] {
    response.results.compactMap { tile in
      switch tile.insight.name {
      case "Weekly Visitors":
        return metric(tile: tile, id: "bleep-weekly-visitors", title: "Weekly visitors", kind: .weeklyVisitors)
      case "Daily Pageviews":
        return metric(tile: tile, id: "bleep-daily-pageviews", title: "Daily pageviews", kind: .pageViews)
      default:
        return nil
      }
    }
  }

  private static func metric(
    tile: PostHogDashboardTileResult,
    id: String,
    title: String,
    kind: GrowthMetricKind
  ) -> GrowthMetric? {
    guard let series = tile.insight.result.first else {
      return nil
    }
    return GrowthMetric(
      id: id,
      provider: .postHog,
      kind: kind,
      title: title,
      value: series.count,
      formattedValue: countFormatter.string(from: NSNumber(value: series.count)) ?? "\(Int(series.count))",
      unit: .count,
      delta: nil,
      series: zip(series.days, series.data).compactMap { day, value in
        guard let date = dateFormatter.date(from: day) else {
          return nil
        }
        return GrowthMetricPoint(date: date, value: value)
      }
    )
  }

  private static func topRows(
    named insightName: String,
    in response: PostHogDashboardRunResponse,
    detail: String,
    valueSuffix: String
  ) -> [GrowthListRow] {
    guard let tile = response.results.first(where: { $0.insight.name == insightName }) else {
      return []
    }

    return tile.insight.result
      .filter { $0.breakdownValue != "$$_posthog_breakdown_other_$$" }
      .sorted { $0.count > $1.count }
      .prefix(6)
      .map { series in
        let title = series.breakdownValue ?? series.label
        let formatted = countFormatter.string(from: NSNumber(value: series.count)) ?? "\(Int(series.count))"
        return GrowthListRow(
          id: "\(insightName)-\(title)",
          title: title,
          detail: detail,
          value: "\(formatted) \(valueSuffix)"
        )
      }
  }

  private static func unsupportedIssues(from response: PostHogDashboardRunResponse) -> [GrowthDashboardIssue] {
    response.results
      .filter { tile in
        ["Weekly Visitors", "Daily Pageviews", "Top Pages", "Traffic Sources"].contains(tile.insight.name) == false
      }
      .map { tile in
        GrowthDashboardIssue(
          id: "unsupported-posthog-tile-\(tile.id)",
          provider: .postHog,
          title: "Unsupported PostHog tile",
          detail: "\(tile.insight.name) is present in the dashboard but not rendered in this experiment."
        )
      }
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private static let countFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter
  }()
}
```

- [ ] **Step 5: Run test to verify pass**

Run the same focused `xcodebuild test` command.

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apple/PRBarShared/GrowthModels.swift apple/PRBarShared/PostHogDashboardGrowthProvider.swift apple/PRBarTests/PostHogGrowthProviderTests.swift
git commit -m "Normalize Bleep PostHog dashboard tiles"
```

---

### Task 4: Add Dashboard Provider

**Files:**
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
- Test: `/Users/neonwatty/Desktop/prbar/apple/PRBarTests/PostHogGrowthProviderTests.swift`

- [ ] **Step 1: Write failing provider test**

Add this test:

```swift
func testPostHogDashboardGrowthProviderFetchesRunInsightsAndReturnsBleepSnapshot() async throws {
  let runInsightsJSON = """
  {
    "results": [
      {
        "id": 6536094,
        "insight": {
          "id": 7359526,
          "name": "Weekly Visitors",
          "result": [
            { "data": [128, 205], "days": ["2026-02-22", "2026-03-01"], "count": 333, "label": "$pageview" }
          ]
        },
        "order": 0
      },
      {
        "id": 6536095,
        "insight": {
          "id": 7359527,
          "name": "Daily Pageviews",
          "result": [
            { "data": [139, 179, 1036], "days": ["2026-04-27", "2026-04-28", "2026-04-29"], "count": 1314, "label": "$pageview" }
          ]
        },
        "order": 1
      }
    ]
  }
  """
  let transport = FixturePostHogQueryTransport(responses: [runInsightsJSON])
  let provider = PostHogDashboardGrowthProvider(
    configuration: .fixture,
    transport: transport,
    baseSnapshot: .fixture(range: .month)
  )

  let snapshot = try await provider.dashboard(
    projectID: "bleep-that-sht",
    range: .month,
    anchorDate: SampleData.date("2026-05-27")
  )

  XCTAssertEqual(snapshot.project.name, "Bleep Blog KPI Dashboard")
  XCTAssertEqual(snapshot.metrics.map(\\.title), ["Weekly visitors", "Daily pageviews"])
  XCTAssertEqual(snapshot.connection(for: .postHog)?.status, .connected)
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PostHogGrowthProviderTests/testPostHogDashboardGrowthProviderFetchesRunInsightsAndReturnsBleepSnapshot
```

Expected: compile failure because `PostHogDashboardGrowthProvider` does not exist.

- [ ] **Step 3: Add provider**

Add to `PostHogDashboardGrowthProvider.swift`:

```swift
struct PostHogDashboardGrowthProvider: GrowthDashboardProviding {
  var configuration: PostHogConfiguration
  var transport: PostHogQueryTransport
  var baseSnapshot: GrowthDashboardSnapshot

  init(
    configuration: PostHogConfiguration,
    transport: PostHogQueryTransport = URLSessionPostHogQueryTransport(),
    baseSnapshot: GrowthDashboardSnapshot = SampleData.growthDashboard
  ) {
    self.configuration = configuration
    self.transport = transport
    self.baseSnapshot = baseSnapshot
  }

  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot {
    do {
      let request = try PostHogDashboardRequest.runInsights(configuration: configuration, refresh: "blocking")
      let data = try await transport.data(for: request)
      let response = try JSONDecoder().decode(PostHogDashboardRunResponse.self, from: data)
      return try BleepBlogDashboardNormalizer.snapshot(
        response: response,
        projectID: projectID,
        range: range,
        anchorDate: anchorDate,
        baseSnapshot: baseSnapshot
      )
    } catch PostHogAPIError.unauthorized {
      return attentionSnapshot(projectID: projectID, range: range, anchorDate: anchorDate, message: "PostHog API key needs attention")
    } catch PostHogAPIError.rateLimited {
      return attentionSnapshot(projectID: projectID, range: range, anchorDate: anchorDate, message: "PostHog rate limit reached")
    }
  }

  private func attentionSnapshot(
    projectID: GrowthProject.ID,
    range: ActivityRange,
    anchorDate: Date,
    message: String
  ) -> GrowthDashboardSnapshot {
    var snapshot = baseSnapshot
    snapshot.dataSource = .sampleFallback
    snapshot.project.id = projectID
    snapshot.project.name = "Bleep Blog KPI Dashboard"
    snapshot.range = range
    snapshot.anchorDate = anchorDate
    snapshot.connections = [
      GrowthConnection(
        id: "posthog-bleep-blog",
        provider: .postHog,
        displayName: "PostHog",
        status: .needsAttention,
        lastRefreshedAt: nil,
        issue: message
      )
    ]
    snapshot.issues = [
      GrowthDashboardIssue(
        id: "posthog-dashboard-needs-attention",
        provider: .postHog,
        title: "PostHog needs attention",
        detail: message
      )
    ]
    return snapshot
  }
}
```

- [ ] **Step 4: Run test to verify pass**

Run the same focused `xcodebuild test` command.

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apple/PRBarShared/PostHogDashboardGrowthProvider.swift apple/PRBarTests/PostHogGrowthProviderTests.swift
git commit -m "Add Bleep dashboard growth provider"
```

---

### Task 5: Wire The Experiment Into App Startup

**Files:**
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBar/PRBarApp.swift`
- Modify: `/Users/neonwatty/Desktop/prbar/apple/project.yml`
- Test: `/Users/neonwatty/Desktop/prbar/apple/PRBarTests/PostHogGrowthProviderTests.swift`

- [ ] **Step 1: Write failing factory test**

If `PRBarApp` has no testable provider factory, add a small helper near the existing app startup logic:

```swift
enum GrowthProviderFactory {
  static func provider(
    environment: [String: String],
    baseSnapshot: GrowthDashboardSnapshot = SampleData.growthDashboard
  ) -> GrowthDashboardProviding {
    guard let configuration = PostHogConfiguration.live(environment: environment) else {
      return StaticGrowthDashboardProvider(snapshot: baseSnapshot)
    }
    if configuration.dashboardID != nil {
      return PostHogDashboardGrowthProvider(configuration: configuration, baseSnapshot: baseSnapshot)
    }
    return PostHogGrowthProvider(configuration: configuration, baseSnapshot: baseSnapshot)
  }
}
```

Add this test:

```swift
func testGrowthProviderFactoryUsesDashboardProviderWhenDashboardIDIsConfigured() {
  let provider = GrowthProviderFactory.provider(
    environment: [
      "PRBAR_IOS_POSTHOG_PROJECT_ID": "324426",
      "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
      "PRBAR_IOS_POSTHOG_DASHBOARD_ID": "1362888",
    ]
  )

  XCTAssertTrue(provider is PostHogDashboardGrowthProvider)
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PostHogGrowthProviderTests/testGrowthProviderFactoryUsesDashboardProviderWhenDashboardIDIsConfigured
```

Expected: compile failure if `GrowthProviderFactory` has not been added.

- [ ] **Step 3: Wire provider factory**

In `PRBarApp`, replace the duplicated growth-provider selection with:

```swift
growthProvider = GrowthProviderFactory.provider(environment: ProcessInfo.processInfo.environment)
```

If `uiTestingPostHogNeedsAttention` needs to force a static fixture, keep that branch before the factory:

```swift
if uiTestingPostHogNeedsAttention {
  growthProvider = StaticGrowthDashboardProvider(snapshot: Self.uiTestingPostHogNeedsAttentionGrowthSnapshot)
} else {
  growthProvider = GrowthProviderFactory.provider(environment: ProcessInfo.processInfo.environment)
}
```

In `apple/project.yml`, add the dashboard env var under both `PRBar` and `PRBarPreview` test scheme environment variables:

```yaml
PRBAR_IOS_POSTHOG_DASHBOARD_ID: $(PRBAR_IOS_POSTHOG_DASHBOARD_ID)
```

- [ ] **Step 4: Regenerate project**

Run:

```bash
./scripts/ios-generate.sh
```

Expected: `apple/PRBar.xcodeproj` regenerates without errors.

- [ ] **Step 5: Run test to verify pass**

Run the same focused `xcodebuild test` command.

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apple/PRBar/PRBarApp.swift apple/project.yml apple/PRBarTests/PostHogGrowthProviderTests.swift
git commit -m "Wire Bleep dashboard provider experiment"
```

---

### Task 6: Add Focused UI Coverage For The Experiment

**Files:**
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBarUITests/PRBarUITests.swift`
- Modify: `/Users/neonwatty/Desktop/prbar/apple/PRBar/PRBarApp.swift`

- [ ] **Step 1: Add UI testing fixture mode**

In `PRBarApp`, add a launch environment branch named `uiTestingBleepPostHogDashboard` that sets `store.growthSnapshot` to a fixture created through the normalizer:

```swift
if ProcessInfo.processInfo.environment["PRBAR_UI_TESTING_BLEEP_POSTHOG_DASHBOARD"] == "1" {
  store.growthSnapshot = Self.uiTestingBleepPostHogDashboardSnapshot
}
```

Add:

```swift
static var uiTestingBleepPostHogDashboardSnapshot: GrowthDashboardSnapshot {
  let response = PostHogDashboardRunResponse(results: [
    PostHogDashboardTileResult(
      id: 6536094,
      insight: PostHogDashboardInsight(
        id: 7359526,
        name: "Weekly Visitors",
        result: [
          PostHogDashboardSeries(data: [128, 205], days: ["2026-02-22", "2026-03-01"], count: 333, label: "$pageview", breakdownValue: nil)
        ]
      ),
      order: 0
    ),
    PostHogDashboardTileResult(
      id: 6536095,
      insight: PostHogDashboardInsight(
        id: 7359527,
        name: "Daily Pageviews",
        result: [
          PostHogDashboardSeries(data: [139, 179, 1036], days: ["2026-04-27", "2026-04-28", "2026-04-29"], count: 1314, label: "$pageview", breakdownValue: nil)
        ]
      ),
      order: 1
    ),
    PostHogDashboardTileResult(
      id: 6536096,
      insight: PostHogDashboardInsight(
        id: 7359528,
        name: "Top Pages",
        result: [
          PostHogDashboardSeries(data: [1087, 879], days: ["2026-04-26", "2026-05-03"], count: 1966, label: "/studio", breakdownValue: "/studio")
        ]
      ),
      order: 2
    ),
  ])

  return (try? BleepBlogDashboardNormalizer.snapshot(
    response: response,
    projectID: "bleep-that-sht",
    range: .month,
    anchorDate: SampleData.date("2026-05-27"),
    baseSnapshot: .fixture(range: .month)
  )) ?? SampleData.growthDashboard
}
```

- [ ] **Step 2: Add UI test**

Add to `PRBarUITests`:

```swift
func testGrowthTabRendersBleepPostHogDashboardExperiment() {
  let app = XCUIApplication()
  app.launchEnvironment["PRBAR_UI_TESTING"] = "1"
  app.launchEnvironment["PRBAR_UI_TESTING_BLEEP_POSTHOG_DASHBOARD"] = "1"
  app.launch()

  XCTAssertTrue(app.buttons["Growth"].waitForExistence(timeout: 2))
  app.buttons["Growth"].tap()

  XCTAssertTrue(app.staticTexts["Bleep Blog KPI Dashboard"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Live PostHog"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Weekly visitors"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["Daily pageviews"].waitForExistence(timeout: 2))
  XCTAssertTrue(app.staticTexts["/studio"].waitForExistence(timeout: 2))
}
```

- [ ] **Step 3: Run UI test to verify pass**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersBleepPostHogDashboardExperiment
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add apple/PRBar/PRBarApp.swift apple/PRBarUITests/PRBarUITests.swift
git commit -m "Cover Bleep dashboard Growth UI"
```

---

### Task 7: Verify Live Dashboard Experiment

**Files:**
- No source edits expected.

- [ ] **Step 1: Run unit tests**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarTests/PostHogGrowthProviderTests
```

Expected: all PostHog provider tests pass.

- [ ] **Step 2: Run focused UI test**

Run:

```bash
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersBleepPostHogDashboardExperiment
```

Expected: PASS.

- [ ] **Step 3: Run iOS build**

Run:

```bash
./scripts/ios-build.sh
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Run live simulator smoke with real dashboard config**

Run with real values available in the shell:

```bash
PRBAR_IOS_POSTHOG_HOST=https://us.posthog.com \
PRBAR_IOS_POSTHOG_PROJECT_ID=324426 \
PRBAR_IOS_POSTHOG_DASHBOARD_ID=1362888 \
PRBAR_IOS_POSTHOG_PERSONAL_API_KEY="$PRBAR_IOS_POSTHOG_PERSONAL_API_KEY" \
xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersBleepPostHogDashboardExperiment
```

Expected: the app launches and the Growth screen can render the dashboard fixture test. This does not prove network data in the UI because the test intentionally uses fixture mode; network provider behavior is covered by provider tests with fixture transport.

- [ ] **Step 5: Manually run the app with live provider**

Run:

```bash
PRBAR_IOS_POSTHOG_HOST=https://us.posthog.com \
PRBAR_IOS_POSTHOG_PROJECT_ID=324426 \
PRBAR_IOS_POSTHOG_DASHBOARD_ID=1362888 \
PRBAR_IOS_POSTHOG_PERSONAL_API_KEY="$PRBAR_IOS_POSTHOG_PERSONAL_API_KEY" \
./scripts/ios-build.sh
```

Then open the app in Simulator through the normal local workflow and confirm:

- Growth tab source chip says `Live PostHog`.
- Project title says `Bleep Blog KPI Dashboard`.
- Metric tiles include `Weekly visitors` and `Daily pageviews`.
- Provider section includes `/studio` under top pages.
- Unsupported funnel tiles appear as issues only if the UI displays `GrowthDashboardIssue` rows.

- [ ] **Step 6: Final commit if any verification-only changes were needed**

If no files changed:

```bash
git status --short
```

Expected: no output.

If files changed, commit them:

```bash
git add apple/PRBarShared apple/PRBar apple/PRBarTests apple/PRBarUITests apple/project.yml
git commit -m "Verify Bleep dashboard experiment"
```

---

## Acceptance Criteria

- The app can represent the `Bleep Blog KPI Dashboard` without changing tabs or adding a new surface.
- When dashboard ID `1362888` is configured, the Growth provider uses dashboard run-insights results instead of the existing ad hoc HogQL provider.
- The Growth tab shows `Live PostHog` and `Bleep Blog KPI Dashboard`.
- The Growth metrics include:
  - `Weekly visitors`
  - `Daily pageviews`
- The Growth list sections include:
  - top pages from `Top Pages`
  - referrers from `Traffic Sources`
- Funnel tiles are explicitly reported as unsupported and do not crash or hide the supported metrics.
- All new provider behavior is covered by unit tests using fixture JSON.
- One UI test verifies the iOS Growth surface renders the dashboard-shaped snapshot.
- `./scripts/ios-build.sh` passes.

## Follow-Up Work Explicitly Out Of Scope

- Storing PostHog credentials in a production-safe backend.
- Installing this on the production iPhone.
- Adding a dashboard picker.
- Supporting other PostHog dashboards.
- Rendering funnels.
- Rendering all PostHog chart types.
- Combining GitHub releases/PRs with this dashboard.
