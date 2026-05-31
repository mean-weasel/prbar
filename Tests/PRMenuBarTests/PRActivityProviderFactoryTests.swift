import XCTest

@testable import PRMenuBar

final class PRActivityProviderFactoryTests: XCTestCase {
  func testFactoryUsesStaticProviderWithoutToken() {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [:],
      gitHubCLIToken: { _ in nil }
    )

    XCTAssertTrue(selection.provider is StaticPRActivityProvider)
    XCTAssertEqual(selection.dataSource, .sample)
  }

  func testFactoryUsesGitHubProviderWithToken() {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: "token"]
    )

    XCTAssertTrue(selection.provider is GitHubPRActivityProvider)
    let provider = selection.provider as? GitHubPRActivityProvider
    XCTAssertTrue(provider?.mergedPullRequestCacheStore is FileGitHubMergedPullRequestCacheStore)
    XCTAssertTrue(provider?.discoveryCacheStore is FileGitHubDiscoveryCacheStore)
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
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: "   \n"],
      gitHubCLIToken: { _ in nil }
    )

    XCTAssertTrue(selection.provider is StaticPRActivityProvider)
    XCTAssertEqual(selection.dataSource, .sample)
  }

  func testFactoryUsesGitHubCLITokenWhenEnvironmentTokenIsMissing() throws {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [:],
      gitHubCLIToken: { _ in "cli-token" }
    )
    let provider = try XCTUnwrap(selection.provider as? GitHubPRActivityProvider)

    XCTAssertEqual(provider.token, "cli-token")
    XCTAssertEqual(selection.dataSource, .github)
  }

  func testFactoryPrefersEnvironmentTokenBeforeGitHubCLIToken() throws {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [PRActivityProviderFactory.tokenEnvironmentKey: "env-token"],
      gitHubCLIToken: { _ in "cli-token" }
    )
    let provider = try XCTUnwrap(selection.provider as? GitHubPRActivityProvider)

    XCTAssertEqual(provider.token, "env-token")
    XCTAssertEqual(selection.dataSource, .github)
  }

  func testGitHubCLITokenResolverCanBeDisabled() {
    let token = GitHubCLITokenResolver.token(
      environment: [GitHubCLITokenResolver.disabledEnvironmentKey: "1"]
    )

    XCTAssertNil(token)
  }

  func testFactoryUsesFixtureProviderBeforeGitHubToken() throws {
    let selection = PRActivityProviderFactory.makeSelection(
      environment: [
        PRActivityProviderFactory.fixturePathEnvironmentKey: " /tmp/pr-fixture.json ",
        PRActivityProviderFactory.tokenEnvironmentKey: "token",
      ],
      gitHubCLIToken: { _ in "cli-token" }
    )

    let provider = try XCTUnwrap(selection.provider as? FilePRActivityProvider)
    XCTAssertEqual(provider.path, "/tmp/pr-fixture.json")
    XCTAssertEqual(selection.dataSource, .github)
  }
}
