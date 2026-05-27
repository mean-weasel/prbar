import XCTest
@testable import PRBar

final class GitHubActivityTests: XCTestCase {
  func testGitHubPullRequestActivityRequestUsesClosedPullsEndpoint() throws {
    let request = try GitHubActivityRequest.pullRequests(
      repository: Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched"),
      token: "token",
      page: 2
    )

    XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/repos/mean-weasel/prbar/pulls?state=closed&sort=updated&direction=desc&per_page=100&page=2")
    XCTAssertEqual(request.httpMethod, "GET")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
  }

  func testGitHubReleaseAndTagActivityRequestsUseRepositoryEndpoints() throws {
    let repository = Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched")

    let releasesRequest = try GitHubActivityRequest.releases(repository: repository, token: "token", page: 1)
    let tagsRequest = try GitHubActivityRequest.tags(repository: repository, token: "token", page: 1)

    XCTAssertEqual(releasesRequest.url?.absoluteString, "https://api.github.com/repos/mean-weasel/prbar/releases?per_page=100&page=1")
    XCTAssertEqual(tagsRequest.url?.absoluteString, "https://api.github.com/repos/mean-weasel/prbar/tags?per_page=100&page=1")
  }

  func testGitHubActivityClientMapsMergedPullRequestsReleasesAndTags() throws {
    let sessionStore = InMemoryGitHubSessionStore(session: .fixture)
    let repository = Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched")
    let client = GitHubActivityClient(
      sessionStore: sessionStore,
      transport: FixtureGitHubRepositoryTransport(
        responses: [
          Data(
            """
            [
              {"id":39,"number":39,"title":"Connect live PR data","merged_at":"2026-05-24T17:42:00Z"},
              {"id":38,"number":38,"title":"Closed without merge","merged_at":null},
              {"id":37,"number":37,"title":"Older merge","merged_at":"2026-04-01T12:00:00Z"}
            ]
            """.utf8
          ),
          Data(
            """
            [
              {"id":140,"tag_name":"v1.4.0","name":"GitHub activity","body":"Live PR and release sync.","html_url":"https://github.com/mean-weasel/prbar/releases/tag/v1.4.0","published_at":"2026-05-23T10:30:00Z"}
            ]
            """.utf8
          ),
          Data(
            """
            [
              {"name":"v1.3.0","commit":{"sha":"abc123","url":"https://api.github.com/repos/mean-weasel/prbar/commits/abc123"}}
            ]
            """.utf8
          ),
          Data(
            """
            {"commit":{"committer":{"date":"2026-05-22T09:00:00Z"}},"html_url":"https://github.com/mean-weasel/prbar/commit/abc123"}
            """.utf8
          )
        ]
      )
    )

    let snapshot = try client.activity(
      for: [repository],
      endingAt: SampleData.date("2026-05-24"),
      lookbackDays: 30
    )

    XCTAssertEqual(snapshot.pullRequests.map(\.id), ["mean-weasel/prbar#39"])
    XCTAssertEqual(snapshot.pullRequests.first?.title, "Connect live PR data")
    XCTAssertEqual(snapshot.releases.map(\.id), ["mean-weasel/prbar@release:v1.4.0", "mean-weasel/prbar@tag:v1.3.0"])
    XCTAssertEqual(snapshot.releases.map(\.source), [.release, .tag])
    XCTAssertEqual(snapshot.anchorDate, SampleData.date("2026-05-24"))
  }

  func testGitHubActivityClientRequiresStoredSession() {
    let client = GitHubActivityClient(
      sessionStore: InMemoryGitHubSessionStore(),
      transport: FixtureGitHubRepositoryTransport(responses: [])
    )

    XCTAssertThrowsError(
      try client.activity(
        for: [Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched")],
        endingAt: SampleData.date("2026-05-24"),
        lookbackDays: 30
      )
    ) { error in
      XCTAssertEqual(error as? GitHubActivityError, .missingSession)
    }
  }

  func testGitHubAPIErrorMapperClassifiesRateLimitAndSSOResponses() {
    let resetDate = Date(timeIntervalSince1970: 1_779_904_000)

    XCTAssertEqual(
      GitHubAPIErrorMapper.error(
        statusCode: 403,
        headers: ["x-ratelimit-remaining": "0", "x-ratelimit-reset": "1779904000"],
        body: Data(#"{"message":"API rate limit exceeded"}"#.utf8)
      ),
      .rateLimited(resetAt: resetDate)
    )

    XCTAssertEqual(
      GitHubAPIErrorMapper.error(
        statusCode: 403,
        headers: [:],
        body: Data(#"{"message":"Resource protected by organization SAML enforcement"}"#.utf8)
      ),
      .ssoRequired
    )
  }

  func testGitHubAPIErrorMapperClassifiesNetworkFailures() {
    XCTAssertEqual(
      GitHubAPIErrorMapper.networkError(for: URLError(.notConnectedToInternet)) as? GitHubAPIError,
      .networkUnavailable
    )
    XCTAssertEqual(
      GitHubAPIErrorMapper.networkError(for: URLError(.timedOut)) as? GitHubAPIError,
      .timedOut
    )
  }
}
