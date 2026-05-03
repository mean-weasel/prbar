import XCTest

@testable import PRMenuBar

final class PRActivityProviderTests: XCTestCase {
  func testJSONProviderLoadsStore() throws {
    let json = """
      {
        "bucketLabels": ["W1", "W2"],
        "defaultWindow": "2 weeks",
        "repositories": [
          {
            "id": "owner/repo",
            "owner": "owner",
            "name": "repo",
            "colorHex": "#ffffff",
            "weeklyCounts": [2, 5],
            "isIncluded": true
          }
        ]
      }
      """
    let provider = JSONPRActivityProvider(data: Data(json.utf8))

    let store = try provider.load(now: Date(timeIntervalSince1970: 0))

    XCTAssertEqual(store.visibleBucketLabels, ["W1", "W2"])
    XCTAssertEqual(store.totalPullRequests, 7)
    XCTAssertEqual(store.refreshedAt, Date(timeIntervalSince1970: 0))
  }

  func testJSONProviderRejectsInvalidPayload() {
    let provider = JSONPRActivityProvider(data: Data("{}".utf8))

    XCTAssertThrowsError(try provider.load(now: Date(timeIntervalSince1970: 0)))
  }
}
