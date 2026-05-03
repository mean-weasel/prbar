import Foundation

struct PRActivityStore {
  var bucketLabels: [String]
  var window: ActivityWindow
  var repositories: [RepositoryActivity]
  var refreshedAt: Date

  var visibleBucketLabels: [String] {
    Array(bucketLabels.suffix(window.visibleBucketCount))
  }

  var includedRepositories: [RepositoryActivity] {
    repositories.filter(\.isIncluded)
  }

  var totalPullRequests: Int {
    includedRepositories.reduce(0) { $0 + $1.visibleTotal(for: window) }
  }

  var activeRepositoryCount: Int {
    includedRepositories.filter { $0.visibleTotal(for: window) > 0 }.count
  }

  var bucketTotals: [Int] {
    visibleBucketLabels.indices.map { index in
      includedRepositories.reduce(0) { sum, repository in
        sum + repository.visibleCounts(for: window)[index]
      }
    }
  }

  var maxBucketTotal: Int {
    max(bucketTotals.max() ?? 0, 1)
  }

  func bucketBreakdown(at index: Int) -> [RepositoryBucketValue] {
    guard visibleBucketLabels.indices.contains(index) else {
      return []
    }
    return
      includedRepositories
      .map { repository in
        RepositoryBucketValue(
          repository: repository,
          value: repository.visibleCounts(for: window)[index]
        )
      }
      .filter { $0.value > 0 }
      .sorted { $0.value > $1.value }
  }

  var statusTitle: String {
    "\(totalPullRequests) PRs"
  }

  var summaryText: String {
    "\(totalPullRequests) merged across \(activeRepositoryCount) repos"
  }

  var settingsSnapshot: PRSettingsSnapshot {
    PRSettingsSnapshot(
      window: window,
      includedRepositoryIDs: repositories.filter(\.isIncluded).map(\.id)
    )
  }

  func applying(_ settings: PRSettingsSnapshot) -> PRActivityStore {
    let included = Set(settings.includedRepositoryIDs)
    var copy = self
    copy.window = settings.window
    copy.repositories = repositories.map { repository in
      var updated = repository
      updated.isIncluded = included.contains(repository.id)
      return updated
    }
    return copy
  }

  static func sample(now: Date = Date()) -> PRActivityStore {
    PRActivityStore(
      bucketLabels: [
        "03/02", "03/09", "03/16", "03/23", "03/30", "04/06", "04/13", "04/20", "04/27",
      ],
      window: .twoWeeks,
      repositories: RepositoryActivity.samples,
      refreshedAt: now
    )
  }
}
