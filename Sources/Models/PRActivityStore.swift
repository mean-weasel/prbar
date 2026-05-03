import Foundation

struct PRActivityStore {
  var window: ActivityWindow
  var repositories: [RepositoryActivity]
  var refreshedAt: Date

  var totalPullRequests: Int {
    repositories.reduce(0) { $0 + $1.total }
  }

  var activeRepositoryCount: Int {
    repositories.filter { $0.total > 0 }.count
  }

  var statusTitle: String {
    "\(totalPullRequests) PRs"
  }

  var summaryText: String {
    "\(totalPullRequests) merged across \(activeRepositoryCount) repos"
  }

  static func sample(now: Date = Date()) -> PRActivityStore {
    PRActivityStore(
      window: .twoWeeks,
      repositories: RepositoryActivity.samples,
      refreshedAt: now
    )
  }
}
