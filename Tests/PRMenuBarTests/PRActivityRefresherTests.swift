import XCTest

@testable import PRMenuBar

final class PRActivityRefresherTests: XCTestCase {
  func testRefreshPreservesCurrentSettings() throws {
    var current = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )
    current.window = .oneMonth
    current.refreshInterval = .manual
    current.repositories[0].isIncluded = false
    let provider = JSONPRActivityProvider(
      data: try jsonData(repositoryID: current.repositories[0].id)
    )
    let refresher = PRActivityRefresher(provider: provider)

    let refreshed = try refresher.refresh(
      current: current,
      now: Date(timeIntervalSince1970: 100)
    )

    XCTAssertEqual(refreshed.window, .oneMonth)
    XCTAssertEqual(refreshed.refreshInterval, .manual)
    XCTAssertFalse(try XCTUnwrap(refreshed.repositories.first).isIncluded)
    XCTAssertEqual(refreshed.refreshedAt, Date(timeIntervalSince1970: 100))
  }

  func testRefreshIfDueReturnsNilWhenPolicyIsNotDue() throws {
    var current = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )
    current.refreshInterval = .daily
    let refresher = PRActivityRefresher(provider: StaticPRActivityProvider())

    let refreshed = try refresher.refreshIfDue(
      current: current,
      now: Date(timeIntervalSince1970: 86_399)
    )

    XCTAssertNil(refreshed)
  }

  func testRefreshIfDuePropagatesProviderErrorsWhenDue() {
    var current = PRActivityStore.sample(
      now: Date(timeIntervalSince1970: 0),
      calendar: .prActivityUTC
    )
    current.refreshInterval = .daily
    let refresher = PRActivityRefresher(provider: FailingPRActivityProvider())

    XCTAssertThrowsError(
      try refresher.refreshIfDue(
        current: current,
        now: Date(timeIntervalSince1970: 86_400)
      )
    )
  }

  private func jsonData(repositoryID: String) throws -> Data {
    let parts = repositoryID.split(separator: "/")
    let owner = String(parts[0])
    let name = String(parts[1])
    let json = """
      {
        "bucketLabels": ["W1", "W2"],
        "defaultWindow": "2 weeks",
        "repositories": [
          {
            "id": "\(repositoryID)",
            "owner": "\(owner)",
            "name": "\(name)",
            "colorHex": "#ffffff",
            "weeklyCounts": [1, 2],
            "isIncluded": true
          }
        ]
      }
      """
    return Data(json.utf8)
  }
}

private struct FailingPRActivityProvider: PRActivityProviding {
  func load(now: Date) throws -> PRActivityStore {
    throw FixtureError.failure
  }

  enum FixtureError: Error {
    case failure
  }
}
