import XCTest

@testable import PRMenuBar

final class ReleaseMomentProviderTests: XCTestCase {
  func testSampleProviderUsesExistingSampleRepositoryIDs() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let releases = try SampleReleaseMomentProvider().fetchReleaseMoments(
      repositories: RepositoryActivity.samples,
      now: now
    )
    let sampleRepositoryIDs = Set(RepositoryActivity.samples.map(\.id))

    XCTAssertFalse(releases.isEmpty)
    XCTAssertTrue(releases.allSatisfy { sampleRepositoryIDs.contains($0.repositoryID) })
    XCTAssertTrue(releases.contains { $0.source == .githubRelease })
    XCTAssertTrue(releases.contains { $0.source == .tag })
  }

  func testGitHubProviderUsesLatestReleaseWhenRepositoryHasRelease() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let transport = FixtureGitHubAPITransport(
      data: Data(
        """
        [
          {
            "id": 42,
            "tag_name": "v2.1.0",
            "name": "Webhook hardening",
            "body": "Fixes retry handling and clarifies release diagnostics.",
            "published_at": "2026-05-20T12:00:00Z",
            "html_url": "https://github.com/owner/project/releases/tag/v2.1.0"
          }
        ]
        """.utf8
      )
    )
    let provider = GitHubReleaseMomentProvider(
      token: "token",
      transport: transport,
      maxConcurrentRequests: 1
    )

    let releases = try provider.fetchReleaseMoments(
      repositories: [repository(id: "owner/project")],
      now: now
    )

    XCTAssertEqual(releases.count, 1)
    XCTAssertEqual(releases.first?.id, "release-owner/project-42")
    XCTAssertEqual(releases.first?.repositoryID, "owner/project")
    XCTAssertEqual(releases.first?.title, "Webhook hardening")
    XCTAssertEqual(releases.first?.tag, "v2.1.0")
    XCTAssertEqual(releases.first?.notes, "Fixes retry handling and clarifies release diagnostics.")
    XCTAssertEqual(releases.first?.source, .githubRelease)
    XCTAssertEqual(
      transport.capturedRequests.first?.url?.path,
      "/repos/owner/project/releases"
    )
  }

  func testGitHubProviderFallsBackToLatestTagWhenRepositoryHasNoReleases() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let transport = FixtureGitHubAPITransport(
      responses: [
        Data("[]".utf8),
        Data(
          """
          [
            { "name": "v1.0.0" }
          ]
          """.utf8
        ),
      ]
    )
    let provider = GitHubReleaseMomentProvider(
      token: "token",
      transport: transport,
      maxConcurrentRequests: 1
    )

    let releases = try provider.fetchReleaseMoments(
      repositories: [repository(id: "owner/project")],
      now: now
    )

    XCTAssertEqual(releases.count, 1)
    XCTAssertEqual(releases.first?.id, "tag-owner/project-v1.0.0")
    XCTAssertEqual(releases.first?.title, "Tagged version")
    XCTAssertEqual(releases.first?.tag, "v1.0.0")
    XCTAssertEqual(releases.first?.date, now)
    XCTAssertEqual(releases.first?.source, .tag)
    XCTAssertEqual(
      releases.first?.url,
      URL(string: "https://github.com/owner/project/releases/tag/v1.0.0")
    )
    XCTAssertEqual(
      transport.capturedRequests.map { $0.url?.path },
      [
        "/repos/owner/project/releases",
        "/repos/owner/project/tags",
      ]
    )
  }

  func testGitHubProviderReusesCachedReleaseMomentsWithinCacheDuration() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let transport = FixtureGitHubAPITransport(
      data: Data(
        """
        [
          {
            "id": 42,
            "tag_name": "v2.1.0",
            "name": "Webhook hardening",
            "body": "Fixes retry handling and clarifies release diagnostics.",
            "published_at": "2026-05-20T12:00:00Z",
            "html_url": "https://github.com/owner/project/releases/tag/v2.1.0"
          }
        ]
        """.utf8
      )
    )
    let provider = GitHubReleaseMomentProvider(
      token: "token",
      transport: transport,
      cacheDuration: 60,
      maxConcurrentRequests: 1
    )
    let repositories = [repository(id: "owner/project")]

    let first = try provider.fetchReleaseMoments(repositories: repositories, now: now)
    let second = try provider.fetchReleaseMoments(
      repositories: repositories,
      now: now.addingTimeInterval(30)
    )

    XCTAssertEqual(first, second)
    XCTAssertEqual(transport.capturedRequests.count, 1)
  }

  func testGitHubProviderRecordsReleaseFetchMetrics() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let collector = RefreshMetricsCollector()
    let transport = FixtureGitHubAPITransport(
      responses: [
        Data("[]".utf8),
        Data(#"[{ "name": "v1.0.0" }]"#.utf8),
      ]
    )
    let provider = GitHubReleaseMomentProvider(
      token: "token",
      transport: transport,
      maxConcurrentRequests: 1,
      metrics: collector
    )

    _ = try provider.fetchReleaseMoments(
      repositories: [repository(id: "owner/project")],
      now: now
    )

    let metric = try XCTUnwrap(collector.events.first { $0.name == "release.fetch.total" })
    XCTAssertEqual(metric.metadata["repository_count"], "1")
    XCTAssertEqual(metric.metadata["release_requests"], "1")
    XCTAssertEqual(metric.metadata["tag_requests"], "1")
    XCTAssertEqual(metric.metadata["moment_count"], "1")
    XCTAssertEqual(metric.metadata["max_concurrent_requests"], "1")
    XCTAssertEqual(metric.metadata["result"], "fetched")
  }

  func testGitHubProviderRecordsCacheHitMetrics() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let collector = RefreshMetricsCollector()
    let transport = FixtureGitHubAPITransport(
      data: Data(
        """
        [
          {
            "id": 42,
            "tag_name": "v2.1.0",
            "name": "Webhook hardening",
            "body": "Fixes retry handling and clarifies release diagnostics.",
            "published_at": "2026-05-20T12:00:00Z",
            "html_url": "https://github.com/owner/project/releases/tag/v2.1.0"
          }
        ]
        """.utf8
      )
    )
    let provider = GitHubReleaseMomentProvider(
      token: "token",
      transport: transport,
      cacheDuration: 60,
      maxConcurrentRequests: 1,
      metrics: collector
    )
    let repositories = [repository(id: "owner/project")]

    _ = try provider.fetchReleaseMoments(repositories: repositories, now: now)
    _ = try provider.fetchReleaseMoments(
      repositories: repositories,
      now: now.addingTimeInterval(30)
    )

    let metric = try XCTUnwrap(collector.events.last { $0.name == "release.fetch.total" })
    XCTAssertEqual(metric.metadata["repository_count"], "1")
    XCTAssertEqual(metric.metadata["release_requests"], "0")
    XCTAssertEqual(metric.metadata["tag_requests"], "0")
    XCTAssertEqual(metric.metadata["moment_count"], "1")
    XCTAssertEqual(metric.metadata["result"], "cache_hit")
  }

  func testRepositoryPrivateFlagMapsToActivityPrivacy() throws {
    let data = Data(
      """
      {
        "full_name": "owner/private",
        "name": "private",
        "private": true,
        "owner": { "login": "owner" },
        "permissions": { "pull": true }
      }
      """.utf8
    )

    let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)
    let activity = repository.activity(bucketCount: 1)

    XCTAssertTrue(activity.isPrivate)
  }

  private func repository(id: String) -> RepositoryActivity {
    let parts = id.split(separator: "/", maxSplits: 1).map(String.init)
    return RepositoryActivity(
      id: id,
      owner: parts[0],
      name: parts[1],
      colorHex: "#818cf8",
      weeklyCounts: [0],
      dailyCounts: [],
      isIncluded: true
    )
  }
}
