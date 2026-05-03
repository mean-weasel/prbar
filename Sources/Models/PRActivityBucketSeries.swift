import Foundation

struct PRActivityBucketSeries: Equatable {
  var labels: [String]
  var counts: [Int]

  static func weekly(
    mergedDates: [Date],
    bucketCount: Int,
    now: Date,
    calendar: Calendar = .prActivity
  ) -> PRActivityBucketSeries {
    let starts = weekStarts(bucketCount: bucketCount, now: now, calendar: calendar)
    let counts = starts.map { start in
      let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
      return mergedDates.filter { $0 >= start && $0 < end }.count
    }
    return PRActivityBucketSeries(
      labels: starts.map { Self.label(for: $0) },
      counts: counts
    )
  }

  static func daily(
    mergedDates: [Date],
    bucketCount: Int,
    now: Date,
    calendar: Calendar = .prActivity
  ) -> PRActivityBucketSeries {
    let starts = dayStarts(bucketCount: bucketCount, now: now, calendar: calendar)
    let counts = starts.map { start in
      let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
      return mergedDates.filter { $0 >= start && $0 < end }.count
    }
    return PRActivityBucketSeries(
      labels: starts.map { Self.label(for: $0) },
      counts: counts
    )
  }

  private static func weekStarts(bucketCount: Int, now: Date, calendar: Calendar) -> [Date] {
    let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
    return (0..<bucketCount).reversed().compactMap { offset in
      calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeek)
    }
  }

  private static func dayStarts(bucketCount: Int, now: Date, calendar: Calendar) -> [Date] {
    let currentDay = calendar.startOfDay(for: now)
    return (0..<bucketCount).reversed().compactMap { offset in
      calendar.date(byAdding: .day, value: -offset, to: currentDay)
    }
  }

  private static func label(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = .prActivity
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MM/dd"
    return formatter.string(from: date)
  }
}

extension Calendar {
  static var prActivity: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 1
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    return calendar
  }
}
