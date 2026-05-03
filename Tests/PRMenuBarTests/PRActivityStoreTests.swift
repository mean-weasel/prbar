import XCTest

@testable import PRMenuBar

final class PRActivityStoreTests: XCTestCase {
  func testSampleStoreSummarizesIncludedRepositories() {
    let store = PRActivityStore.sample(now: Date(timeIntervalSince1970: 0))

    XCTAssertEqual(store.totalPullRequests, 667)
    XCTAssertEqual(store.activeRepositoryCount, 11)
    XCTAssertEqual(store.statusTitle, "667 PRs")
    XCTAssertEqual(store.summaryText, "667 merged across 11 repos")
    XCTAssertEqual(store.bucketTotals, [205, 462])
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
      repositories: repositories,
      refreshedAt: Date()
    )

    XCTAssertEqual(store.totalPullRequests, 7)
    XCTAssertEqual(store.activeRepositoryCount, 1)
  }

  func testWindowLimitsVisibleBuckets() {
    var store = PRActivityStore.sample(now: Date(timeIntervalSince1970: 0))

    store.window = .oneMonth

    XCTAssertEqual(store.visibleBucketLabels, ["04/06", "04/13", "04/20", "04/27"])
    XCTAssertEqual(store.bucketTotals, [128, 288, 205, 462])
  }
}
