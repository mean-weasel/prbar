import Foundation

struct RefreshPolicy {
  var interval: AutoRefreshInterval

  func isRefreshDue(lastRefreshedAt: Date, now: Date) -> Bool {
    guard let duration = interval.duration else {
      return false
    }
    return now.timeIntervalSince(lastRefreshedAt) >= duration
  }
}
