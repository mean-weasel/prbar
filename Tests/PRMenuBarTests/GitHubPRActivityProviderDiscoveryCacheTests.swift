import XCTest

@testable import PRMenuBar

final class GitHubPRActivityProviderDiscoveryCacheTests: XCTestCase,
  GitHubPRActivityProviderTestHelpers
{
  func testProviderUsesPersistedDiscoveryAndPullRequestCachesAfterRestart() throws {
    let stores = cacheStores(suiteName: "GitHubProviderPersistedDiscoveryTests")
    let firstProvider = GitHubPRActivityProvider(
      token: "token",
      transport: FixtureGitHubAPITransport(
        responses: [
          repositoryDiscoveryData(),
          authenticatedUserData(),
          organizationsData(),
          graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z", id: "PR_old"),
        ]
      ),
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )
    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let collector = RefreshMetricsCollector()
    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z", id: "PR_new")
      ]
    )
    let secondProvider = GitHubPRActivityProvider(
      token: "token",
      transport: secondTransport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery,
      metrics: collector
    )

    let refreshed = try secondProvider.load(now: try date("2026-05-02T18:05:00Z"))

    XCTAssertEqual(refreshed.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(secondTransport.capturedRequests.map(\.url?.path), ["/graphql"])
    XCTAssertEqual(
      collector.events.first { $0.name == "discovery.cache_hit" }?.metadata["cache"],
      "persisted"
    )
    XCTAssertEqual(
      collector.events.first { $0.name == "graphql.total" }?.metadata["mode"],
      "incremental"
    )
  }

  func testProviderDoesNotReusePersistedDiscoveryAcrossTokens() throws {
    let stores = cacheStores(suiteName: "GitHubProviderDiscoveryTokenTests")
    let firstProvider = provider(token: "token-a", stores: stores)
    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z"),
      ]
    )
    let secondProvider = GitHubPRActivityProvider(
      token: "token-b",
      transport: secondTransport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )

    _ = try secondProvider.load(now: try date("2026-05-02T18:05:00Z"))

    XCTAssertEqual(secondTransport.capturedRequests.count, 4)
    XCTAssertEqual(secondTransport.capturedRequests.first?.url?.path, "/user/repos")
  }

  func testProviderFallsBackToLiveDiscoveryWhenPersistedPayloadIsCorrupt() throws {
    let stores = cacheStores(suiteName: "GitHubProviderDiscoveryCorruptTests")
    stores.defaults.set(Data("not-json".utf8), forKey: stores.discovery.cacheKey(token: "token"))
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )

    _ = try provider.load(now: try date("2026-05-02T18:05:00Z"))

    XCTAssertEqual(transport.capturedRequests.count, 4)
    XCTAssertEqual(transport.capturedRequests.first?.url?.path, "/user/repos")
  }

  func testProviderRevalidatesWithPersistedETagsWhenDiscoveryIsStale() throws {
    let stores = cacheStores(suiteName: "GitHubProviderDiscoveryStaleETagTests")
    let firstTransport = FixtureGitHubAPITransport(
      responses: [
        GitHubAPIResponse(data: repositoryDiscoveryData(), eTag: #""repos-v1""#),
        GitHubAPIResponse(data: authenticatedUserData(), eTag: #""user-v1""#),
        GitHubAPIResponse(data: organizationsData(), eTag: #""orgs-v1""#),
        GitHubAPIResponse(data: graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z")),
      ]
    )
    let firstProvider = GitHubPRActivityProvider(
      token: "token",
      transport: firstTransport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60,
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )
    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        GitHubAPIResponse(data: Data(), eTag: #""repos-v1""#, statusCode: 304),
        GitHubAPIResponse(data: Data(), eTag: #""user-v1""#, statusCode: 304),
        GitHubAPIResponse(data: Data(), eTag: #""orgs-v1""#, statusCode: 304),
        GitHubAPIResponse(data: graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z")),
      ]
    )
    let secondProvider = GitHubPRActivityProvider(
      token: "token",
      transport: secondTransport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60,
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )

    _ = try secondProvider.load(now: try date("2026-05-02T18:02:00Z"))

    XCTAssertEqual(secondTransport.capturedRequests.count, 4)
    XCTAssertEqual(
      secondTransport.capturedRequests[0].value(forHTTPHeaderField: "If-None-Match"),
      #""repos-v1""#
    )
    XCTAssertEqual(
      secondTransport.capturedRequests[1].value(forHTTPHeaderField: "If-None-Match"),
      #""user-v1""#
    )
    XCTAssertEqual(
      secondTransport.capturedRequests[2].value(forHTTPHeaderField: "If-None-Match"),
      #""orgs-v1""#
    )
  }

  func testRepositoryChangeAfterStaleDiscoveryForcesFullPullRequestSearch() throws {
    let stores = cacheStores(suiteName: "GitHubProviderDiscoveryRepositoryChangeTests")
    _ = try provider(token: "token", stores: stores)
      .load(now: try date("2026-05-02T18:00:00Z"))
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(
          repositories: [repositoryFixture(owner: "owner", name: "new", canPull: true)]
        ),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z", id: "PR_new"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60,
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )

    _ = try provider.load(now: try date("2026-05-02T18:02:00Z"))

    XCTAssertEqual(transport.capturedRequests.count, 4)
    XCTAssertTrue(
      bodyString(in: transport.capturedRequests[3])?
        .contains("merged:2026-04-25..2026-05-03") == true
    )
  }

  private func provider(
    token: String,
    stores: CacheStores
  ) -> GitHubPRActivityProvider {
    GitHubPRActivityProvider(
      token: token,
      transport: FixtureGitHubAPITransport(
        responses: [
          repositoryDiscoveryData(),
          authenticatedUserData(),
          organizationsData(),
          graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z"),
        ]
      ),
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60,
      mergedPullRequestCacheStore: stores.pullRequests,
      discoveryCacheStore: stores.discovery
    )
  }

  private func cacheStores(suiteName: String) -> CacheStores {
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return CacheStores(
      defaults: defaults,
      pullRequests: UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults),
      discovery: UserDefaultsGitHubDiscoveryCacheStore(defaults: defaults)
    )
  }

  private struct CacheStores {
    var defaults: UserDefaults
    var pullRequests: UserDefaultsGitHubMergedPullRequestCacheStore
    var discovery: UserDefaultsGitHubDiscoveryCacheStore
  }
}
