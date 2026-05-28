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

  func testLiveGitHubOneRepositoryRefresh() {
    let login = requiredEnvironmentValue("IOS_LIVE_GITHUB_LOGIN")
    let repoID = requiredEnvironmentValue("IOS_LIVE_INCLUDED_REPO")
    let repoName = repoID.split(separator: "/").last.map(String.init) ?? repoID

    let app = XCUIApplication()
    app.launchArguments = ["--live-github-smoke"]
    app.launchEnvironment["PRBAR_LIVE_SMOKE_GITHUB_LOGIN"] = login
    app.launchEnvironment["PRBAR_LIVE_SMOKE_INCLUDED_REPO"] = repoID
    app.launch()

    if app.staticTexts["Connect GitHub"].waitForExistence(timeout: 5) {
      XCTFail("Live GitHub smoke requires an existing GitHub session on the preview device for @\(login). Sign in once on the device, then rerun.")
      return
    }

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 15))
    XCTAssertTrue(app.buttons["1 repositories"].waitForExistence(timeout: 5), "Expected exactly one included repository: \(repoID)")

    app.buttons["1 repositories"].tap()
    XCTAssertTrue(app.staticTexts["@\(login)"].waitForExistence(timeout: 5), "Expected connected GitHub user @\(login)")
    XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: 5), "Expected one selected repository")
    let searchField = app.textFields["repo-search-field"]
    XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    searchField.tap()
    searchField.typeText(repoName)
    XCTAssertTrue(app.switches["Include \(repoName)"].waitForExistence(timeout: 5), "Expected selected repository \(repoID) to be available")

    let backButton = app.navigationBars.buttons["PRs"]
    if backButton.waitForExistence(timeout: 2) {
      backButton.tap()
    } else {
      app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 5))

    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(waitForRefreshCompletion(in: app, timeout: 90), "Expected live GitHub refresh to finish")
    XCTAssertFalse(app.staticTexts["Last refresh failed"].exists, "Live GitHub refresh failed for \(repoID)")
    XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 5), "Expected successful live refresh for \(repoID)")
    XCTAssertFalse(app.staticTexts["No merged PRs"].exists && app.staticTexts["No release selected"].exists, "Expected live PR or release evidence for \(repoID)")
  }

  private func requiredEnvironmentValue(_ key: String) -> String {
    guard let value = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
      value.isEmpty == false
    else {
      XCTFail("Missing required environment value: \(key)")
      return ""
    }
    return value
  }

  private func waitForRefreshCompletion(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if app.staticTexts["Last refreshed"].exists || app.staticTexts["Last refresh failed"].exists {
        return true
      }
      RunLoop.current.run(until: Date().addingTimeInterval(1))
    }
    return false
  }
}
