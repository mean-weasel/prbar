import Foundation

struct PostHogDashboardRunResponse: Decodable, Equatable {
  var results: [PostHogDashboardTileResult]

  init(data: Data) throws {
    self = try JSONDecoder().decode(Self.self, from: data)
  }
}

struct PostHogDashboardTileResult: Decodable, Equatable {
  var id: Int
  var order: Int?
  var insight: PostHogDashboardInsight
}

struct PostHogDashboardInsight: Decodable, Equatable {
  var id: Int
  var shortID: String?
  var name: String?
  var derivedName: String?
  var result: [PostHogDashboardSeries]

  private enum CodingKeys: String, CodingKey {
    case id
    case shortID = "short_id"
    case name
    case derivedName = "derived_name"
    case result
  }
}

struct PostHogDashboardSeries: Decodable, Equatable {
  var data: [Double]
  var days: [String]
  var count: Double?
  var label: String?
  var breakdownValue: String?

  private enum CodingKeys: String, CodingKey {
    case data
    case days
    case count
    case label
    case breakdownValue = "breakdown_value"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    data = try container.decode([Double].self, forKey: .data)
    days = try container.decode([String].self, forKey: .days)
    count = try container.decodeFlexibleDoubleIfPresent(forKey: .count)
    label = try container.decodeIfPresent(String.self, forKey: .label)
    breakdownValue = try container.decodeIfPresent(String.self, forKey: .breakdownValue)
  }
}

enum BleepBlogDashboardNormalizer {
  static func snapshot(
    response: PostHogDashboardRunResponse,
    range: ActivityRange,
    anchorDate: Date
  ) -> GrowthDashboardSnapshot {
    let tiles = orderedTiles(from: response)
    let project = GrowthProject(
      id: "bleep-that-sht",
      name: "Bleep Blog KPI Dashboard",
      repositoryIDs: [],
      postHogConnectionID: "posthog-main",
      searchConsoleConnectionID: nil
    )

    var metrics: [GrowthMetric] = []
    var topEvents: [GrowthListRow] = []
    var topPages: [GrowthListRow] = []
    var issues: [GrowthDashboardIssue] = []

    for tile in tiles {
      switch tile.insight.name ?? tile.insight.derivedName {
      case "Weekly Visitors":
        if let series = tile.insight.result.first {
          metrics.append(
            metric(
              id: "posthog-weekly-visitors",
              kind: .weeklyVisitors,
              title: "Weekly visitors",
              series: series
            )
          )
        }
      case "Daily Pageviews":
        if let series = tile.insight.result.first {
          metrics.append(
            metric(
              id: "posthog-page-views",
              kind: .pageViews,
              title: "Daily pageviews",
              series: series
            )
          )
        }
      case "Traffic Sources":
        topEvents = listRows(
          from: tile.insight.result,
          fallbackTitle: "Unknown source",
          detail: "traffic source"
        )
      case "Top Pages":
        topPages = listRows(
          from: tile.insight.result,
          fallbackTitle: "Unknown page",
          detail: "top page"
        )
      default:
        let name = tile.insight.name ?? tile.insight.derivedName ?? "Untitled dashboard tile"
        issues.append(
          GrowthDashboardIssue(
            id: "unsupported-dashboard-tile-\(tile.id)",
            provider: .postHog,
            title: "Unsupported dashboard tile",
            detail: "Dashboard tile \"\(name)\" is not supported yet."
          )
        )
      }
    }

    return GrowthDashboardSnapshot(
      dataSource: .livePostHog,
      project: project,
      range: range,
      anchorDate: anchorDate,
      connections: [
        GrowthConnection(
          id: "posthog-main",
          provider: .postHog,
          displayName: "PostHog",
          status: .connected,
          lastRefreshedAt: anchorDate,
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
      ],
      metrics: metrics,
      topEvents: topEvents,
      topQueries: [],
      topPages: topPages,
      shippingContext: GrowthShippingContext(
        pullRequestCount: 0,
        releaseCount: 0,
        topRepositoryName: nil
      ),
      issues: issues
    )
  }

  private static func orderedTiles(from response: PostHogDashboardRunResponse) -> [PostHogDashboardTileResult] {
    response.results.enumerated().sorted { lhs, rhs in
      switch (lhs.element.order, rhs.element.order) {
      case let (lhsOrder?, rhsOrder?) where lhsOrder != rhsOrder:
        return lhsOrder < rhsOrder
      case (_?, nil):
        return true
      case (nil, _?):
        return false
      default:
        return lhs.offset < rhs.offset
      }
    }.map(\.element)
  }

  private static func metric(
    id: String,
    kind: GrowthMetricKind,
    title: String,
    series: PostHogDashboardSeries
  ) -> GrowthMetric {
    let value = count(from: series)
    return GrowthMetric(
      id: id,
      provider: .postHog,
      kind: kind,
      title: title,
      value: value,
      formattedValue: formattedCount(value),
      unit: .count,
      delta: nil,
      series: metricPoints(from: series)
    )
  }

  private static func metricPoints(from series: PostHogDashboardSeries) -> [GrowthMetricPoint] {
    zip(series.days, series.data).compactMap { day, value in
      guard let date = dateFormatter.date(from: day) else {
        return nil
      }
      return GrowthMetricPoint(date: date, value: value)
    }
  }

  private static func listRows(
    from series: [PostHogDashboardSeries],
    fallbackTitle: String,
    detail: String
  ) -> [GrowthListRow] {
    series
      .enumerated()
      .filter { isOtherBreakdown($0.element) == false }
      .sorted { lhs, rhs in
        let lhsCount = count(from: lhs.element)
        let rhsCount = count(from: rhs.element)
        if lhsCount == rhsCount {
          return lhs.offset < rhs.offset
        }
        return lhsCount > rhsCount
      }
      .prefix(5)
      .map { _, row in
        listRow(
          series: row,
          fallbackTitle: fallbackTitle,
          detail: detail
        )
      }
  }

  private static func listRow(
    series: PostHogDashboardSeries,
    fallbackTitle: String,
    detail: String
  ) -> GrowthListRow {
    let title = series.breakdownValue ?? series.label ?? fallbackTitle
    return GrowthListRow(
      id: title,
      title: title,
      detail: detail,
      value: formattedCount(count(from: series))
    )
  }

  private static func isOtherBreakdown(_ series: PostHogDashboardSeries) -> Bool {
    [series.breakdownValue, series.label]
      .compactMap { $0 }
      .contains { value in
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "$$_posthog_breakdown_other_$$"
          || normalized == "__other__"
          || normalized == "other"
      }
  }

  private static func count(from series: PostHogDashboardSeries) -> Double {
    series.count ?? series.data.reduce(0, +)
  }

  private static func formattedCount(_ value: Double) -> String {
    countFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value.rounded()))"
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
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = true
    formatter.groupingSeparator = ","
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 0
    return formatter
  }()
}

private extension KeyedDecodingContainer {
  func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
    if let double = try decodeIfPresent(Double.self, forKey: key) {
      return double
    }
    if let int = try decodeIfPresent(Int.self, forKey: key) {
      return Double(int)
    }
    return nil
  }
}
