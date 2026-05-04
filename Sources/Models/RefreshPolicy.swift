import Foundation

struct RefreshPolicy {
  var interval: AutoRefreshInterval
  var calendar: Calendar = .prActivity

  func isRefreshDue(lastRefreshedAt: Date, now: Date) -> Bool {
    switch interval {
    case .manual:
      return false
    case .daily:
      return calendar.isDate(lastRefreshedAt, inSameDayAs: now) == false
        || now.timeIntervalSince(lastRefreshedAt) >= 86_400
    }
  }

  func nextRefreshDate(lastRefreshedAt: Date) -> Date? {
    switch interval {
    case .manual:
      return nil
    case .daily:
      return calendar.date(
        byAdding: .day,
        value: 1,
        to: calendar.startOfDay(for: lastRefreshedAt)
      )
    }
  }
}
