import XCTest

@testable import PRMenuBar

final class PRActivityRollingWindowTests: XCTestCase {
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

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
