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

  @MainActor
  func testPRCalendarAndRepoDistributionAreReachable() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts["Distribution by repo"].exists)
    app.buttons["May 23, not selected, 1 pull request"].tap()
    XCTAssertTrue(app.staticTexts["1 merged"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testReleasesCalendarShowsSelectedReleaseDetail() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))
    app.buttons["May 21, not selected, 1 release"].tap()
    XCTAssertTrue(app.staticTexts["v1.0.0 Tagged v1.0.0"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testShareTabExplainsWorkCardExport() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tabBars.buttons["Share"].tap()
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Public side"].exists)
    app.buttons["Export card"].tap()
    XCTAssertTrue(app.staticTexts["Choose what leaves the app"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Share public-side image"].exists)
    XCTAssertTrue(app.buttons["Copy caption"].exists)
  }

  @MainActor
  func testMoreMenuContainsRepositoryAndPrivacySettings() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tabBars.buttons["More"].tap()
    XCTAssertTrue(app.buttons["Repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Privacy"].exists)
    app.buttons["Repos"].tap()
    XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
  }
}
