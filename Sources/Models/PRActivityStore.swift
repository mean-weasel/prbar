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

  var statusTitle: String {
    "\(totalPullRequests) PRs"
  }

  var summaryText: String {
    "\(totalPullRequests) merged across \(activeRepositoryCount) repos"
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
