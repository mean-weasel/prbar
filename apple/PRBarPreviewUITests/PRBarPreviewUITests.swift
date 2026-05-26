import XCTest

final class PRBarPreviewUITests: XCTestCase {
  func testPreviewDeviceCanLaunchCoreTabs() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 8))

    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 4))

    app.tabBars.buttons["Share"].tap()
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 4))
  }
}
