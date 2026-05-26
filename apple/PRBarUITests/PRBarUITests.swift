import XCTest

final class PRBarUITests: XCTestCase {
  @MainActor
  func testTabsExposeReviewedPrototypeSurfaces() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))

    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))

    app.tabBars.buttons["Share"].tap()
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))

    app.tabBars.buttons["More"].tap()
    XCTAssertTrue(app.staticTexts["Menu"].waitForExistence(timeout: 2))
  }
}
