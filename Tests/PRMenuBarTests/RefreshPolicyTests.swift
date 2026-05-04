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

  func testDailyRefreshIsDueWhenLocalDayChangesBeforeOneDay() throws {
    let policy = RefreshPolicy(interval: .daily, calendar: .prActivityPhoenix)

    XCTAssertTrue(
      policy.isRefreshDue(
        lastRefreshedAt: try date("2026-05-04T05:30:00Z"),
        now: try date("2026-05-04T07:15:00Z")
      )
    )
  }

  func testDailyRefreshIsNotDueBeforeOneDayOnSameLocalDay() throws {
    let policy = RefreshPolicy(interval: .daily, calendar: .prActivityPhoenix)

    XCTAssertFalse(
      policy.isRefreshDue(
        lastRefreshedAt: try date("2026-05-04T08:00:00Z"),
        now: try date("2026-05-04T20:00:00Z")
      )
    )
  }

  func testDailyRefreshReportsNextLocalDayStart() throws {
    let policy = RefreshPolicy(interval: .daily, calendar: .prActivityPhoenix)

    XCTAssertEqual(
      policy.nextRefreshDate(lastRefreshedAt: try date("2026-05-04T20:00:00Z")),
      try date("2026-05-05T07:00:00Z")
    )
  }

  func testManualRefreshDoesNotReportNextRefreshDate() {
    let policy = RefreshPolicy(interval: .manual)

    XCTAssertNil(policy.nextRefreshDate(lastRefreshedAt: Date(timeIntervalSince1970: 0)))
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}

extension Calendar {
  fileprivate static var prActivityPhoenix: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 1
    calendar.timeZone = TimeZone(identifier: "America/Phoenix") ?? .gmt
    return calendar
  }
}
