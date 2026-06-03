import Foundation

struct PostHogDashboardDailySeries: Equatable, Sendable {
  var day: Date
  var visitors: Double
  var pageviews: Double
}

enum PostHogDashboardDailySeriesQuery {
  static func request(
    configuration: PostHogConfiguration,
    range: ActivityRange,
    anchorDate: Date
  ) throws -> URLRequest {
    try PostHogQueryRequest.query(
      configuration: configuration,
      sql: sql(range: range, anchorDate: anchorDate)
    )
  }

  static func decode(_ data: Data) throws -> [PostHogDashboardDailySeries] {
    try PostHogQueryResponse(data: data).dashboardDailySeriesRows()
  }

  private static func sql(range: ActivityRange, anchorDate: Date) -> String {
    let interval = dateInterval(range: range, anchorDate: anchorDate)
    let bucketCount = max(1, calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1)
    let startDay = sqlDayFormatter.string(from: interval.start)
    let start = sqlDateTimeFormatter.string(from: interval.start)
    let end = sqlDateTimeFormatter.string(from: interval.end)

    return """
    WITH toDate('\(startDay)') AS start_day
    SELECT toString(days.day) AS day, coalesce(metrics.visitors, 0) AS visitors, coalesce(metrics.pageviews, 0) AS pageviews
    FROM (
      SELECT start_day + number AS day
      FROM numbers(\(bucketCount))
    ) AS days
    LEFT JOIN (
      SELECT toDate(timestamp) AS day, count(DISTINCT person_id) AS visitors, count() AS pageviews
      FROM events
      WHERE event = '$pageview'
        AND timestamp >= toDateTime('\(start)')
        AND timestamp < toDateTime('\(end)')
      GROUP BY day
    ) AS metrics ON metrics.day = days.day
    ORDER BY days.day ASC
    """
  }

  private static func dateInterval(range: ActivityRange, anchorDate: Date) -> (start: Date, end: Date) {
    let days = CalendarDay.days(endingAt: anchorDate, range: range)
    let start = days.first?.date ?? anchorDate
    let end = calendar.date(byAdding: .day, value: 1, to: days.last?.date ?? anchorDate) ?? anchorDate
    return (start, end)
  }

  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()

  private static let sqlDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private static let sqlDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()
}
