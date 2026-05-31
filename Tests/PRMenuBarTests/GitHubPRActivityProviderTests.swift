import XCTest

@testable import PRMenuBar

final class GitHubPRActivityProviderTests: XCTestCase, GitHubPRActivityProviderTestHelpers {
  func testProviderLoadsPullableRepositoriesFromTransport() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1", "W2", "W3"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.map(\.id), ["owner/visible"])
    XCTAssertFalse(try XCTUnwrap(store.repositories.first).isIncluded)
    XCTAssertEqual(store.repositories.first?.weeklyCounts, [0, 0, 1])
    XCTAssertEqual(store.repositories.first?.dailyCounts.suffix(7).reduce(0, +), 1)
    XCTAssertEqual(store.bucketLabels, ["04/12", "04/19", "04/26"])
    XCTAssertEqual(store.dailyBucketLabels.count, 30)
    XCTAssertEqual(store.window, .oneWeek)
    XCTAssertEqual(store.bin, .day)
    XCTAssertEqual(store.refreshedAt, try date("2026-05-02T18:00:00Z"))
    XCTAssertEqual(transport.capturedRequests.count, 4)
    XCTAssertEqual(queryValue("per_page", in: transport.capturedRequests[0]), "100")
    XCTAssertEqual(
      transport.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"),
      "Bearer token"
    )
    XCTAssertEqual(transport.capturedRequests[1].url?.path, "/user")
    XCTAssertEqual(transport.capturedRequests[2].url?.path, "/user/orgs")
    XCTAssertEqual(transport.capturedRequests[3].url?.path, "/graphql")
    XCTAssertEqual(transport.capturedRequests[3].httpMethod, "POST")
  }

  func testProviderRejectsInvalidRepositoryPayload() {
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: FixtureGitHubAPITransport(data: Data("{}".utf8)),
      bucketLabels: ["W1"]
    )

    XCTAssertThrowsError(try provider.load(now: Date()))
  }

  func testProviderFetchesAdditionalRepositoryDiscoveryPages() throws {
    let firstPage = repositoryDiscoveryData(
      repositories: (0..<100).map { index in
        repositoryFixture(owner: "owner", name: "repo-\(index)", canPull: false)
      }
    )
    let secondPage = repositoryDiscoveryData(
      repositories: [
        repositoryFixture(owner: "owner", name: "visible", canPull: true)
      ]
    )
    let transport = FixtureGitHubAPITransport(
      responses: [
        firstPage,
        secondPage,
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(queryValue("page", in: transport.capturedRequests[0]), "1")
    XCTAssertEqual(queryValue("page", in: transport.capturedRequests[1]), "2")
  }

  func testProviderSkipsSearchWhenNoRepositoriesArePullable() throws {
    let transport = FixtureGitHubAPITransport(
      data: repositoryDiscoveryData(
        repositories: [
          repositoryFixture(owner: "owner", name: "hidden", canPull: false)
        ]
      )
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertTrue(store.repositories.isEmpty)
    XCTAssertEqual(transport.capturedRequests.count, 1)
  }

  func testProviderFetchesAdditionalMergedPullRequestPages() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-26T12:00:00.000Z",
          hasNextPage: true,
          endCursor: "cursor-1"
        ),
        graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.first?.weeklyCounts, [2])
    XCTAssertEqual(transport.capturedRequests.count, 5)
    XCTAssertTrue(bodyString(in: transport.capturedRequests[4])?.contains("cursor-1") == true)
  }

  func testProviderReusesDiscoveryWithinCacheDuration() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
        graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60
    )

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    let refreshed = try provider.load(now: try date("2026-05-02T18:00:30Z"))

    XCTAssertEqual(refreshed.repositories.first?.weeklyCounts, [2])
    XCTAssertEqual(transport.capturedRequests.count, 5)
    XCTAssertEqual(transport.capturedRequests[4].url?.path, "/graphql")
  }

  func testProviderRediscoversRepositoriesAfterCacheDuration() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
        repositoryDiscoveryData(
          repositories: [
            repositoryFixture(owner: "owner", name: "new", canPull: true)
          ]
        ),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60
    )

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    let refreshed = try provider.load(now: try date("2026-05-02T18:02:00Z"))

    XCTAssertEqual(refreshed.repositories.map(\.id), ["owner/new"])
    XCTAssertEqual(transport.capturedRequests.count, 8)
    XCTAssertEqual(transport.capturedRequests[4].url?.path, "/user/repos")
  }

  func testProviderUsesConditionalDiscoveryRequestsAfterCacheDuration() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        GitHubAPIResponse(data: repositoryDiscoveryData(), eTag: #""repos-v1""#),
        GitHubAPIResponse(data: authenticatedUserData(), eTag: #""user-v1""#),
        GitHubAPIResponse(data: organizationsData(), eTag: #""orgs-v1""#),
        GitHubAPIResponse(data: graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z")),
        GitHubAPIResponse(data: Data(), eTag: #""repos-v1""#, statusCode: 304),
        GitHubAPIResponse(data: Data(), eTag: #""user-v1""#, statusCode: 304),
        GitHubAPIResponse(data: Data(), eTag: #""orgs-v1""#, statusCode: 304),
        GitHubAPIResponse(data: graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z")),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      discoveryCacheDuration: 60
    )

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    let refreshed = try provider.load(now: try date("2026-05-02T18:02:00Z"))

    XCTAssertEqual(refreshed.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(transport.capturedRequests.count, 8)
    XCTAssertEqual(
      transport.capturedRequests[4].value(forHTTPHeaderField: "If-None-Match"),
      #""repos-v1""#
    )
    XCTAssertEqual(
      transport.capturedRequests[5].value(forHTTPHeaderField: "If-None-Match"),
      #""user-v1""#
    )
    XCTAssertEqual(
      transport.capturedRequests[6].value(forHTTPHeaderField: "If-None-Match"),
      #""orgs-v1""#
    )
  }

  func testProviderFiltersMergedPullRequestsByMerger() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(
          mergedAt: "2026-04-26T12:00:00.000Z",
          mergedBy: "someone-else"
        ),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.first?.weeklyCounts, [0])
  }

  func testProviderRejectsGraphQLErrors() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLErrorData(message: "Search failed"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    XCTAssertThrowsError(try provider.load(now: try date("2026-05-02T18:00:00Z"))) { error in
      XCTAssertEqual(
        error as? GitHubPRActivityProviderError,
        .graphQL("Search failed")
      )
    }
  }
}
