import Foundation

protocol GrowthDashboardProviding: Sendable {
  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot
}

enum GrowthProviderError: LocalizedError, Equatable {
  case providerUnavailable(String)

  var errorDescription: String? {
    switch self {
    case let .providerUnavailable(message): message
    }
  }
}

struct StaticGrowthDashboardProvider: GrowthDashboardProviding {
  var snapshot: GrowthDashboardSnapshot

  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot {
    var updated = snapshot
    updated.project.id = projectID
    updated.range = range
    updated.anchorDate = anchorDate
    return updated
  }
}

struct FailingGrowthDashboardProvider: GrowthDashboardProviding {
  var error: GrowthProviderError

  func dashboard(projectID: GrowthProject.ID, range: ActivityRange, anchorDate: Date) async throws -> GrowthDashboardSnapshot {
    throw error
  }
}
