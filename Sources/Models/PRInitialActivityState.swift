import Foundation

struct PRInitialActivityState {
  var store: PRActivityStore
  var refreshError: String?

  static func load(
    providerSelection: PRActivityProviderSelection,
    now: Date = Date()
  ) -> PRInitialActivityState {
    do {
      return PRInitialActivityState(
        store: try providerSelection.provider.load(now: now),
        refreshError: nil
      )
    } catch {
      let store =
        providerSelection.dataSource == .sample
        ? PRActivityStore.sample(now: now)
        : PRActivityStore.empty(now: now)
      let refreshError =
        providerSelection.dataSource == .github
        ? RefreshFailureMessage.scheduled(error: error)
        : nil
      return PRInitialActivityState(store: store, refreshError: refreshError)
    }
  }
}
