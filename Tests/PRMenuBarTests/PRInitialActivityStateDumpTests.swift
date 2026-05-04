import XCTest

@testable import PRMenuBar

final class PRInitialActivityStateDumpTests: XCTestCase {
  func testWriteIfRequestedPersistsInitialStateSummary() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("json")
    defer {
      try? FileManager.default.removeItem(at: url)
    }
    let store = PRActivityStore(
      bucketLabels: ["04/26"],
      dailyBucketLabels: ["04/29", "04/30", "05/01", "05/02", "05/03", "05/04", "05/05"],
      window: .oneWeek,
      bin: .day,
      refreshInterval: .daily,
      repositories: [
        RepositoryActivity(
          id: "mean-weasel/deckchecker",
          owner: "mean-weasel",
          name: "deckchecker",
          colorHex: "#ffffff",
          weeklyCounts: [9],
          dailyCounts: [0, 0, 0, 0, 0, 9, 0],
          isIncluded: true
        )
      ],
      refreshedAt: try date("2026-05-04T20:00:00Z")
    )

    PRInitialActivityStateDump.writeIfRequested(
      state: PRInitialActivityState(store: store, refreshError: nil),
      dataSource: .github,
      environment: [PRInitialActivityStateDump.pathEnvironmentKey: url.path]
    )

    let payload = try decodedPayload(at: url)
    XCTAssertEqual(payload["dataSourceTitle"] as? String, "GitHub")
    XCTAssertEqual(payload["totalPullRequests"] as? Int, 9)
    XCTAssertEqual(payload["activeRepositoryCount"] as? Int, 1)
    XCTAssertEqual(payload["bucketTotals"] as? [Int], [0, 0, 0, 0, 0, 9, 0])
    XCTAssertEqual(payload["refreshError"] as? String, nil)
  }

  private func decodedPayload(at url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    let json = try JSONSerialization.jsonObject(with: data)
    return try XCTUnwrap(json as? [String: Any])
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
