import Foundation

struct RefreshPolicy {
  var interval: AutoRefreshInterval

  func isRefreshDue(lastRefreshedAt: Date, now: Date) -> Bool {
    switch interval {
    case .manual:
      return false
    case .daily:
      return Calendar.prActivity.isDate(lastRefreshedAt, inSameDayAs: now) == false
        || now.timeIntervalSince(lastRefreshedAt) >= 86_400
    }
  }

  func nextRefreshDate(lastRefreshedAt: Date) -> Date? {
    switch interval {
    case .manual:
      return nil
    case .daily:
      let calendar = Calendar.prActivity
      return calendar.date(
        byAdding: .day,
        value: 1,
        to: calendar.startOfDay(for: lastRefreshedAt)
      )
    }
  }
}
