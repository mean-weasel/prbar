import Foundation

struct PostHogDashboardMetadataResponse: Decodable, Equatable {
  var id: Int?
  var name: String?
  var description: String?

  init(data: Data) throws {
    self = try JSONDecoder().decode(Self.self, from: data)
  }
}

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

  private enum CodingKeys: String, CodingKey {
    case id
    case order
    case insight
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = (try? container.decode(Int.self, forKey: .id)) ?? 0
    order = try? container.decode(Int.self, forKey: .order)
    insight = (try? container.decodeIfPresent(PostHogDashboardInsight.self, forKey: .insight)) ?? .empty
  }
}

struct PostHogDashboardInsight: Decodable, Equatable {
  var id: Int
  var shortID: String?
  var name: String?
  var derivedName: String?
  var filters: PostHogDashboardInsightFilters?
  var query: PostHogDashboardInsightQuery?
  var result: [PostHogDashboardSeries]

  private enum CodingKeys: String, CodingKey {
    case id
    case shortID = "short_id"
    case name
    case derivedName = "derived_name"
    case filters
    case query
    case result
  }

  static let empty = PostHogDashboardInsight(
    id: 0,
    shortID: nil,
    name: nil,
    derivedName: nil,
    filters: nil,
    query: nil,
    result: []
  )

  init(
    id: Int,
    shortID: String?,
    name: String?,
    derivedName: String?,
    filters: PostHogDashboardInsightFilters?,
    query: PostHogDashboardInsightQuery?,
    result: [PostHogDashboardSeries]
  ) {
    self.id = id
    self.shortID = shortID
    self.name = name
    self.derivedName = derivedName
    self.filters = filters
    self.query = query
    self.result = result
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = (try? container.decode(Int.self, forKey: .id)) ?? 0
    shortID = try container.decodeIfPresent(String.self, forKey: .shortID)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    derivedName = try container.decodeIfPresent(String.self, forKey: .derivedName)
    filters = try container.decodeIfPresent(PostHogDashboardInsightFilters.self, forKey: .filters)
    query = try container.decodeIfPresent(PostHogDashboardInsightQuery.self, forKey: .query)
    result = (try? container.decodeIfPresent([PostHogDashboardSeries].self, forKey: .result)) ?? []
  }
}

struct PostHogDashboardInsightFilters: Decodable, Equatable {
  var xAxisLabel: String?
  var yAxisLabel: String?
  var yAxisScaleType: String?
  var display: String?
  var insight: String?
  var interval: String?

  private enum CodingKeys: String, CodingKey {
    case xAxisLabel = "x_axis_label"
    case yAxisLabel = "y_axis_label"
    case yAxisScaleType = "y_axis_scale_type"
    case display
    case insight
    case interval
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    xAxisLabel = try container.decodeFlexibleStringIfPresent(forKey: .xAxisLabel)
    yAxisLabel = try container.decodeFlexibleStringIfPresent(forKey: .yAxisLabel)
    yAxisScaleType = try container.decodeFlexibleStringIfPresent(forKey: .yAxisScaleType)
    display = try container.decodeFlexibleStringIfPresent(forKey: .display)
    insight = try container.decodeFlexibleStringIfPresent(forKey: .insight)
    interval = try container.decodeFlexibleStringIfPresent(forKey: .interval)
  }
}

struct PostHogDashboardInsightQuery: Decodable, Equatable {
  var kind: String?
  var trendsFilter: PostHogDashboardTrendsFilter?
  var source: PostHogDashboardInsightQuerySource?

  private enum CodingKeys: String, CodingKey {
    case kind
    case trendsFilter
    case source
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    kind = try container.decodeFlexibleStringIfPresent(forKey: .kind)
    trendsFilter = try container.decodeIfPresent(PostHogDashboardTrendsFilter.self, forKey: .trendsFilter)
    source = try container.decodeIfPresent(PostHogDashboardInsightQuerySource.self, forKey: .source)
  }
}

struct PostHogDashboardInsightQuerySource: Decodable, Equatable {
  var kind: String?
  var trendsFilter: PostHogDashboardTrendsFilter?

  private enum CodingKeys: String, CodingKey {
    case kind
    case trendsFilter
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    kind = try container.decodeFlexibleStringIfPresent(forKey: .kind)
    trendsFilter = try container.decodeIfPresent(PostHogDashboardTrendsFilter.self, forKey: .trendsFilter)
  }
}

struct PostHogDashboardTrendsFilter: Decodable, Equatable {
  var xAxisLabel: String?
  var yAxisLabel: String?
  var yAxisScaleType: String?
  var display: String?

