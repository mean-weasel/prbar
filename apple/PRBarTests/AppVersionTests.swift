import XCTest

@testable import PRBar

final class AppVersionTests: XCTestCase {
  func testDisplayValueUsesMarketingVersionAndBuildNumber() {
    let version = AppVersion(infoDictionary: [
      "CFBundleShortVersionString": "1.2.3",
      "CFBundleVersion": "45",
    ])

    XCTAssertEqual(version.displayValue, "1.2.3 (45)")
  }

  func testDisplayValueFallsBackWhenBundleInfoIsMissing() {
    let version = AppVersion(infoDictionary: [:])

    XCTAssertEqual(version.displayValue, "0.0.0 (0)")
  }
}
