import XCTest

@testable import PRMenuBar

final class PRActivityProviderFactoryTests: XCTestCase {
  func testFactoryUsesStaticProviderWithoutToken() {
    let selection = PRActivityProviderFactory.makeSelection(environment: [:])

    XCTAssertTrue(selection.provider is StaticPRActivityProvider)
    XCTAssertEqual(selection.dataSource, .sample)
  }

  func testFactoryUsesGitHubProviderWithToken() {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: "token"]
    )

    XCTAssertTrue(selection.provider is GitHubPRActivityProvider)
    XCTAssertEqual(selection.dataSource, .github)
  }

  func testFactoryTrimsGitHubProviderToken() throws {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: " \ntoken\t"]
    )
    let provider = try XCTUnwrap(selection.provider as? GitHubPRActivityProvider)

    XCTAssertEqual(provider.token, "token")
    XCTAssertEqual(selection.dataSource, .github)
  }

  func testFactoryUsesStaticProviderWithWhitespaceOnlyToken() {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: "   \n"]
    )

    XCTAssertTrue(selection.provider is StaticPRActivityProvider)
    XCTAssertEqual(selection.dataSource, .sample)
  }
}