  private enum CodingKeys: String, CodingKey {
    case xAxisLabel
    case yAxisLabel
    case yAxisScaleType
    case display
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    xAxisLabel = try container.decodeFlexibleStringIfPresent(forKey: .xAxisLabel)
    yAxisLabel = try container.decodeFlexibleStringIfPresent(forKey: .yAxisLabel)
    yAxisScaleType = try container.decodeFlexibleStringIfPresent(forKey: .yAxisScaleType)
    display = try container.decodeFlexibleStringIfPresent(forKey: .display)
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
    data = try container.decodeFlexibleDoubleArrayIfPresent(forKey: .data) ?? []
    days = (try? container.decodeIfPresent([String].self, forKey: .days)) ?? []
    count = try container.decodeFlexibleDoubleIfPresent(forKey: .count)
    label = try container.decodeFlexibleStringIfPresent(forKey: .label)
    breakdownValue = try container.decodeFlexibleStringIfPresent(forKey: .breakdownValue)
  }
}

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
      let metadataRequest = try PostHogDashboardRequest.dashboard(configuration: configuration)
      let metadataData = try await transport.data(for: metadataRequest)
      _ = try PostHogDashboardMetadataResponse(data: metadataData)

      let runInsightsRequest = try PostHogDashboardRequest.runInsights(
        configuration: configuration,
        refresh: "blocking"
      )
      let runInsightsData = try await transport.data(for: runInsightsRequest)
      let response = try PostHogDashboardRunResponse(data: runInsightsData)
      var snapshot = BleepBlogDashboardNormalizer.snapshot(
        response: response,
        range: range,
        anchorDate: anchorDate
      )
      do {
        let dailySeriesRequest = try PostHogDashboardDailySeriesQuery.request(
          configuration: configuration,
          range: range,
          anchorDate: anchorDate
        )
        let dailySeriesData = try await transport.data(for: dailySeriesRequest)
        let dailySeries = try PostHogDashboardDailySeriesQuery.decode(dailySeriesData)
        if dailySeries.isEmpty == false {
          snapshot = Self.augment(snapshot: snapshot, dailySeries: dailySeries)
        }
      } catch {
        snapshot.issues.append(
          GrowthDashboardIssue(
            id: "posthog-daily-series-failed",
            provider: .postHog,
            title: "PostHog daily series unavailable",
            detail: "Dashboard tiles loaded, but the daily PostHog series query failed."
          )
        )
      }
      return snapshot
    } catch PostHogAPIError.unauthorized {
      return attentionSnapshot(
        projectID: projectID,
        range: range,
        anchorDate: anchorDate,
        message: "PostHog API key needs attention"
      )
    } catch PostHogAPIError.rateLimited {
      return attentionSnapshot(
        projectID: projectID,
        range: range,
        anchorDate: anchorDate,
        message: "PostHog rate limit reached"
      )
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
    snapshot.range = range
    snapshot.anchorDate = anchorDate
    snapshot.connections = snapshot.connections.map { connection in
      guard connection.provider == .postHog else {
        return connection
      }
      return GrowthConnection(
        id: connection.id,
        provider: connection.provider,
        displayName: connection.displayName,
        status: .needsAttention,
        lastRefreshedAt: connection.lastRefreshedAt,
        issue: message
      )
    }
    snapshot.shippingContext = GrowthDashboardSnapshot.fixtureShippingContext(
      project: snapshot.project,
      range: range,
      anchorDate: anchorDate
    )
    snapshot.issues = [
      GrowthDashboardIssue(
        id: "posthog-needs-attention",
        provider: .postHog,
        title: "PostHog needs attention",
        detail: message
      )
    ]
    return snapshot
  }

  private static func augment(
    snapshot: GrowthDashboardSnapshot,
    dailySeries: [PostHogDashboardDailySeries]
  ) -> GrowthDashboardSnapshot {
    var snapshot = snapshot
    let sortedSeries = dailySeries.sorted { $0.day < $1.day }
    let metrics = [
      dailyMetric(
        id: "posthog-weekly-visitors",
        kind: .weeklyVisitors,
        title: "Weekly visitors",
        dailySeries: sortedSeries,
        value: \.visitors,
        headlineMetric: snapshot.metrics.first { $0.kind == .weeklyVisitors },
        usesHeadlineValue: true
      ),
      dailyMetric(
        id: "posthog-page-views",
        kind: .pageViews,
        title: "Daily pageviews",
        dailySeries: sortedSeries,
        value: \.pageviews,
        headlineMetric: snapshot.metrics.first { $0.kind == .pageViews },
        usesHeadlineValue: false
      ),
    ]

    for metric in metrics {
      if let index = snapshot.metrics.firstIndex(where: { $0.kind == metric.kind }) {
        snapshot.metrics[index] = metric
      } else {
        snapshot.metrics.append(metric)
      }
    }
    return snapshot
  }

  private static func dailyMetric(
    id: String,
    kind: GrowthMetricKind,
    title: String,
    dailySeries: [PostHogDashboardDailySeries],
    value: KeyPath<PostHogDashboardDailySeries, Double>,
    headlineMetric: GrowthMetric?,
    usesHeadlineValue: Bool
  ) -> GrowthMetric {
    let total = dailySeries.reduce(0) { $0 + $1[keyPath: value] }
    let displayValue = usesHeadlineValue ? headlineMetric?.value ?? total : total
    let formattedValue = usesHeadlineValue
      ? headlineMetric?.formattedValue ?? formattedCount(total)
      : formattedCount(total)
    return GrowthMetric(
      id: id,
      provider: .postHog,
      kind: kind,
      title: title,
      value: displayValue,
      formattedValue: formattedValue,
      unit: .count,
      delta: nil,
      series: dailySeries.map { row in
        GrowthMetricPoint(date: row.day, value: row[keyPath: value])
      },
      chartMetadata: headlineMetric?.chartMetadata
    )
  }

  private static func formattedCount(_ value: Double) -> String {
    countFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value.rounded()))"
  }

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
              insight: tile.insight,
              series: series,
              fallbackXAxisLabel: "Calendar day",
              fallbackYAxisLabel: "Visitors"
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
              insight: tile.insight,
              series: series,
              fallbackXAxisLabel: "Calendar day",
              fallbackYAxisLabel: "Pageviews"
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
        if let customMetric = customTrendMetric(from: tile) {
          metrics.append(customMetric)
        } else {
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
    insight: PostHogDashboardInsight,
    series: PostHogDashboardSeries,
    fallbackXAxisLabel: String? = nil,
    fallbackYAxisLabel: String? = nil
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
      series: metricPoints(from: series),
      chartMetadata: chartMetadata(
        from: insight,
        fallbackXAxisLabel: fallbackXAxisLabel,
        fallbackYAxisLabel: fallbackYAxisLabel
      )
    )
  }

  private static func customTrendMetric(from tile: PostHogDashboardTileResult) -> GrowthMetric? {
    guard let series = tile.insight.result.first,
      isTrendSeries(series),
      let title = normalized(tile.insight.name) ?? normalized(tile.insight.derivedName)
    else {
      return nil
    }

    return metric(
      id: "posthog-insight-\(tile.insight.id)-\(tile.id)",
      kind: .custom,
      title: title,
      insight: tile.insight,
      series: series
    )
  }

  private static func isTrendSeries(_ series: PostHogDashboardSeries) -> Bool {
    metricPoints(from: series).isEmpty == false
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

  private static func chartMetadata(
    from insight: PostHogDashboardInsight,
    fallbackXAxisLabel: String? = nil,
    fallbackYAxisLabel: String? = nil
  ) -> GrowthMetricChartMetadata {
    let trendsFilter = insight.query?.trendsFilter ?? insight.query?.source?.trendsFilter
    let display = normalized(trendsFilter?.display)
      ?? normalized(insight.filters?.display)
      ?? normalized(insight.query?.kind)
      ?? normalized(insight.query?.source?.kind)
    let yAxisScale = normalized(trendsFilter?.yAxisScaleType)
      ?? normalized(insight.filters?.yAxisScaleType)

    return GrowthMetricChartMetadata(
      kind: chartKind(display: display),
      xAxisLabel: normalized(trendsFilter?.xAxisLabel)
        ?? normalized(insight.filters?.xAxisLabel)
        ?? fallbackXAxisLabel,
      yAxisLabel: normalized(trendsFilter?.yAxisLabel)
        ?? normalized(insight.filters?.yAxisLabel)
        ?? fallbackYAxisLabel,
      yAxisScale: yAxisScale.flatMap(GrowthMetricYAxisScale.init(rawValue:)),
      sourceInsightID: "\(insight.id)",
      sourceInsightName: normalized(insight.name) ?? normalized(insight.derivedName),
      sourceDisplay: display
    )
  }

  private static func chartKind(display: String?) -> GrowthMetricChartKind {
    guard let display = display?.lowercased() else {
      return .trend
    }
    if display.contains("bar") {
      return .bar
    }
    if display.contains("area") {
      return .area
    }
    if display.contains("number") || display.contains("bold") {
      return .value
    }
    if display.contains("line") || display.contains("graph") {
      return .line
    }
    return .trend
  }

  private static func normalized(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
      value.isEmpty == false
    else {
      return nil
    }
    return value
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
    if let double = try? decodeIfPresent(Double.self, forKey: key) {
      return double
    }
    if let int = try? decodeIfPresent(Int.self, forKey: key) {
      return Double(int)
    }
    if let string = try? decodeIfPresent(String.self, forKey: key),
      let double = Double(string)
    {
      return double
    }
    return nil
  }

  func decodeFlexibleDoubleArrayIfPresent(forKey key: Key) throws -> [Double]? {
    guard var values = try? nestedUnkeyedContainer(forKey: key) else {
      return nil
    }

    var doubles: [Double] = []
    while values.isAtEnd == false {
      if let double = try? values.decode(Double.self) {
        doubles.append(double)
      } else if let int = try? values.decode(Int.self) {
        doubles.append(Double(int))
      } else if let string = try? values.decode(String.self), let double = Double(string) {
        doubles.append(double)
      } else {
        _ = try? values.decode(PostHogDiscardedJSONValue.self)
      }
    }
    return doubles
  }

  func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
    if let string = try? decodeIfPresent(String.self, forKey: key) {
      return string
    }
    if let int = try? decodeIfPresent(Int.self, forKey: key) {
      return "\(int)"
    }
    if let double = try? decodeIfPresent(Double.self, forKey: key) {
      return "\(double)"
    }
    return nil
  }
}

private struct PostHogDiscardedJSONValue: Decodable {}
