import XCTest

@testable import PRMenuBar

final class GitHubPRActivityProviderTests: XCTestCase {
  func testProviderLoadsPullableRepositoriesFromTransport() throws {
    let transport = FixtureGitHubAPITransport(
      data: Data(
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
    )
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1", "W2", "W3"]
    )

    let store = try provider.load(now: Date(timeIntervalSince1970: 10))

    XCTAssertEqual(store.repositories.map(\.id), ["owner/visible"])
    XCTAssertEqual(store.repositories.first?.weeklyCounts, [0, 0, 0])
    XCTAssertEqual(store.refreshedAt, Date(timeIntervalSince1970: 10))
    XCTAssertEqual(transport.capturedRequests.count, 1)
    XCTAssertEqual(
      transport.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"),
      "Bearer token"
    )
  }

  func testProviderRejectsInvalidRepositoryPayload() {
    let provider = GitHubPRActivityProvider(
      token: "token",
      transport: FixtureGitHubAPITransport(data: Data("{}".utf8)),
      bucketLabels: ["W1"]
    )

    XCTAssertThrowsError(try provider.load(now: Date()))
  }
}
