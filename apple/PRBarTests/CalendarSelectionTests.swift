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
}
