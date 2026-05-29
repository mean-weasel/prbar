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

  func testGitHubActivityClientStopsScanningClosedPullsWhenUpdatedPageIsStale() throws {
    let sessionStore = InMemoryGitHubSessionStore(session: .fixture)
    let repository = Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched")
    let stalePulls = (1...100)
      .map { index in
        #"{"id":\#(index),"number":\#(index),"title":"Old closed PR","merged_at":null,"updated_at":"2026-03-01T12:00:00Z"}"#
      }
      .joined(separator: ",")
    let transport = RecordingActivityTransport(
      responses: [
        Data("[\(stalePulls)]".utf8),
        Data("[]".utf8),
        Data("[]".utf8)
      ]
    )
    let client = GitHubActivityClient(sessionStore: sessionStore, transport: transport)

    let snapshot = try client.activity(for: [repository], endingAt: SampleData.date("2026-05-24"), lookbackDays: 30)

    XCTAssertTrue(snapshot.pullRequests.isEmpty)
    XCTAssertEqual(
      transport.requests.map { $0.url?.path },
      [
        "/repos/mean-weasel/prbar/pulls",
        "/repos/mean-weasel/prbar/releases",
        "/repos/mean-weasel/prbar/tags"
      ]
    )
  }

  func testGitHubActivityClientStopsScanningReleasePagesWhenPageIsStale() throws {
    let sessionStore = InMemoryGitHubSessionStore(session: .fixture)
    let repository = Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched")
    let oldReleases = (1...100)
      .map { index in
        #"{"id":\#(index),"tag_name":"v0.\#(index).0","name":"Old release","body":"","html_url":"https://github.com/mean-weasel/prbar/releases/tag/v0.\#(index).0","published_at":"2026-03-01T12:00:00Z"}"#
      }
      .joined(separator: ",")
    let transport = RecordingActivityTransport(
      responses: [
        Data("[]".utf8),
        Data("[\(oldReleases)]".utf8),
        Data("[]".utf8)
      ]
    )
    let client = GitHubActivityClient(sessionStore: sessionStore, transport: transport)

    let snapshot = try client.activity(for: [repository], endingAt: SampleData.date("2026-05-24"), lookbackDays: 30)

    XCTAssertTrue(snapshot.releases.isEmpty)
    XCTAssertEqual(
      transport.requests.map { $0.url?.path },
      [
        "/repos/mean-weasel/prbar/pulls",
        "/repos/mean-weasel/prbar/releases",
        "/repos/mean-weasel/prbar/tags"
      ]
    )
  }

  func testGitHubActivityClientCapsTagScanToFirstPage() throws {
    let sessionStore = InMemoryGitHubSessionStore(session: .fixture)
    let repository = Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched")
    let releases = (1...100)
      .map { index in
        #"{"id":\#(index),"tag_name":"v1.\#(index).0","name":"Release","body":"","html_url":"https://github.com/mean-weasel/prbar/releases/tag/v1.\#(index).0","published_at":"2026-05-23T12:00:00Z"}"#
      }
      .joined(separator: ",")
    let tags = (1...100)
      .map { index in
        #"{"name":"v1.\#(index).0","commit":{"sha":"abc\#(index)","url":"https://api.github.com/repos/mean-weasel/prbar/commits/abc\#(index)"}}"#
      }
      .joined(separator: ",")
    let transport = RecordingActivityTransport(
      responses: [
        Data("[]".utf8),
        Data("[\(releases)]".utf8),
        Data("[]".utf8),
        Data("[\(tags)]".utf8)
      ]
    )
    let client = GitHubActivityClient(sessionStore: sessionStore, transport: transport)

    let snapshot = try client.activity(for: [repository], endingAt: SampleData.date("2026-05-24"), lookbackDays: 30)

    XCTAssertEqual(snapshot.releases.count, 100)
    XCTAssertEqual(
      transport.requests.map { $0.url?.absoluteString },
      [
        "https://api.github.com/repos/mean-weasel/prbar/pulls?state=closed&sort=updated&direction=desc&per_page=100&page=1",
        "https://api.github.com/repos/mean-weasel/prbar/releases?per_page=100&page=1",
        "https://api.github.com/repos/mean-weasel/prbar/releases?per_page=100&page=2",
        "https://api.github.com/repos/mean-weasel/prbar/tags?per_page=100&page=1"
      ]
    )
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

  func testFileGitHubActivityCacheStoreRoundTripsMatchingRecord() throws {
    let fileURL = temporaryCacheURL()
    let store = FileGitHubActivityCacheStore(fileURL: fileURL)
    let record = GitHubActivityCacheRecord(
      githubLogin: "neonwatty",
      includedRepositoryIDs: ["launch-kit", "prbar"],
      snapshot: SampleData.activitySnapshot,
      lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z")
    )

    try store.save(record)

    XCTAssertEqual(
      try store.load(githubLogin: "neonwatty", includedRepositoryIDs: ["prbar", "launch-kit"]),
      record
    )
    XCTAssertNil(try store.load(githubLogin: "octocat", includedRepositoryIDs: ["prbar", "launch-kit"]))
    XCTAssertNil(try store.load(githubLogin: "neonwatty", includedRepositoryIDs: ["prbar"]))
  }

  func testFileGitHubActivityCacheStoreIgnoresUnsupportedVersion() throws {
    let fileURL = temporaryCacheURL()
    let store = FileGitHubActivityCacheStore(fileURL: fileURL)
    let record = GitHubActivityCacheRecord(
      githubLogin: "neonwatty",
      includedRepositoryIDs: ["prbar"],
      snapshot: SampleData.activitySnapshot,
      lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
      version: 999
    )

    try store.save(record)

    XCTAssertNil(try store.load(githubLogin: "neonwatty", includedRepositoryIDs: ["prbar"]))
  }

  func testFileGitHubActivityCacheStoreThrowsForCorruptCache() throws {
    let fileURL = temporaryCacheURL()
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("not-json".utf8).write(to: fileURL)

    let store = FileGitHubActivityCacheStore(fileURL: fileURL)

    XCTAssertThrowsError(try store.load(githubLogin: "neonwatty", includedRepositoryIDs: ["prbar"]))
  }

  func testFileGitHubActivityCacheStoreClearsCacheFile() throws {
    let fileURL = temporaryCacheURL()
    let store = FileGitHubActivityCacheStore(fileURL: fileURL)
    let record = GitHubActivityCacheRecord(
      githubLogin: "neonwatty",
      includedRepositoryIDs: ["prbar"],
      snapshot: SampleData.activitySnapshot,
      lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z")
    )

    try store.save(record)
    try store.clear()

    XCTAssertNil(try store.load(githubLogin: "neonwatty", includedRepositoryIDs: ["prbar"]))
  }

  private func temporaryCacheURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
      .appendingPathComponent("GitHubActivityCache.json")
  }
}

private final class RecordingActivityTransport: GitHubRepositoryTransport {
  private var responses: [Data]
  private(set) var requests: [URLRequest] = []

  init(responses: [Data]) {
    self.responses = responses
  }

  func data(for request: URLRequest) throws -> Data {
    requests.append(request)
    guard responses.isEmpty == false else {
      throw GitHubRepositoryError.invalidResponse
    }
    return responses.removeFirst()
  }
}
