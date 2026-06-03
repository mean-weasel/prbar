import Foundation

enum GrowthRefreshStatus: Equatable, Sendable {
  case idle
  case loading(message: String)
  case loaded(lastRefreshedAt: Date, source: GrowthDataSource)
  case failed(message: String)

  var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }
}
