import XCTest

@testable import PRMenuBar

final class GitHubGraphQLSearchTests: XCTestCase {
  func testMergedPullRequestsRequestBuildsGraphQLSearchBody() throws {
    let request = try GitHubGraphQLSearch.mergedPullRequestsRequest(
      token: "token",
      owner: GitHubSearchOwner(kind: .org, login: "mean-weasel"),
      mergedBy: "neonwatty",
      since: Date(timeIntervalSince1970: 0),
      until: Date(timeIntervalSince1970: 86_400),
      first: 50,
      after: "cursor"
    )

    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/graphql")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

    let body = try decodedBody(request)
    let variables = try XCTUnwrap(body["variables"] as? [String: Any])
    XCTAssertTrue((body["query"] as? String)?.contains("mergedBy") == true)
    XCTAssertEqual(
      variables["query"] as? String,
      "org:mean-weasel is:pr is:merged involves:neonwatty merged:1970-01-01..1970-01-03"
    )
    XCTAssertEqual(variables["first"] as? Int, 50)
    XCTAssertEqual(variables["after"] as? String, "cursor")
  }

  func testMergedPullRequestsRequestAllowsNilCursor() throws {
    let request = try GitHubGraphQLSearch.mergedPullRequestsRequest(
      token: "token",
      owner: GitHubSearchOwner(kind: .user, login: "neonwatty"),
      mergedBy: "neonwatty",
      since: Date(timeIntervalSince1970: 0),
      until: Date(timeIntervalSince1970: 0),
      first: 100,
      after: nil
    )

    let body = try decodedBody(request)
    let variables = try XCTUnwrap(body["variables"] as? [String: Any])
    XCTAssertEqual(
      variables["query"] as? String,
      "user:neonwatty is:pr is:merged involves:neonwatty merged:1970-01-01..1970-01-02"
    )
    XCTAssertFalse(variables.keys.contains("after"))
  }

  func testGraphQLResponseDecodesMergedPullRequestCandidate() throws {
    let data = Data(
      """
      {
        "data": {
          "search": {
            "pageInfo": { "hasNextPage": false, "endCursor": null },
            "nodes": [
              {
                "id": "PR_kwDOExample",
                "title": "Merged",
                "mergedAt": "2026-05-04T07:30:00Z",
                "mergedBy": { "login": "neonwatty" },
                "repository": { "nameWithOwner": "mean-weasel/deckchecker" }
              }
            ]
          }
        }
      }
      """.utf8
    )

    let response = try JSONDecoder().decode(GitHubGraphQLSearchResponse.self, from: data)
    let pullRequest = try XCTUnwrap(response.search?.nodes.first)

    XCTAssertEqual(pullRequest.mergedBy?.login, "neonwatty")
    XCTAssertEqual(pullRequest.id, "PR_kwDOExample")
    XCTAssertEqual(pullRequest.mergedPullRequest().repositoryID, "mean-weasel/deckchecker")
    XCTAssertEqual(pullRequest.mergedAt, try date("2026-05-04T07:30:00Z"))
  }

  private func decodedBody(_ request: URLRequest) throws -> [String: Any] {
    let data = try XCTUnwrap(request.httpBody)
    let json = try JSONSerialization.jsonObject(with: data)
    return try XCTUnwrap(json as? [String: Any])
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}
