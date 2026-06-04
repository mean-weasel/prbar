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
  case weeklyVisitors
  case pageViews
  case activeUsers
  case keyEventCount
  case conversionRate
  case searchClicks
  case searchImpressions
  case searchCTR
  case averagePosition
  case custom

  var id: String { rawValue }
}

enum GrowthMetricUnit: String, Codable, Sendable {
  case count
  case percent
  case position
}

enum GrowthMetricChartKind: String, Codable, Sendable {
  case trend
  case line
  case bar
  case area
  case value
}

enum GrowthMetricYAxisScale: String, Codable, Sendable {
  case linear
  case log10
}

struct GrowthMetricChartMetadata: Codable, Equatable, Sendable {
  var kind: GrowthMetricChartKind
  var xAxisLabel: String?
  var yAxisLabel: String?
  var yAxisScale: GrowthMetricYAxisScale?
  var sourceInsightID: String?
  var sourceInsightName: String?
  var sourceDisplay: String?
}

enum GrowthDataSource: String, Codable, Equatable, Sendable {
  case sample
  case livePostHog
  case sampleFallback

  var displayName: String {
    switch self {
    case .sample:
      "Sample data"
    case .livePostHog:
      "Live PostHog"
    case .sampleFallback:
      "Sample fallback"
    }
  }

  var detail: String {
    switch self {
    case .sample:
      "Growth is using the built-in demo snapshot."
    case .livePostHog:
      "Growth is using live PostHog query results."
    case .sampleFallback:
      "Growth is showing cached sample data because the live provider needs attention."
    }
  }
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
  var chartMetadata: GrowthMetricChartMetadata? = nil

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
  var dataSource: GrowthDataSource
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
      .custom,
    ]

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
      dataSource: .sample,
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
      shippingContext: Self.fixtureShippingContext(project: project, range: range, anchorDate: anchorDate),
      issues: []
    )
  }

  private static func fixtureSeries(_ values: [Double]) -> [GrowthMetricPoint] {
    let dates = CalendarDay.days(endingAt: SampleData.date("2026-05-24"), range: .week).map(\.date)
    return zip(dates, values).map { GrowthMetricPoint(date: $0.0, value: $0.1) }
  }

  static func fixtureShippingContext(
    project: GrowthProject,
    range: ActivityRange,
    anchorDate: Date
  ) -> GrowthShippingContext {
    let repositoryIDs = Set(project.repositoryIDs)
    let days = CalendarDay.days(endingAt: anchorDate, range: range).map(\.date)
    let pullRequestCount = SampleData.pullRequests.filter { pullRequest in
      repositoryIDs.contains(pullRequest.repoID) && days.contains { CalendarDay.isSameDay($0, pullRequest.mergedAt) }
    }.count
    let releaseCount = SampleData.releases.filter { release in
      repositoryIDs.contains(release.repoID) && days.contains { CalendarDay.isSameDay($0, release.date) }
    }.count

    return GrowthShippingContext(
      pullRequestCount: pullRequestCount,
      releaseCount: releaseCount,
      topRepositoryName: "prbar"
    )
  }
}
