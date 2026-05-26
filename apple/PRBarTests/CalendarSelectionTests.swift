import XCTest
@testable import PRBar

final class CalendarSelectionTests: XCTestCase {
  func testWeekDaysEndOnToday() {
    let days = CalendarDay.days(endingAt: SampleData.today, range: .week)

    XCTAssertEqual(days.count, 7)
    XCTAssertEqual(days.last?.date, SampleData.today)
  }

  func testMonthDaysCoverMayFixtureMonth() {
    let days = CalendarDay.days(endingAt: SampleData.today, range: .month)

    XCTAssertEqual(days.count, 31)
    XCTAssertEqual(days.first?.dayNumber, 1)
    XCTAssertEqual(days.last?.dayNumber, 31)
  }

  func testDayNumbersUseUTCGregorianCalendar() {
    let day = CalendarDay(date: SampleData.dateTime("2026-05-24T01:30:00Z"), count: 0)

    XCTAssertEqual(day.dayNumber, 24)
    XCTAssertEqual(day.monthName, "May")
  }

  func testMayFixtureMonthStartsUnderFridayInWeekdayGrid() {
    let days = CalendarDay.days(endingAt: SampleData.today, range: .month)

    XCTAssertEqual(CalendarDay.leadingWeekdayPlaceholderCount(for: days), 5)
  }

  func testAccessibilityLabelIncludesSelectedStateAndNeutralCount() {
    let selectedDay = CalendarDay(date: SampleData.dateTime("2026-05-24T01:30:00Z"), count: 3)
    let emptyDay = CalendarDay(date: SampleData.dateTime("2026-05-25T01:30:00Z"), count: 0)

    XCTAssertEqual(selectedDay.accessibilityLabel(isSelected: true), "May 24, selected, 3 items")
    XCTAssertEqual(emptyDay.accessibilityLabel(isSelected: false), "May 25, not selected")
  }

  func testAccessibilityLabelUsesCustomCountLabel() {
    let releaseDay = CalendarDay(date: SampleData.dateTime("2026-05-24T01:30:00Z"), count: 1)
    let pullRequestDay = CalendarDay(date: SampleData.dateTime("2026-05-25T01:30:00Z"), count: 2)

    XCTAssertEqual(
      releaseDay.accessibilityLabel(
        isSelected: false,
        countLabel: { $0 == 1 ? "release" : "releases" }
      ),
      "May 24, not selected, 1 release"
    )
    XCTAssertEqual(
      pullRequestDay.accessibilityLabel(
        isSelected: true,
        countLabel: { $0 == 1 ? "pull request" : "pull requests" }
      ),
      "May 25, selected, 2 pull requests"
    )
  }
}
