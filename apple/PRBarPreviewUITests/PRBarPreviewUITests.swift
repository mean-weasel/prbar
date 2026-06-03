import XCTest

final class PRBarPreviewUITests: XCTestCase {
  @MainActor
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

  @MainActor
  func testLiveGitHubSelectsOneRepositoryAndSyncsActivity() throws {
    try runLiveGitHubSetupSmoke()
  }

  @MainActor
  func testLivePostHogGrowthMetricsRender() throws {
    try runLivePostHogGrowthSmoke()
  }
}

@MainActor
private func runLiveGitHubSetupSmoke(file: StaticString = #filePath, line: UInt = #line) throws {
  let environment = ProcessInfo.processInfo.environment
  guard let token = environment["PRBAR_IOS_LIVE_GITHUB_TOKEN"], token.isEmpty == false else {
    throw XCTSkip("PRBAR_IOS_LIVE_GITHUB_TOKEN is required for live GitHub device smoke.")
  }

  let repositoryFullName = environment["PRBAR_IOS_LIVE_REPOSITORY"] ?? "mean-weasel/prbar"
  let repositoryName = repositoryFullName.split(separator: "/").last.map(String.init) ?? repositoryFullName
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing", "--ui-testing-live-github", "--signed-out"]
  app.launchEnvironment["PRBAR_IOS_LIVE_GITHUB_TOKEN"] = token
  app.launchEnvironment["PRBAR_IOS_LIVE_REPOSITORY"] = repositoryFullName
  if let login = environment["PRBAR_IOS_LIVE_GITHUB_LOGIN"] {
    app.launchEnvironment["PRBAR_IOS_LIVE_GITHUB_LOGIN"] = login
  }
  app.launch()

  XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 8), file: file, line: line)
  app.tapContinueWithGitHub(file: file, line: line)
  XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 20), file: file, line: line)
  XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "0 of ")).firstMatch.waitForExistence(timeout: 5), file: file, line: line)

  let searchField = app.textFields["repo-search-field"]
  XCTAssertTrue(searchField.waitForExistence(timeout: 5), file: file, line: line)
  searchField.tap()
  searchField.typeText(repositoryFullName)
  if app.keyboards.buttons["Return"].exists {
    app.keyboards.buttons["Return"].tap()
  }

  let repositorySwitch = app.switches["Include \(repositoryName)"].firstMatch
  XCTAssertTrue(repositorySwitch.waitForExistence(timeout: 20), "Could not find \(repositoryFullName). Check GitHub App installation, SSO, and token access.", file: file, line: line)
  repositorySwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
  XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "1 of ")).firstMatch.waitForExistence(timeout: 5), file: file, line: line)

  app.tapButton("Finish setup", untilStaticTextExists: "Shipping rhythm", file: file, line: line)
  XCTAssertTrue(
    app.staticTexts["Last refreshed"].waitForExistence(timeout: 60) ||
      app.staticTexts["Partial GitHub sync"].waitForExistence(timeout: 2),
    "Live GitHub sync did not finish or surface a partial-sync issue.",
    file: file,
    line: line
  )

  XCTAssertTrue(
    app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "#")).firstMatch.waitForExistence(timeout: 10) ||
      app.staticTexts["No merged PRs"].waitForExistence(timeout: 2),
    "PRs tab did not render synced PR data or an intentional empty state.",
    file: file,
    line: line
  )

  app.tapTab("Releases", file: file, line: line)
  XCTAssertTrue(
    app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", repositoryName)).firstMatch.waitForExistence(timeout: 10) ||
      app.staticTexts["No releases or tags"].waitForExistence(timeout: 2),
    "Releases tab did not render synced release/tag data or an intentional empty state.",
    file: file,
    line: line
  )
}

@MainActor
private func runLivePostHogGrowthSmoke(file: StaticString = #filePath, line: UInt = #line) throws {
  let environment = ProcessInfo.processInfo.environment
  guard let projectID = environment["PRBAR_IOS_POSTHOG_PROJECT_ID"], projectID.isEmpty == false,
    let personalAPIKey = environment["PRBAR_IOS_POSTHOG_PERSONAL_API_KEY"], personalAPIKey.isEmpty == false
  else {
    throw XCTSkip("PRBAR_IOS_POSTHOG_PROJECT_ID and PRBAR_IOS_POSTHOG_PERSONAL_API_KEY are required for live PostHog device smoke.")
  }

  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing"]
  app.launchEnvironment["PRBAR_IOS_POSTHOG_PROJECT_ID"] = projectID
  app.launchEnvironment["PRBAR_IOS_POSTHOG_PERSONAL_API_KEY"] = personalAPIKey
  if let host = environment["PRBAR_IOS_POSTHOG_HOST"], host.isEmpty == false {
    app.launchEnvironment["PRBAR_IOS_POSTHOG_HOST"] = host
  }
  app.launch()

  app.tapTab("Growth", file: file, line: line)
  XCTAssertTrue(app.staticTexts["Usage and search movement near shipped work"].waitForExistence(timeout: 8), file: file, line: line)
  XCTAssertTrue(app.buttons["Refresh PostHog growth"].waitForExistence(timeout: 4), file: file, line: line)
  app.buttons["Refresh PostHog growth"].tap()
  XCTAssertTrue(app.staticTexts["Active users"].waitForExistence(timeout: 30), file: file, line: line)
  XCTAssertTrue(app.staticTexts["Events"].waitForExistence(timeout: 30), file: file, line: line)

  app.tapTab("More", file: file, line: line)
  XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 4), file: file, line: line)
  app.buttons["Settings"].tap()
  app.scrollToButton("PostHog", file: file, line: line)
  app.buttons["PostHog"].tap()
  XCTAssertTrue(app.staticTexts["Connection"].waitForExistence(timeout: 4), file: file, line: line)
  XCTAssertTrue(app.staticTexts["Configuration"].exists, file: file, line: line)
  XCTAssertTrue(app.staticTexts["Live config"].exists, file: file, line: line)
  XCTAssertTrue(app.staticTexts["Host"].exists, file: file, line: line)
  XCTAssertTrue(app.staticTexts["Project ID"].exists, file: file, line: line)
  XCTAssertTrue(app.staticTexts["Personal API key"].exists, file: file, line: line)
}

private extension XCUIApplication {
  @MainActor
  func tapContinueWithGitHub(file: StaticString = #filePath, line: UInt = #line) {
    let button = buttons["Continue with GitHub"].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing Continue with GitHub button", file: file, line: line)
    activate()
    button.tap()
  }

  @MainActor
  func tapTab(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
    let button = tabBars.firstMatch.buttons[name].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing \(name) tab", file: file, line: line)
    activate()
    button.tap()
    if button.isSelected == false {
      activate()
      button.tap()
    }
  }

  @MainActor
  func tapButton(
    _ name: String,
    untilStaticTextExists expectedText: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let button = buttons[name].firstMatch
    XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing \(name) button", file: file, line: line)
    activate()
    button.tap()
    if staticTexts[expectedText].waitForExistence(timeout: 2) {
      return
    }

    activate()
    button.tap()
    XCTAssertTrue(staticTexts[expectedText].waitForExistence(timeout: 3), "\(name) did not reach \(expectedText)", file: file, line: line)
  }

  @MainActor
  func scrollToButton(_ label: String, maxSwipes: Int = 4, file: StaticString = #filePath, line: UInt = #line) {
    let button = buttons[label].firstMatch
    for _ in 0..<maxSwipes where button.exists == false {
      swipeUp()
    }
    XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing \(label) button", file: file, line: line)
  }
}
