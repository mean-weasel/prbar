import XCTest

@testable import PRMenuBar

final class GitHubPRActivityProviderIncrementalTests: XCTestCase,
  GitHubPRActivityProviderTestHelpers
{
  func testProviderUsesPersistedCacheAfterProviderRestart() throws {
    let defaults = UserDefaults(suiteName: "GitHubPRActivityProviderPersistedCacheTests")!
    defaults.removePersistentDomain(forName: "GitHubPRActivityProviderPersistedCacheTests")
    let cacheStore = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)
    let firstTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-27T12:00:00.000Z",
          id: "PR_old"
        ),
      ]
    )
    let firstProvider = GitHubPRActivityProvider(
      token: "token",
      transport: firstTransport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore
    )

    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-05-03T12:00:00.000Z",
          id: "PR_new"
        ),
      ]
    )
    let secondProvider = GitHubPRActivityProvider(
      token: "token",
      transport: secondTransport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore
    )

    let refreshed = try secondProvider.load(now: try date("2026-05-03T18:00:00Z"))

    XCTAssertEqual(refreshed.repositories.first?.weeklyCounts, [1])
    XCTAssertEqual(secondTransport.capturedRequests.count, 4)
    XCTAssertTrue(
      bodyString(in: secondTransport.capturedRequests[3])?
        .contains("merged:2026-05-02..2026-05-04") == true
    )
  }

  func testProviderFallsBackToFullSearchWhenPersistedRepositorySetChanges() throws {
    let defaults = UserDefaults(suiteName: "GitHubPRActivityProviderRepositoryMismatchTests")!
    defaults.removePersistentDomain(forName: "GitHubPRActivityProviderRepositoryMismatchTests")
    let cacheStore = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)
    let firstProvider = GitHubPRActivityProvider(
      token: "token",
      transport: FixtureGitHubAPITransport(
        responses: [
          repositoryDiscoveryData(),
          authenticatedUserData(),
          organizationsData(),
          graphQLMergedPullRequestData(
            mergedAt: "2026-04-27T12:00:00.000Z",
            id: "PR_old"
          ),
        ]
      ),
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore
    )

    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(
          repositories: [
            repositoryFixture(owner: "owner", name: "new", canPull: true)
          ]
        ),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-28T12:00:00.000Z",
          id: "PR_new"
        ),
      ]
    )
    let secondProvider = GitHubPRActivityProvider(
      token: "token",
      transport: secondTransport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore
    )

    let refreshed = try secondProvider.load(now: try date("2026-05-03T18:00:00Z"))

    XCTAssertEqual(refreshed.repositories.map(\.id), ["owner/new"])
    XCTAssertTrue(
      bodyString(in: secondTransport.capturedRequests[3])?
        .contains("merged:2026-04-26..2026-05-04") == true
    )
  }

  func testProviderFallsBackToFullSearchWhenPersistedCachePredatesWindow() throws {
    let defaults = UserDefaults(suiteName: "GitHubPRActivityProviderDormantCacheTests")!
    defaults.removePersistentDomain(forName: "GitHubPRActivityProviderDormantCacheTests")
    let cacheStore = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)
    let firstProvider = GitHubPRActivityProvider(
      token: "token",
      transport: FixtureGitHubAPITransport(
        responses: [
          repositoryDiscoveryData(),
          authenticatedUserData(),
          organizationsData(),
          graphQLMergedPullRequestData(
            mergedAt: "2026-04-27T12:00:00.000Z",
            id: "PR_old"
          ),
        ]
      ),
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore
    )

    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-06-01T12:00:00.000Z",
          id: "PR_current"
        ),
      ]
    )
    let secondProvider = GitHubPRActivityProvider(
      token: "token",
      transport: secondTransport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore
    )

    let refreshed = try secondProvider.load(now: try date("2026-06-01T18:00:00Z"))

    XCTAssertEqual(refreshed.repositories.first?.weeklyCounts, [1])
    XCTAssertTrue(
      bodyString(in: secondTransport.capturedRequests[3])?
        .contains("merged:2026-05-25..2026-06-02") == true
    )
  }

  func testProviderOverlapsIncrementalSearchAndDedupesCachedPullRequests() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-05-01T23:55:00.000Z",
          id: "PR_boundary"
        ),
        graphQLMergedPullRequestData(
          mergedAt: "2026-05-01T23:55:00.000Z",
          id: "PR_boundary"
        ),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 72 * 60 * 60
    )

    _ = try provider.load(now: try date("2026-05-02T00:15:00Z"))
    let refreshed = try provider.load(now: try date("2026-05-02T01:00:00Z"))

    XCTAssertEqual(refreshed.repositories.first?.weeklyCounts, [1])
    XCTAssertTrue(
      bodyString(in: transport.capturedRequests[4])?
        .contains("merged:2026-05-01..2026-05-03") == true
    )
  }

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
