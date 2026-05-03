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
    XCTAssertEqual(
      transport.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"),
      "Bearer token"
    )
    XCTAssertEqual(transport.capturedRequests.last?.url?.path, "/search/issues")
  }

  func testProviderRejectsInvalidRepositoryPayload() {
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: FixtureGitHubAPITransport(data: Data("{}".utf8)),
      bucketLabels: ["W1"]
    )

    XCTAssertThrowsError(try provider.load(now: Date()))
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

  private func repositoryDiscoveryData() -> Data {
    Data(
      """
      [
        {
          "full_name": "owner/visible",
          "name": "visible",
          "owner": { "login": "owner" },
          "permissions": { "pull": true }
        },
        {
          "full_name": "owner/hidden",
          "name": "hidden",
          "owner": { "login": "owner" },
          "permissions": { "pull": false }
        }
      ]
      """.utf8
    )
  }

  private func mergedPullRequestData(totalCount: Int = 1, mergedAt: String) -> Data {
    Data(
      """
      {
        "total_count": \(totalCount),
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

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
