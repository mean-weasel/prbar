import XCTest

@testable import PRMenuBar

final class RefreshPolicyTests: XCTestCase {
  func testManualRefreshIsNeverDue() {
    let policy = RefreshPolicy(interval: .manual)

    XCTAssertFalse(
      policy.isRefreshDue(
        lastRefreshedAt: Date(timeIntervalSince1970: 0),
        now: Date(timeIntervalSince1970: 100_000)
      )
    )
  }

  func testDailyRefreshIsDueAfterOneDay() {
    let policy = RefreshPolicy(interval: .daily)

    XCTAssertTrue(
      policy.isRefreshDue(
        lastRefreshedAt: Date(timeIntervalSince1970: 0),
        now: Date(timeIntervalSince1970: 86_400)
      )
    )
  }

  func testDailyRefreshIsNotDueBeforeOneDay() {
    let policy = RefreshPolicy(interval: .daily)

    XCTAssertFalse(
      policy.isRefreshDue(
        lastRefreshedAt: Date(timeIntervalSince1970: 0),
        now: Date(timeIntervalSince1970: 86_399)
      )
    )
  }
}
