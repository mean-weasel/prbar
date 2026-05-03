import XCTest

@testable import PRMenuBar

final class ActivityWindowTests: XCTestCase {
  func testDayCountsMatchLabels() {
    XCTAssertEqual(ActivityWindow.oneDay.dayCount, 1)
    XCTAssertEqual(ActivityWindow.oneWeek.dayCount, 7)
    XCTAssertEqual(ActivityWindow.twoWeeks.dayCount, 14)
    XCTAssertEqual(ActivityWindow.oneMonth.dayCount, 30)
  }
}
