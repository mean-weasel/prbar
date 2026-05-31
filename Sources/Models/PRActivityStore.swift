import Foundation

struct PRActivityStore: Codable {
  var bucketLabels: [String]
  var dailyBucketLabels: [String]
  var window: ActivityWindow
  var bin: ActivityBin
  var refreshInterval: AutoRefreshInterval
  var showPrivateRepositoryNamesInShare: Bool
  var repositories: [RepositoryActivity]
  var refreshedAt: Date

  init(
    bucketLabels: [String],
    dailyBucketLabels: [String] = [],
    window: ActivityWindow,
    bin: ActivityBin = .week,
    refreshInterval: AutoRefreshInterval,
    showPrivateRepositoryNamesInShare: Bool = false,
    repositories: [RepositoryActivity],
    refreshedAt: Date
  ) {
    self.bucketLabels = bucketLabels
    self.dailyBucketLabels = dailyBucketLabels
    self.window = window
    self.bin = bin
    self.refreshInterval = refreshInterval
    self.showPrivateRepositoryNamesInShare = showPrivateRepositoryNamesInShare
    self.repositories = repositories
    self.refreshedAt = refreshedAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    bucketLabels = try container.decode([String].self, forKey: .bucketLabels)
    dailyBucketLabels =
      try container.decodeIfPresent([String].self, forKey: .dailyBucketLabels) ?? []
    window = try container.decode(ActivityWindow.self, forKey: .window)
    bin = try container.decodeIfPresent(ActivityBin.self, forKey: .bin) ?? .week
    refreshInterval =
      try container.decodeIfPresent(AutoRefreshInterval.self, forKey: .refreshInterval) ?? .daily
    showPrivateRepositoryNamesInShare =
      try container.decodeIfPresent(Bool.self, forKey: .showPrivateRepositoryNamesInShare)
      ?? false
    repositories = try container.decode([RepositoryActivity].self, forKey: .repositories)
    refreshedAt = try container.decode(Date.self, forKey: .refreshedAt)
  }

  var visibleBucketLabels: [String] {
    switch bin {
    case .day:
      guard usesDailyBucketsForVisibleData else {
        return Array(bucketLabels.suffix(window.visibleBucketCount))
      }
      return Array(dailyBucketLabels.suffix(window.dayCount))
    case .week:
      guard usesDailyBucketsForVisibleData else {
        return Array(bucketLabels.suffix(window.visibleBucketCount))
      }
      return Array(dailyBucketLabels.suffix(window.dayCount)).groupedLabels(size: 7)
    case .month:
      guard usesDailyBucketsForVisibleData else {
        return Array(bucketLabels.suffix(window.visibleBucketCount)).groupedLabels(size: 4)
      }
      return Array(dailyBucketLabels.suffix(window.dayCount)).rangeLabel()
    }
  }

  var includedRepositories: [RepositoryActivity] {
    repositories.filter(\.isIncluded)
  }

  var totalPullRequests: Int {
    includedRepositories.reduce(0) { $0 + visibleTotal(for: $1) }
  }

  var activeRepositoryCount: Int {
    includedRepositories.filter { visibleTotal(for: $0) > 0 }.count
  }

  var bucketTotals: [Int] {
    visibleBucketLabels.indices.map { index in
      includedRepositories.reduce(0) { sum, repository in
        sum + visibleCounts(for: repository)[index]
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

  func repositoryIndices(matching query: String) -> [Int] {
    repositories.indices.filter { index in
      repositories[index].matchesSearch(query)
    }
  }

  mutating func setRepositoriesIncluded(_ isIncluded: Bool, matching query: String) {
    for index in repositoryIndices(matching: query) {
      repositories[index].isIncluded = isIncluded
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
          value: visibleCounts(for: repository)[index]
        )
      }
      .filter { $0.value > 0 }
      .sorted { $0.value > $1.value }
  }

  func visibleCounts(for repository: RepositoryActivity) -> [Int] {
    guard usesDailyBucketsForVisibleData else {
      var fallback = repository
      fallback.dailyCounts = []
      return fallback.visibleCounts(for: window, bin: bin)
    }
    return repository.visibleCounts(for: window, bin: bin)
  }

  func visibleTotal(for repository: RepositoryActivity) -> Int {
    guard repository.isIncluded else {
      return 0
    }
    return visibleCounts(for: repository).reduce(0, +)
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
      showPrivateRepositoryNamesInShare: showPrivateRepositoryNamesInShare,
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
    copy.showPrivateRepositoryNamesInShare = settings.showPrivateRepositoryNamesInShare
    copy.repositories = repositories.map { repository in
      var updated = repository
      updated.isIncluded = known.contains(repository.id) && included.contains(repository.id)
      return updated
    }
    return copy
  }

  private var usesDailyBucketsForVisibleData: Bool {
    guard dailyBucketLabels.isEmpty == false else {
      return false
    }
    return includedRepositories.allSatisfy { $0.dailyCounts.count == dailyBucketLabels.count }
  }

  static func sample(
    now: Date = Date(),
    calendar: Calendar = .prActivity
  ) -> PRActivityStore {
    PRActivityStore(
      bucketLabels: [
        "03/02", "03/09", "03/16", "03/23", "03/30", "04/06", "04/13", "04/20", "04/27",
      ],
      dailyBucketLabels: PRActivityBucketSeries.daily(
        mergedDates: [],
        bucketCount: 63,
        now: now,
        calendar: calendar
      )
      .labels,
      window: .oneWeek,
      bin: .day,
      refreshInterval: .daily,
      repositories: RepositoryActivity.samples.map { $0.withDistributedDailyCounts() },
      refreshedAt: now
    )
  }

  static func empty(
    now: Date = Date(),
    refreshedAt: Date = .distantPast,
    calendar: Calendar = .prActivity
  ) -> PRActivityStore {
    PRActivityStore(
      bucketLabels: PRActivityBucketSeries.weekly(
        mergedDates: [],
        bucketCount: 9,
        now: now,
        calendar: calendar
      )
      .labels,
      dailyBucketLabels: PRActivityBucketSeries.daily(
        mergedDates: [],
        bucketCount: 30,
        now: now,
        calendar: calendar
      )
      .labels,
      window: .oneWeek,
      bin: .day,
      refreshInterval: .daily,
      repositories: [],
      refreshedAt: refreshedAt
    )
  }
}

extension PRActivityStore {
  fileprivate enum CodingKeys: String, CodingKey {
    case bucketLabels
    case dailyBucketLabels
    case window
    case bin
    case refreshInterval
    case showPrivateRepositoryNamesInShare
    case repositories
    case refreshedAt
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
