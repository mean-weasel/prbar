import XCTest

@testable import PRMenuBar

final class PRActivityStoreTests: XCTestCase {
  func testSampleStoreSummarizesIncludedRepositories() {
    let store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )

    XCTAssertEqual(store.window, .oneWeek)
    XCTAssertEqual(store.bin, .day)
    XCTAssertEqual(store.totalPullRequests, 462)
    XCTAssertEqual(store.activeRepositoryCount, 10)
    XCTAssertEqual(store.statusTitle, "462 PRs")
    XCTAssertEqual(store.summaryText, "462 merged across 10 repos")
    XCTAssertEqual(store.bucketTotals, [62, 64, 65, 66, 66, 69, 70])
  }

  func testEmptyStoreHasCurrentBucketsWithoutSampleCounts() throws {
    let store = PRActivityStore.empty(
      now: try date("2026-05-04T20:00:00Z"),
      calendar: .prActivityUTC
    )

    XCTAssertEqual(store.window, .oneWeek)
    XCTAssertEqual(store.bin, .day)
    XCTAssertEqual(store.totalPullRequests, 0)
    XCTAssertEqual(store.activeRepositoryCount, 0)
    XCTAssertEqual(store.bucketTotals, [0, 0, 0, 0, 0, 0, 0])
    XCTAssertEqual(store.visibleBucketLabels.last, "05/04")
    XCTAssertEqual(store.refreshedAt, .distantPast)
  }

  func testEmptyStoreRefreshIsDueImmediately() throws {
    let store = PRActivityStore.empty(
      now: try date("2026-05-04T20:00:00Z"),
      calendar: .prActivityUTC
    )
    let policy = RefreshPolicy(interval: store.refreshInterval)

    XCTAssertTrue(
      policy.isRefreshDue(
        lastRefreshedAt: store.refreshedAt,
        now: try date("2026-05-04T20:00:01Z")
      )
    )
  }

  func testExcludedRepositoryDoesNotContributeToTotals() {
    let repositories = [
      RepositoryActivity(
        id: "owner/included",
        owner: "owner",
        name: "included",
        colorHex: "#ffffff",
        weeklyCounts: [3, 4],
        isIncluded: true
      ),
      RepositoryActivity(
        id: "owner/excluded",
        owner: "owner",
        name: "excluded",
        colorHex: "#000000",
        weeklyCounts: [99],
        isIncluded: false
      ),
    ]
    let store = PRActivityStore(
      bucketLabels: ["W1", "W2"],
      window: .twoWeeks,
      bin: .week,
      refreshInterval: .daily,
      repositories: repositories,
      refreshedAt: Date()
    )

    XCTAssertEqual(store.totalPullRequests, 7)
    XCTAssertEqual(store.activeRepositoryCount, 1)
  }

  func testWindowLimitsVisibleBuckets() {
    var store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )

    store.window = .oneMonth

    XCTAssertEqual(store.visibleBucketLabels.count, 30)
    XCTAssertEqual(store.visibleBucketLabels.first, "12/03")
    XCTAssertEqual(store.visibleBucketLabels.last, "01/01")
    XCTAssertEqual(
      store.bucketTotals,
      [
        18, 18, 17, 17, 17, 17, 18, 20, 22, 39, 41, 41, 41, 41, 41, 44, 26, 27, 28, 29,
        31, 32, 32, 62, 64, 65, 66, 66, 69, 70,
      ]
    )
  }

  func testMonthBinAggregatesVisibleBuckets() {
    var store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )

    store.window = .oneMonth
    store.bin = .month

    XCTAssertEqual(store.visibleBucketLabels.count, 1)
    XCTAssertEqual(store.bucketTotals, [1_119])
    XCTAssertEqual(store.totalPullRequests, 1_119)
  }

  func testDayBinShowsDailyBuckets() {
    var store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )

    store.window = .oneWeek
    store.bin = .day

    XCTAssertEqual(store.visibleBucketLabels.count, 7)
    XCTAssertEqual(store.bucketTotals.count, 7)
    XCTAssertEqual(
      store.repositories.first?.visibleCounts(for: store.window, bin: store.bin).count,
      7
    )
    XCTAssertEqual(store.totalPullRequests, 462)
  }

  func testWeekBinUsesRollingSevenDayWindowsWhenDailyBucketsAreAvailable() throws {
    let store = PRActivityStore(
      bucketLabels: ["05/03", "05/10", "05/17", "05/24"],
      dailyBucketLabels: [
        "05/14", "05/15", "05/16", "05/17", "05/18", "05/19", "05/20",
        "05/21", "05/22", "05/23", "05/24", "05/25", "05/26", "05/27",
      ],
      window: .twoWeeks,
      bin: .week,
      refreshInterval: .daily,
      repositories: [
        RepositoryActivity(
          id: "owner/repo",
          owner: "owner",
          name: "repo",
          colorHex: "#ffffff",
          weeklyCounts: [100, 100, 100, 100],
          dailyCounts: [1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2],
          isIncluded: true
        )
      ],
      refreshedAt: try date("2026-05-27T12:00:00Z")
    )

    XCTAssertEqual(store.visibleBucketLabels, ["05/14-05/20", "05/21-05/27"])
    XCTAssertEqual(store.bucketTotals, [7, 14])
    XCTAssertEqual(store.totalPullRequests, 21)
  }

  func testMonthBinUsesRollingThirtyDayWindowWhenDailyBucketsAreAvailable() throws {
    let dailyLabels = (1...31).map { day in "05/\(String(format: "%02d", day))" }
    let dailyCounts = Array(repeating: 100, count: 1) + Array(repeating: 1, count: 30)
    let store = PRActivityStore(
      bucketLabels: ["05/03", "05/10", "05/17", "05/24"],
      dailyBucketLabels: dailyLabels,
      window: .oneMonth,
      bin: .month,
      refreshInterval: .daily,
      repositories: [
        RepositoryActivity(
          id: "owner/repo",
          owner: "owner",
          name: "repo",
          colorHex: "#ffffff",
          weeklyCounts: [100, 100, 100, 100],
          dailyCounts: dailyCounts,
          isIncluded: true
        )
      ],
      refreshedAt: try date("2026-05-31T12:00:00Z")
    )

    XCTAssertEqual(store.visibleBucketLabels, ["05/02-05/31"])
    XCTAssertEqual(store.bucketTotals, [30])
    XCTAssertEqual(store.totalPullRequests, 30)
  }

  func testSettingsSnapshotCanBeApplied() {
    let store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )
    let settings = PRSettingsSnapshot(
      window: .oneMonth,
      bin: .month,
      refreshInterval: .manual,
      includedRepositoryIDs: ["mean-weasel/deckchecker", "neonwatty/RedditReminder"],
      knownRepositoryIDs: store.repositories.map(\.id)
    )

    let updated = store.applying(settings)

    XCTAssertEqual(updated.window, .oneMonth)
    XCTAssertEqual(updated.bin, .month)
    XCTAssertEqual(updated.refreshInterval, .manual)
    XCTAssertEqual(updated.activeRepositoryCount, 2)
    XCTAssertEqual(updated.totalPullRequests, 359)
    XCTAssertEqual(updated.settingsSnapshot, settings)
  }

  func testApplyingSettingsKeepsNewlyDiscoveredRepositoriesIncluded() {
    let repositories = [
      RepositoryActivity(
        id: "owner/known",
        owner: "owner",
        name: "known",
        colorHex: "#ffffff",
        weeklyCounts: [1],
        isIncluded: true
      ),
      RepositoryActivity(
        id: "owner/new",
        owner: "owner",
        name: "new",
        colorHex: "#000000",
        weeklyCounts: [1],
        isIncluded: true
      ),
    ]
    let store = PRActivityStore(
      bucketLabels: ["W1"],
      window: .twoWeeks,
      bin: .week,
      refreshInterval: .daily,
      repositories: repositories,
      refreshedAt: Date()
    )
    let settings = PRSettingsSnapshot(
      window: .twoWeeks,
      includedRepositoryIDs: [],
      knownRepositoryIDs: ["owner/known"]
    )

    let updated = store.applying(settings)

    XCTAssertFalse(updated.repositories[0].isIncluded)
    XCTAssertTrue(updated.repositories[1].isIncluded)
  }

  func testSettingsSnapshotPrunesStaleKnownRepositoriesAfterRefresh() {
    let repositories = [
      RepositoryActivity(
        id: "owner/remaining",
        owner: "owner",
        name: "remaining",
        colorHex: "#ffffff",
        weeklyCounts: [1],
        isIncluded: true
      )
    ]
    let store = PRActivityStore(
      bucketLabels: ["W1"],
      window: .twoWeeks,
      bin: .week,
      refreshInterval: .daily,
      repositories: repositories,
      refreshedAt: Date()
    )
    let settings = PRSettingsSnapshot(
      window: .twoWeeks,
      includedRepositoryIDs: ["owner/remaining"],
      knownRepositoryIDs: ["owner/remaining", "owner/removed"]
    )

    let updated = store.applying(settings)

    XCTAssertEqual(updated.settingsSnapshot.knownRepositoryIDs, ["owner/remaining"])
    XCTAssertEqual(updated.settingsSnapshot.includedRepositoryIDs, ["owner/remaining"])
  }

  func testBucketBreakdownSortsNonZeroRepoValues() {
    let store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )
    let breakdown = store.bucketBreakdown(at: 6)

    XCTAssertEqual(breakdown.first?.repository.id, "mean-weasel/deckchecker")
    XCTAssertEqual(breakdown.first?.value, 16)
    XCTAssertFalse(breakdown.contains { $0.value == 0 })
  }

  func testIncludeAllRepositoriesRecoversVisibleActivity() {
    var store = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )
    store.repositories = store.repositories.map { repository in
      var updated = repository
      updated.isIncluded = false
      return updated
    }

    XCTAssertFalse(store.hasVisibleActivity)

    store.includeAllRepositories()

    XCTAssertTrue(store.hasVisibleActivity)
    XCTAssertEqual(store.activeRepositoryCount, 10)
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
