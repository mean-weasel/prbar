import XCTest

@testable import PRMenuBar

final class GitHubPRActivityProviderIncrementalTests: XCTestCase,
  GitHubPRActivityProviderTestHelpers
{
  func testProviderSearchesIncrementalRangeWithinCacheDuration() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-27T12:00:00.000Z",
          id: "PR_old"
        ),
        graphQLMergedPullRequestData(
          mergedAt: "2026-05-03T12:00:00.000Z",
          id: "PR_new"
        ),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 72 * 60 * 60
    )

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    let refreshed = try provider.load(now: try date("2026-05-03T18:00:00Z"))

    XCTAssertEqual(refreshed.repositories.first?.weeklyCounts, [1])
    XCTAssertEqual(transport.capturedRequests.count, 5)
    XCTAssertTrue(
      bodyString(in: transport.capturedRequests[4])?
        .contains("merged:2026-05-02..2026-05-04") == true
    )
  }

  func testProviderUsesFullSearchWhenWindowExpandsBeforeCache() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-26T12:00:00.000Z",
          id: "PR_old"
        ),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-20T12:00:00.000Z",
          id: "PR_older"
        ),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 72 * 60 * 60
    )

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    provider.bucketLabels = ["W1", "W2"]
    let refreshed = try provider.load(now: try date("2026-05-03T18:00:00Z"))

    XCTAssertEqual(refreshed.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(transport.capturedRequests.count, 5)
    XCTAssertTrue(
      bodyString(in: transport.capturedRequests[4])?
        .contains("merged:2026-04-19..2026-05-04") == true
    )
  }

  func testProviderDoesNotAdvanceIncrementalCacheAfterFailedRefresh() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-26T12:00:00.000Z",
          id: "PR_old"
        ),
        Data(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-05-04T12:00:00.000Z",
          id: "PR_new"
        ),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 72 * 60 * 60
    )

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    XCTAssertThrowsError(try provider.load(now: try date("2026-05-03T18:00:00Z")))
    _ = try provider.load(now: try date("2026-05-04T18:00:00Z"))

    XCTAssertTrue(
      bodyString(in: transport.capturedRequests[5])?
        .contains("merged:2026-05-02..2026-05-05") == true
    )
  }
}
