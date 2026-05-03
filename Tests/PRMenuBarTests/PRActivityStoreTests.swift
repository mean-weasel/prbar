import XCTest

@testable import PRMenuBar

final class PRActivityStoreTests: XCTestCase {
  func testSampleStoreSummarizesIncludedRepositories() {
    let store = PRActivityStore.sample(now: Date(timeIntervalSince1970: 0))

    XCTAssertEqual(store.totalPullRequests, 370)
    XCTAssertEqual(store.activeRepositoryCount, 3)
    XCTAssertEqual(store.statusTitle, "370 PRs")
    XCTAssertEqual(store.summaryText, "370 merged across 3 repos")
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
    let store = PRActivityStore(window: .twoWeeks, repositories: repositories, refreshedAt: Date())

    XCTAssertEqual(store.totalPullRequests, 7)
    XCTAssertEqual(store.activeRepositoryCount, 1)
  }
}
