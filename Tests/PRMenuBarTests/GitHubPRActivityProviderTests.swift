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
    XCTAssertEqual(store.repositories.first?.dailyCounts.suffix(7).reduce(0, +), 1)
    XCTAssertEqual(store.bucketLabels, ["04/12", "04/19", "04/26"])
    XCTAssertEqual(store.dailyBucketLabels.count, 30)
    XCTAssertEqual(store.window, .oneWeek)
    XCTAssertEqual(store.bin, .day)
    XCTAssertEqual(store.refreshedAt, try date("2026-05-02T18:00:00Z"))
    XCTAssertEqual(transport.capturedRequests.count, 2)
    XCTAssertEqual(queryValue("per_page", in: transport.capturedRequests[0]), "100")
    XCTAssertEqual(
      transport.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"),
      "Bearer token"
    )
    XCTAssertEqual(transport.capturedRequests.last?.url?.path, "/search/issues")
    XCTAssertEqual(queryValue("per_page", in: transport.capturedRequests[1]), "100")
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
    XCTAssertEqual(queryValue("page", in: transport.capturedRequests[1]), "1")
    XCTAssertEqual(queryValue("page", in: transport.capturedRequests[2]), "2")
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

  private func queryValue(_ name: String, in request: URLRequest) -> String? {
    guard
      let url = request.url,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      return nil
    }
    return components.queryItems?.first { $0.name == name }?.value
  }
}
