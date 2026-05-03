import XCTest

@testable import PRMenuBar

final class PRActivityProviderFactoryTests: XCTestCase {
  func testFactoryUsesStaticProviderWithoutToken() {
    let provider = PRActivityProviderFactory.make(environment: [:])

    XCTAssertTrue(provider is StaticPRActivityProvider)
  }

  func testFactoryUsesGitHubProviderWithToken() {
    let provider = PRActivityProviderFactory.make(
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: "token"]
    )

    XCTAssertTrue(provider is GitHubPRActivityProvider)
  }
}
