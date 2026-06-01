import Foundation

struct PostHogConfiguration: Equatable, Sendable {
  var host: URL
  var projectID: String
  var personalAPIKey: String

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

    return PostHogConfiguration(host: host, projectID: projectID, personalAPIKey: personalAPIKey)
  }

  static let fixture = PostHogConfiguration(
    host: URL(string: "https://us.posthog.com")!,
    projectID: "12345",
    personalAPIKey: "phx_fixture"
  )

  private static func normalized(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
      value.isEmpty == false,
      value.hasPrefix("$(") == false
    else {
      return nil
    }
    return value
  }
}

enum PostHogAPIError: Error, Equatable, Sendable {
  case invalidURL
  case invalidResponse
  case unauthorized
  case rateLimited
  case server(statusCode: Int)
}

enum PostHogQueryRequest {
  static func query(configuration: PostHogConfiguration, sql: String) throws -> URLRequest {
    guard let url = URL(string: "/api/projects/\(configuration.projectID)/query/", relativeTo: configuration.host)?.absoluteURL else {
      throw PostHogAPIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(configuration.personalAPIKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(
      PostHogQueryBody(query: PostHogHogQLQuery(query: sql))
    )
    return request
  }
}

protocol PostHogQueryTransport: Sendable {
  func data(for request: URLRequest) async throws -> Data
}

struct URLSessionPostHogQueryTransport: PostHogQueryTransport {
  func data(for request: URLRequest) async throws -> Data {
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw PostHogAPIError.invalidResponse
    }
    guard (200..<300).contains(httpResponse.statusCode) else {
      throw Self.error(statusCode: httpResponse.statusCode)
    }
    return data
  }

  private static func error(statusCode: Int) -> PostHogAPIError {
    switch statusCode {
    case 401, 403:
      .unauthorized
    case 429:
      .rateLimited
    case 500...599:
      .server(statusCode: statusCode)
    default:
      .invalidResponse
    }
  }
}

actor FixturePostHogQueryTransport: PostHogQueryTransport {
  private var results: [Result<Data, Error>]

  init(responses: [String]) {
    self.results = responses.map { .success(Data($0.utf8)) }
  }

  init(results: [Result<Data, Error>]) {
    self.results = results
  }

  func data(for request: URLRequest) async throws -> Data {
    guard results.isEmpty == false else {
      return Data(#"{"results":[]}"#.utf8)
    }
    return try results.removeFirst().get()
  }
}

struct PostHogGrowthProvider: GrowthDashboardProviding {
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
      let dailyRows = try await dailyMetricRows(range: range, anchorDate: anchorDate)
      let topEventRows = try await topEventRows(range: range, anchorDate: anchorDate)
      return connectedSnapshot(
        projectID: projectID,
        range: range,
        anchorDate: anchorDate,
        dailyRows: dailyRows,
        topEventRows: topEventRows
      )
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

  private func dailyMetricRows(range: ActivityRange, anchorDate: Date) async throws -> [PostHogDailyMetricRow] {
    let request = try PostHogQueryRequest.query(
      configuration: configuration,
      sql: Self.dailyMetricsSQL(range: range, anchorDate: anchorDate)
    )
    let data = try await transport.data(for: request)
    return try PostHogQueryResponse(data: data).dailyMetricRows()
  }

  private func topEventRows(range: ActivityRange, anchorDate: Date) async throws -> [PostHogTopEventRow] {
    let request = try PostHogQueryRequest.query(
      configuration: configuration,
      sql: Self.topEventsSQL(range: range, anchorDate: anchorDate)
    )
    let data = try await transport.data(for: request)
    return try PostHogQueryResponse(data: data).topEventRows()
  }

  private func connectedSnapshot(
    projectID: GrowthProject.ID,
    range: ActivityRange,
    anchorDate: Date,
    dailyRows: [PostHogDailyMetricRow],
    topEventRows: [PostHogTopEventRow]
  ) -> GrowthDashboardSnapshot {
    var snapshot = baseSnapshot
    snapshot.project.id = projectID
    snapshot.range = range
    snapshot.anchorDate = anchorDate
    snapshot.connections = [
      GrowthConnection(
        id: "posthog-main",
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
    snapshot.metrics = metrics(from: dailyRows)
    snapshot.topEvents = topEventRows.map { row in
      GrowthListRow(
        id: row.event,
        title: row.event,
        detail: "PostHog event",
        value: Self.countFormatter.string(from: NSNumber(value: row.count)) ?? "\(row.count)"
      )
    }
    snapshot.topQueries = []
    snapshot.topPages = []
    snapshot.shippingContext = GrowthDashboardSnapshot.fixtureShippingContext(
      project: snapshot.project,
      range: range,
      anchorDate: anchorDate
    )
    snapshot.issues = []
    return snapshot
  }

  private func attentionSnapshot(
    projectID: GrowthProject.ID,
    range: ActivityRange,
    anchorDate: Date,
    message: String
  ) -> GrowthDashboardSnapshot {
    var snapshot = baseSnapshot
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

  private func metrics(from rows: [PostHogDailyMetricRow]) -> [GrowthMetric] {
    let activeUsers = rows.reduce(0) { $0 + $1.activeUsers }
    let eventCount = rows.reduce(0) { $0 + $1.eventCount }
    return [
      GrowthMetric(
        id: "posthog-active-users",
        provider: .postHog,
        kind: .activeUsers,
        title: "Active users",
        value: Double(activeUsers),
        formattedValue: Self.countFormatter.string(from: NSNumber(value: activeUsers)) ?? "\(activeUsers)",
        unit: .count,
        delta: nil,
        series: rows.map { GrowthMetricPoint(date: $0.date, value: Double($0.activeUsers)) }
      ),
      GrowthMetric(
        id: "posthog-events",
        provider: .postHog,
        kind: .keyEventCount,
        title: "Events",
        value: Double(eventCount),
        formattedValue: Self.countFormatter.string(from: NSNumber(value: eventCount)) ?? "\(eventCount)",
        unit: .count,
        delta: nil,
        series: rows.map { GrowthMetricPoint(date: $0.date, value: Double($0.eventCount)) }
      ),
    ]
  }

  private static func dailyMetricsSQL(range: ActivityRange, anchorDate: Date) -> String {
    let interval = dateInterval(range: range, anchorDate: anchorDate)
    return """
    SELECT toDate(timestamp) AS day, count(DISTINCT person_id) AS active_users, count() AS events
    FROM events
    WHERE timestamp >= toDateTime('\(interval.start)') AND timestamp < toDateTime('\(interval.end)')
    GROUP BY day
    ORDER BY day ASC
    """
  }

  private static func topEventsSQL(range: ActivityRange, anchorDate: Date) -> String {
    let interval = dateInterval(range: range, anchorDate: anchorDate)
    return """
    SELECT event, count() AS events
    FROM events
    WHERE timestamp >= toDateTime('\(interval.start)') AND timestamp < toDateTime('\(interval.end)')
    GROUP BY event
    ORDER BY events DESC
    LIMIT 5
    """
  }

  private static func dateInterval(range: ActivityRange, anchorDate: Date) -> (start: String, end: String) {
    let days = CalendarDay.days(endingAt: anchorDate, range: range)
    let start = days.first?.date ?? anchorDate
    let dayAfterEnd = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: days.last?.date ?? anchorDate) ?? anchorDate
    return (sqlDateFormatter.string(from: start), sqlDateFormatter.string(from: dayAfterEnd))
  }

  private static let sqlDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()

  private static let countFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter
  }()
}

private struct PostHogQueryBody: Encodable {
  var query: PostHogHogQLQuery
}

private struct PostHogHogQLQuery: Encodable {
  var kind = "HogQLQuery"
  var query: String
}

private struct PostHogDailyMetricRow: Equatable {
  var date: Date
  var activeUsers: Int
  var eventCount: Int
}

private struct PostHogTopEventRow: Equatable {
  var event: String
  var count: Int
}

private struct PostHogQueryResponse {
  var rows: [[PostHogJSONValue]]

  init(data: Data) throws {
    rows = try JSONDecoder().decode(PostHogQueryPayload.self, from: data).results
  }

  func dailyMetricRows() throws -> [PostHogDailyMetricRow] {
    try rows.map { row in
      guard row.count >= 3,
        let day = row[0].string,
        let date = Self.dayFormatter.date(from: day),
        let activeUsers = row[1].int,
        let eventCount = row[2].int
      else {
        throw PostHogAPIError.invalidResponse
      }
      return PostHogDailyMetricRow(date: date, activeUsers: activeUsers, eventCount: eventCount)
    }
  }

  func topEventRows() throws -> [PostHogTopEventRow] {
    try rows.map { row in
      guard row.count >= 2,
        let event = row[0].string,
        let count = row[1].int
      else {
        throw PostHogAPIError.invalidResponse
      }
      return PostHogTopEventRow(event: event, count: count)
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
}

private struct PostHogQueryPayload: Decodable {
  var results: [[PostHogJSONValue]]
}

private enum PostHogJSONValue: Decodable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Int.self) {
      self = .int(value)
    } else if let value = try? container.decode(Double.self) {
      self = .double(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else {
      throw PostHogAPIError.invalidResponse
    }
  }

  var string: String? {
    if case let .string(value) = self {
      return value
    }
    return nil
  }

  var int: Int? {
    switch self {
    case let .int(value):
      value
    case let .double(value):
      Int(value)
    case let .string(value):
      Int(value)
    case .bool, .null:
      nil
    }
  }
}
