import Foundation

struct PRActivityRefresher {
  var provider: PRActivityProviding

  func refresh(current store: PRActivityStore, now: Date = Date()) throws -> PRActivityStore {
    let settings = store.settingsSnapshot
    return try provider.load(now: now).applying(settings)
  }

  func refreshIfDue(current store: PRActivityStore, now: Date = Date()) throws -> PRActivityStore? {
    let policy = RefreshPolicy(interval: store.refreshInterval)
    guard policy.isRefreshDue(lastRefreshedAt: store.refreshedAt, now: now) else {
      return nil
    }
    return try refresh(current: store, now: now)
  }
}
