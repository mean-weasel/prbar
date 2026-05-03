import Foundation

struct PRActivityStore {
  var bucketLabels: [String]
  var dailyBucketLabels: [String]
  var window: ActivityWindow
  var bin: ActivityBin
  var refreshInterval: AutoRefreshInterval
  var repositories: [RepositoryActivity]
  var refreshedAt: Date

  init(
    bucketLabels: [String],
    dailyBucketLabels: [String] = [],
    window: ActivityWindow,
    bin: ActivityBin = .week,
    refreshInterval: AutoRefreshInterval,
    repositories: [RepositoryActivity],
    refreshedAt: Date
  ) {
    self.bucketLabels = bucketLabels
    self.dailyBucketLabels = dailyBucketLabels
    self.window = window
    self.bin = bin
    self.refreshInterval = refreshInterval
    self.repositories = repositories
    self.refreshedAt = refreshedAt
  }

  var visibleBucketLabels: [String] {
    switch bin {
    case .day:
      guard dailyBucketLabels.isEmpty == false else {
        return Array(bucketLabels.suffix(window.visibleBucketCount))
      }
      return Array(dailyBucketLabels.suffix(window.dayCount))
    case .week:
      return Array(bucketLabels.suffix(window.visibleBucketCount))
    case .month:
      guard dailyBucketLabels.isEmpty == false else {
        return Array(bucketLabels.suffix(window.visibleBucketCount)).groupedLabels(size: 4)
      }
      return Array(dailyBucketLabels.suffix(window.dayCount)).rangeLabel()
    }
  }

  var includedRepositories: [RepositoryActivity] {
    repositories.filter(\.isIncluded)
  }

  var totalPullRequests: Int {
    includedRepositories.reduce(0) { $0 + $1.visibleTotal(for: window, bin: bin) }
  }

  var activeRepositoryCount: Int {
    includedRepositories.filter { $0.visibleTotal(for: window, bin: bin) > 0 }.count
  }

  var bucketTotals: [Int] {
    visibleBucketLabels.indices.map { index in
      includedRepositories.reduce(0) { sum, repository in
        sum + repository.visibleCounts(for: window, bin: bin)[index]
      }
    }
  }

  var maxBucketTotal: Int {
    max(bucketTotals.max() ?? 0, 1)
  }

  var hasVisibleActivity: Bool {
    totalPullRequests > 0
  }

  mutating func includeAllRepositories() {
    repositories = repositories.map { repository in
      var updated = repository
      updated.isIncluded = true
      return updated
    }
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
          value: repository.visibleCounts(for: window, bin: bin)[index]
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
      bin: bin,
      refreshInterval: refreshInterval,
      includedRepositoryIDs: repositories.filter(\.isIncluded).map(\.id),
      knownRepositoryIDs: repositories.map(\.id)
    )
  }

  func applying(_ settings: PRSettingsSnapshot) -> PRActivityStore {
    let included = Set(settings.includedRepositoryIDs)
    let known = Set(settings.knownRepositoryIDs)
    var copy = self
    copy.window = settings.window
    copy.bin = settings.bin
    copy.refreshInterval = settings.refreshInterval
    copy.repositories = repositories.map { repository in
      var updated = repository
      if known.contains(repository.id) {
        updated.isIncluded = included.contains(repository.id)
      }
      return updated
    }
    return copy
  }

  static func sample(now: Date = Date()) -> PRActivityStore {
    PRActivityStore(
      bucketLabels: [
        "03/02", "03/09", "03/16", "03/23", "03/30", "04/06", "04/13", "04/20", "04/27",
      ],
      dailyBucketLabels: PRActivityBucketSeries.daily(
        mergedDates: [],
        bucketCount: 63,
        now: now
      )
      .labels,
      window: .twoWeeks,
      bin: .week,
      refreshInterval: .daily,
      repositories: RepositoryActivity.samples.map { $0.withDistributedDailyCounts() },
      refreshedAt: now
    )
  }
}

extension Array where Element == String {
  func groupedLabels(size: Int) -> [String] {
    guard size > 1 else {
      return self
    }
    return stride(from: 0, to: count, by: size).map { start in
      let group = self[start..<Swift.min(start + size, count)]
      guard let first = group.first, let last = group.last, first != last else {
        return group.first ?? ""
      }
      return "\(first)-\(last)"
    }
  }

  func rangeLabel() -> [String] {
    guard let first, let last, first != last else {
      return first.map { [$0] } ?? []
    }
    return ["\(first)-\(last)"]
  }
}
