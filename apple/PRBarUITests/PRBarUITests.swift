import XCTest

final class PRBarUITests: XCTestCase {
  @MainActor
  func testTabsExposeReviewedPrototypeSurfaces() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))

    app.tapTab("Releases")
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))

    app.tapTab("Share")
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))

    app.tapTab("More")
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

    app.tapTab("Releases")
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))
    app.buttons["May 21, not selected, 1 release"].tap()
    XCTAssertTrue(app.staticTexts["v1.0.0 Tagged v1.0.0"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testShareTabExplainsWorkCardExport() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tapTab("Share")
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Public side"].exists)
    app.buttons["Export card"].tap()
    XCTAssertTrue(app.staticTexts["Choose what leaves the app"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Share public-side image"].exists)
    XCTAssertTrue(app.buttons["Copy caption"].exists)
  }

  @MainActor
  func testShareTabExportsRealActivityProof() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-refresh-data"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(app.staticTexts["#999 UI refresh merged PR"].waitForExistence(timeout: 4))

    app.tapTab("Share")
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["1 merged"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Proof source"].exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Last refreshed")).firstMatch.exists)

    app.buttons["Export card"].tap()
    XCTAssertTrue(app.staticTexts["Image and caption stay local"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Progress recap")).firstMatch.exists)
    XCTAssertTrue(app.buttons["Share public-side image"].exists)
    app.buttons["Copy caption"].tap()
    XCTAssertTrue(app.staticTexts["Caption copied from GitHub activity."].waitForExistence(timeout: 2))
  }

  @MainActor
  func testShareTabLabelsCachedProofBeforeExport() {
    let seedApp = XCUIApplication()
    seedApp.launchArguments = ["--ui-testing", "--ui-testing-seed-activity-cache"]
    seedApp.launch()

    XCTAssertTrue(seedApp.staticTexts["#424 Cached relaunch PR"].waitForExistence(timeout: 4))
    seedApp.terminate()

    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-cached-activity"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 4))
    app.tapTab("Share")
    XCTAssertTrue(app.staticTexts["Create a work card"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Last refreshed")).firstMatch.exists)
    app.buttons["Export card"].tap()
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Last refreshed")).firstMatch.waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Share public-side image"].exists)
  }

  @MainActor
  func testMoreMenuContainsRepositoryAndPrivacySettings() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tapTab("More")
    XCTAssertTrue(app.buttons["Repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Privacy"].exists)
    app.buttons["Repos"].tap()
    XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
  }

  @MainActor
  func testMoreSettingsAndAboutShowProductVersion() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tapTab("More")
    XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 2))
    app.buttons["Settings"].tap()
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "@neonwatty")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Connected")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "GitHub")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "3 included")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "4 available")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Not refreshed")).firstMatch.exists)
    XCTAssertTrue(app.buttons["Manage included repos"].exists)
    app.buttons["Manage included repos"].tap()
    XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
    XCTAssertTrue(app.navigationBars.buttons["Settings"].waitForExistence(timeout: 2))
    app.navigationBars.buttons["Settings"].tap()

    app.scrollToStaticText("Version")
    XCTAssertTrue(app.versionText().waitForExistence(timeout: 2))

    XCTAssertTrue(app.navigationBars.buttons["More"].waitForExistence(timeout: 2))
    app.navigationBars.buttons["More"].tap()
    XCTAssertTrue(app.buttons["About"].waitForExistence(timeout: 2))
    app.buttons["About"].tap()
    XCTAssertTrue(app.staticTexts["Product version"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Build"].exists)
    XCTAssertTrue(app.versionText().waitForExistence(timeout: 2))
  }

  @MainActor
  func testSettingsShowsRefreshFailureDiagnostics() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-refresh-failure"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(app.staticTexts["Showing cached GitHub data"].waitForExistence(timeout: 4))

    app.tapTab("More")
    app.buttons["Settings"].tap()

    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Showing cached data")).firstMatch.waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["GitHub is unreachable"].exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Existing data stays available")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "May 24, 2026")).firstMatch.exists)
  }

  @MainActor
  func testRepositorySetupSearchAndFiltersRepos() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    app.tapTab("More")
    XCTAssertTrue(app.buttons["Repos"].waitForExistence(timeout: 2))
    app.buttons["Repos"].tap()

    XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["3 of 5 selected"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["1 repo needs access"].waitForExistence(timeout: 2))

    app.textFields["repo-search-field"].tap()
    app.textFields["repo-search-field"].typeText("neonwatty/docs-site")
    XCTAssertTrue(app.staticTexts["neonwatty repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.switches["Include docs-site"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Documentation releases"].exists)

    app.buttons["Clear repo search"].tap()
    app.buttons["Blocked"].tap()
    XCTAssertTrue(app.switches["Include ops-console"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Needs SSO authorization"].exists)

    app.buttons["All"].tap()
    app.textFields["repo-search-field"].tap()
    app.textFields["repo-search-field"].typeText("missing-org-repo")
    app.scrollToStaticText("Repo not showing up?")
    XCTAssertTrue(app.staticTexts["Install PRBar in the GitHub organization."].exists)
    XCTAssertTrue(app.staticTexts["Authorize SSO for protected organizations."].exists)
    XCTAssertTrue(app.staticTexts["Check your repository permissions."].exists)

    app.buttons["Clear repo search"].tap()
    app.textFields["repo-search-field"].tap()
    app.textFields["repo-search-field"].typeText("docs")
    XCTAssertTrue(app.switches["Include docs-site"].waitForExistence(timeout: 2))
    app.tapButton("Select visible", untilStaticTextExists: "4 of 5 selected")
    XCTAssertTrue(app.staticTexts["4 of 5 selected"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testPRHeaderReposButtonOpensRepositorySetup() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.buttons["Edit repos"].waitForExistence(timeout: 2))
    app.buttons["Edit repos"].tap()
    XCTAssertTrue(app.staticTexts["Included repos power PRs, Releases, and Cards."].waitForExistence(timeout: 2))
    XCTAssertTrue(app.textFields["repo-search-field"].exists)
  }

  @MainActor
  func testFirstRunSelectsOneRepoFinishesSetupAndShowsSyncedActivity() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--signed-out", "--ui-testing-first-run-slow-sync"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 4))
    app.openRepositorySetupFromSignedOut()

    XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["0 of 5 selected"].waitForExistence(timeout: 2))
    XCTAssertFalse(app.buttons["Finish setup"].isEnabled)
    XCTAssertTrue(app.staticTexts["Select at least one repo to finish setup."].exists)

    app.textFields["repo-search-field"].tap()
    app.textFields["repo-search-field"].typeText("prbar")
    let prbarSwitch = app.switches["Include prbar"].firstMatch
    XCTAssertTrue(prbarSwitch.waitForExistence(timeout: 2))
    if app.keyboards.buttons["Return"].exists {
      app.keyboards.buttons["Return"].tap()
    }
    prbarSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    XCTAssertTrue(app.staticTexts["1 of 5 selected"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Finish setup syncs PRs and releases only for repos you turn on."].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Finish setup"].isEnabled)

    app.tapButton("Finish setup", untilStaticTextExists: "Shipping rhythm")

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 2))
    if app.staticTexts["Setup complete. Syncing repos"].waitForExistence(timeout: 4) {
      XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "1 selected repo")).firstMatch.exists)
      XCTAssertTrue(
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Syncing 1 of 1: prbar")).firstMatch.waitForExistence(timeout: 2) ||
          app.staticTexts["Last refreshed"].waitForExistence(timeout: 8)
      )
      XCTAssertTrue(
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Found 0 PRs and 0 releases so far")).firstMatch.exists ||
          app.staticTexts["Last refreshed"].exists
      )
    } else {
      XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 8))
    }
    XCTAssertTrue(app.staticTexts["#999 UI refresh merged PR"].waitForExistence(timeout: 10))

    app.tapTab("Releases")
    XCTAssertTrue(app.staticTexts["v9.9.9 UI refresh release"].waitForExistence(timeout: 4))
  }

  @MainActor
  func testFirstRunCanNavigateWhileSetupSyncRuns() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--signed-out", "--ui-testing-first-run-slow-sync"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 4))
    app.openRepositorySetupFromSignedOut()
    XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 2))

    app.textFields["repo-search-field"].tap()
    app.textFields["repo-search-field"].typeText("prbar")
    let prbarSwitch = app.switches["Include prbar"].firstMatch
    XCTAssertTrue(prbarSwitch.waitForExistence(timeout: 2))
    if app.keyboards.buttons["Return"].exists {
      app.keyboards.buttons["Return"].tap()
    }
    prbarSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

    app.tapButton("Finish setup", untilStaticTextExists: "Shipping rhythm")
    XCTAssertTrue(app.staticTexts["Setup complete. Syncing repos"].waitForExistence(timeout: 4))

    app.tapTab("Releases")
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Setup complete. Syncing repos"].waitForExistence(timeout: 2))

    app.tapTab("PRs")
    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["#999 UI refresh merged PR"].waitForExistence(timeout: 10))
  }

  @MainActor
  func testPullToRefreshUpdatesPRsAndReleases() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-refresh-data"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts["Not refreshed yet"].waitForExistence(timeout: 2))
    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Synced selected repositories")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts["#999 UI refresh merged PR"].waitForExistence(timeout: 4))

    app.tapTab("Releases")
    XCTAssertTrue(app.staticTexts["Shipping moments"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 2))
    app.buttons["Refresh activity"].tap()
    XCTAssertTrue(app.staticTexts["v9.9.9 UI refresh release"].waitForExistence(timeout: 4))
  }

  @MainActor
  func testPullToRefreshFailureShowsStaleDataStatus() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-refresh-failure"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 2))
    app.buttons["Refresh activity"].tap()

    XCTAssertTrue(app.staticTexts["Showing cached GitHub data"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Retry failed")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Showing cached data from")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts["#39 Connect GitHub auth fallback"].exists)
  }

  @MainActor
  func testPartialRefreshShowsRepositoryIssueAndKeepsSyncedData() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-partial-sync"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    app.buttons["Refresh activity"].tap()

    XCTAssertTrue(app.staticTexts["Partial GitHub sync"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Authorize SSO for example/client-api")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts["1 merged"].waitForExistence(timeout: 4))

    app.tapTab("Releases")
    XCTAssertTrue(app.staticTexts["Partial GitHub sync"].waitForExistence(timeout: 2))
    app.scrollToStaticText("v10.0.1 Partial sync visible release")
  }

  @MainActor
  func testRelaunchRestoresCachedActivityWithoutBlockingRefresh() {
    let seedApp = XCUIApplication()
    seedApp.launchArguments = ["--ui-testing", "--ui-testing-seed-activity-cache"]
    seedApp.launch()

    XCTAssertTrue(seedApp.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    XCTAssertTrue(seedApp.staticTexts["#424 Cached relaunch PR"].waitForExistence(timeout: 4))
    seedApp.terminate()

    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-cached-activity"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Shipping rhythm"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts["Last refreshed"].waitForExistence(timeout: 4))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "May 24, 2026")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts["#424 Cached relaunch PR"].exists)

    app.tabBars.buttons["Releases"].tap()
    XCTAssertTrue(app.staticTexts["v4.2.4 Cached relaunch release"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testSignedOutGitHubConnectShowsRepoSelection() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--signed-out"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 4))

    app.openRepositorySetupFromSignedOut()

    XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["0 of 5 selected"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.textFields["repo-search-field"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Finish setup"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testSignedOutGitHubDeviceAuthorizationContinuesToRepoSelection() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-testing-device-auth", "--signed-out"]
    app.launch()

    XCTAssertTrue(app.staticTexts["Connect GitHub"].waitForExistence(timeout: 4))

    app.tapContinueWithGitHub()

    XCTAssertTrue(app.staticTexts["Authorize GitHub"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["github-device-code"].exists)
    XCTAssertTrue(app.staticTexts["github-device-code-expiration"].exists)
    XCTAssertTrue(app.buttons["Copy code"].exists)
    XCTAssertTrue(app.buttons["Copy link"].exists)
    XCTAssertTrue(app.buttons["Open here"].exists)
    XCTAssertTrue(app.buttons["Refresh code"].exists)

    app.buttons["I authorized GitHub"].tap()

    XCTAssertTrue(app.staticTexts["Choose repos"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["0 of 5 selected"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.textFields["repo-search-field"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Finish setup"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testLiveGitHubSelectsOneRepositoryAndSyncsActivity() throws {
    try runLiveGitHubSetupSmoke()
  }
}

private extension XCUIApplication {
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
  func tapContinueWithGitHub(file: StaticString = #filePath, line: UInt = #line) {
    let button = buttons["Continue with GitHub"].firstMatch
    if button.waitForExistence(timeout: 2) == false {
      for _ in 0..<3 where button.exists == false {
        swipeUp()
      }
    }
    XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing Continue with GitHub button", file: file, line: line)
    activate()
    button.tap()
  }

  @MainActor
  func scrollToStaticText(_ label: String, maxSwipes: Int = 4, file: StaticString = #filePath, line: UInt = #line) {
    let text = staticTexts[label].firstMatch
    for _ in 0..<maxSwipes where text.exists == false {
      swipeUp()
    }
    XCTAssertTrue(text.waitForExistence(timeout: 2), "Missing \(label)", file: file, line: line)
  }

  @MainActor
  func versionText() -> XCUIElement {
    staticTexts
      .matching(NSPredicate(format: "label MATCHES %@", ".*[0-9]+\\.[0-9]+\\.[0-9]+.*"))
      .firstMatch
  }

  @MainActor
  func openRepositorySetupFromSignedOut(file: StaticString = #filePath, line: UInt = #line) {
    tapContinueWithGitHub(file: file, line: line)
    if textFields["repo-search-field"].waitForExistence(timeout: 2) {
      return
    }

    if buttons["Continue with GitHub"].firstMatch.exists {
      tapContinueWithGitHub(file: file, line: line)
    }
    XCTAssertTrue(textFields["repo-search-field"].waitForExistence(timeout: 3), "Repository setup did not open", file: file, line: line)
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
  app.openRepositorySetupFromSignedOut(file: file, line: line)
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
