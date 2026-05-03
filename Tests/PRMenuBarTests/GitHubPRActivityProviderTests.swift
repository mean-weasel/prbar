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

  private func mergedPullRequestData(mergedAt: String) -> Data {
    Data(
      """
      {
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
