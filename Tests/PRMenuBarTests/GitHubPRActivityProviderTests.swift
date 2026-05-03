import XCTest

@testable import PRMenuBar

final class GitHubPRActivityProviderTests: XCTestCase {
  func testProviderLoadsPullableRepositoriesFromTransport() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        mergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1", "W2", "W3"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(store.repositories.first?.weeklyCounts, [0, 0, 1])
    XCTAssertEqual(store.bucketLabels, ["04/12", "04/19", "04/26"])
    XCTAssertEqual(store.refreshedAt, try date("2026-05-02T18:00:00Z"))
    XCTAssertEqual(transport.capturedRequests.count, 2)
    XCTAssertEqual(transport.capturedRequests.first?.url?.query?.contains("per_page=100"), true)
    XCTAssertEqual(
      transport.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"),
      "Bearer token"
    )
    XCTAssertEqual(transport.capturedRequests.last?.url?.path, "/search/issues")
    XCTAssertEqual(transport.capturedRequests.last?.url?.query?.contains("per_page=100"), true)
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
        mergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(transport.capturedRequests[0].url?.query?.contains("page=1"), true)
    XCTAssertEqual(transport.capturedRequests[1].url?.query?.contains("page=2"), true)
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
        mergedPullRequestData(totalCount: 2, mergedAt: "2026-04-26T12:00:00.000Z"),
        mergedPullRequestData(totalCount: 2, mergedAt: "2026-04-27T12:00:00.000Z"),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.first?.weeklyCounts, [2])
    XCTAssertEqual(transport.capturedRequests.count, 3)
    XCTAssertTrue(transport.capturedRequests[1].url?.query?.contains("page=1") ?? false)
    XCTAssertTrue(transport.capturedRequests[2].url?.query?.contains("page=2") ?? false)
  }

  func testProviderStopsMergedPullRequestPaginationOnEmptyPage() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        mergedPullRequestData(totalCount: 2, mergedAt: "2026-04-26T12:00:00.000Z"),
        emptyMergedPullRequestData(totalCount: 2),
      ]
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"]
    )

    let store = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    XCTAssertEqual(store.repositories.first?.weeklyCounts, [1])
    XCTAssertEqual(transport.capturedRequests.count, 3)
  }

  func testProviderRejectsIncompleteMergedPullRequestSearchResults() throws {
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        mergedPullRequestData(
          totalCount: 1,
          incompleteResults: true,
          mergedAt: "2026-04-26T12:00:00.000Z"
        ),
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
        .incompleteSearchResults(repositoryID: "owner/visible")
      )
    }
  }

  private func repositoryDiscoveryData() -> Data {
    repositoryDiscoveryData(
      repositories: [
        repositoryFixture(owner: "owner", name: "visible", canPull: true),
        repositoryFixture(owner: "owner", name: "hidden", canPull: false),
      ]
    )
  }

  private func repositoryDiscoveryData(repositories: [String]) -> Data {
    Data(
      "[\(repositories.joined(separator: ","))]".utf8
    )
  }

  private func repositoryFixture(owner: String, name: String, canPull: Bool) -> String {
    """
    {
      "full_name": "\(owner)/\(name)",
      "name": "\(name)",
      "owner": { "login": "\(owner)" },
      "permissions": { "pull": \(canPull) }
    }
    """
  }

  private func mergedPullRequestData(
    totalCount: Int = 1,
    incompleteResults: Bool = false,
    mergedAt: String
  ) -> Data {
    Data(
      """
      {
        "total_count": \(totalCount),
        "incomplete_results": \(incompleteResults),
        "items": [
          {
            "title": "Merged",
            "pull_request": {
              "merged_at": "\(mergedAt)"
            }
          }
        ]
      }
      """.utf8
    )
  }

  private func emptyMergedPullRequestData(totalCount: Int) -> Data {
    Data(
      """
      {
        "total_count": \(totalCount),
        "incomplete_results": false,
        "items": []
      }
      """.utf8
    )
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
