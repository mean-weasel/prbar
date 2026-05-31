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

  func testDailyLabelsFallBackWhenIncludedRepositoriesLackDailyCounts() {
    var store = PRActivityStore(
      bucketLabels: ["W1", "W2", "W3", "W4"],
      dailyBucketLabels: (1...30).map { "D\($0)" },
      window: .oneMonth,
      bin: .week,
      refreshInterval: .daily,
      repositories: [
        RepositoryActivity(
          id: "owner/legacy",
          owner: "owner",
          name: "legacy",
          colorHex: "#ffffff",
          weeklyCounts: [1, 2, 3, 4],
          isIncluded: true
        )
      ],
      refreshedAt: Date()
    )

    XCTAssertEqual(store.visibleBucketLabels, ["W1", "W2", "W3", "W4"])
    XCTAssertEqual(store.bucketTotals, [1, 2, 3, 4])
    XCTAssertEqual(store.totalPullRequests, 10)
    XCTAssertEqual(store.bucketBreakdown(at: 3).first?.value, 4)

    let payload = ShareCardBuilder.prActivityPayload(store: store)

    XCTAssertEqual(payload.chartBuckets.map(\.label), ["W1", "W2", "W3", "W4"])
    XCTAssertEqual(payload.chartBuckets.map(\.total), [1, 2, 3, 4])
    XCTAssertEqual(payload.repoRows.first?.count, 10)

    store.bin = .month

    XCTAssertEqual(store.visibleBucketLabels, ["W1-W4"])
    XCTAssertEqual(store.bucketTotals, [10])
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

  func testApplyingSettingsExcludesNewlyDiscoveredRepositoriesByDefault() {
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
    XCTAssertFalse(updated.repositories[1].isIncluded)
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
