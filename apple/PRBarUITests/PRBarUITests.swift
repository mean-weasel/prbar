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

  @MainActor
  func testRepositorySetupSearchAndFiltersRepos() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tabBars.buttons["More"].tap()
    XCTAssertTrue(app.buttons["Repos"].waitForExistence(timeout: 2))
    app.buttons["Repos"].tap()

    XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
    app.textFields["repo-search-field"].tap()
    app.textFields["repo-search-field"].typeText("docs")
    XCTAssertTrue(app.switches["Include docs-site"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Documentation releases"].exists)

    app.buttons["Clear repo search"].tap()
    app.buttons["Blocked"].tap()
    XCTAssertTrue(app.switches["Include ops-console"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Needs SSO authorization"].exists)
  }

  @MainActor
  func testPullToRefreshUpdatesPRsAndReleases() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-refresh-data"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(app.staticTexts["#999 UI refresh merged PR"].waitForExistence(timeout: 4))

    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))
    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(app.staticTexts["v9.9.9 UI refresh release"].waitForExistence(timeout: 4))
  }

  @MainActor
  func testSignedOutGitHubConnectShowsRepoSelection() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--signed-out"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts["Private by default"].exists)

    app.buttons["Continue with GitHub"].tap()

    XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.switches["Include prbar"].exists)
    XCTAssertTrue(app.buttons["Finish setup"].exists)
  }

  @MainActor
  func testSignedOutGitHubDeviceAuthorizationContinuesToRepoSelection() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-device-auth", "--signed-out"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 4))

    app.buttons["Continue with GitHub"].tap()

    XCTAssertTrue(app.staticTexts["Authorize GitHub"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["github-device-code"].exists)
    XCTAssertTrue(app.buttons["Copy code"].exists)
    XCTAssertTrue(app.buttons["Copy link"].exists)
    XCTAssertTrue(app.buttons["Open here"].exists)

    app.buttons["I authorized GitHub"].tap()

    XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.switches["Include prbar"].exists)
    XCTAssertTrue(app.buttons["Finish setup"].exists)
  }
}
