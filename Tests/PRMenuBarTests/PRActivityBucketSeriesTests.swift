import XCTest

@testable import PRMenuBar

final class PRActivityBucketSeriesTests: XCTestCase {
  func testWeeklyBucketsUseSundayStartsAndCountMergedDates() throws {
    let series = PRActivityBucketSeries.weekly(
      mergedDates: [
        try date("2026-04-19T12:00:00Z"),
        try date("2026-04-25T23:59:59Z"),
        try date("2026-04-26T00:00:00Z"),
      ],
      bucketCount: 2,
      now: try date("2026-05-02T18:00:00Z")
    )

    XCTAssertEqual(series.labels, ["04/19", "04/26"])
    XCTAssertEqual(series.counts, [2, 1])
  }

  func testWeeklyBucketsIgnoreDatesOutsideRange() throws {
    let series = PRActivityBucketSeries.weekly(
      mergedDates: [
        try date("2026-04-18T23:59:59Z"),
        try date("2026-04-19T00:00:00Z"),
      ],
      bucketCount: 1,
      now: try date("2026-04-25T12:00:00Z")
    )

    XCTAssertEqual(series.labels, ["04/19"])
    XCTAssertEqual(series.counts, [1])
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
