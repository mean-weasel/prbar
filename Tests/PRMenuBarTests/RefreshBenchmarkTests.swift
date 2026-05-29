import Foundation
import XCTest

@testable import PRMenuBar

final class RefreshBenchmarkTests: XCTestCase, GitHubPRActivityProviderTestHelpers {
  func testFixtureBackedRefreshBenchmarkReport() throws {
    let report = try RefreshBenchmarkReport(
      generatedAt: "fixture-backed",
      scenarios: [
        coldRefreshScenario(),
        cacheHitRefreshScenario(),
        cacheExpiredRefreshScenario(),
        persistedCacheRefreshScenario(),
        persistedDiscoveryCacheRefreshScenario(),
      ]
    )

    XCTAssertEqual(report.scenarios[0].requestCount, 4)
    XCTAssertEqual(report.scenarios[1].requestCount, 1)
    XCTAssertEqual(report.scenarios[2].requestCount, 4)
    XCTAssertEqual(report.scenarios[3].requestCount, 4)
    XCTAssertEqual(report.scenarios[4].requestCount, 1)
    XCTAssertTrue(report.scenarios[1].metricNames.contains("discovery.cache_hit"))
    XCTAssertFalse(report.scenarios[1].metricNames.contains("discovery.repositories.page"))
    XCTAssertEqual(
      report.scenarios[2].metrics.filter {
        $0.name == "http.conditional" && $0.metadata["result"] == "not_modified"
      }
      .count,
      3
    )
    XCTAssertEqual(
      report.scenarios[1].metric(named: "graphql.total")?.metadata["mode"],
      "incremental"
    )
    XCTAssertEqual(
      report.scenarios[1].metric(named: "graphql.total")?.metadata["since"],
      "2026-05-02T17:30:00Z"
    )
    XCTAssertEqual(
      report.scenarios[2].metric(named: "graphql.total")?.metadata["mode"],
      "incremental"
    )
    XCTAssertEqual(
      report.scenarios[2].metric(named: "graphql.total")?.metadata["since"],
      "2026-05-02T17:30:00Z"
    )
    XCTAssertEqual(
      report.scenarios[3].metric(named: "graphql.total")?.metadata["mode"],
      "incremental"
    )
    XCTAssertEqual(
      report.scenarios[3].metric(named: "graphql.total")?.metadata["since"],
      "2026-05-02T17:30:00Z"
    )
    XCTAssertEqual(
      report.scenarios[4].requestsByPath,
      ["/graphql": 1]
    )
    XCTAssertEqual(
      report.scenarios[4].metric(named: "graphql.total")?.metadata["mode"],
      "incremental"
    )

    let url = benchmarkReportURL()
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let data = try JSONEncoder.prettyBenchmark.encode(report)
    try data.write(to: url, options: .atomic)
  }

  private func coldRefreshScenario() throws -> RefreshBenchmarkScenario {
    let collector = RefreshMetricsCollector()
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
      ]
    )
    let provider = provider(transport: transport, metrics: collector)

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))

    return scenario(
      name: "cold_refresh",
      requests: transport.capturedRequests,
      metrics: collector.events
    )
  }

  private func cacheHitRefreshScenario() throws -> RefreshBenchmarkScenario {
    let collector = RefreshMetricsCollector()
    let transport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
        graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z"),
      ]
    )
    let provider = provider(transport: transport, metrics: collector)

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    let warmupRequestCount = transport.capturedRequests.count
    collector.reset()
    _ = try provider.load(now: try date("2026-05-02T18:05:00Z"))

    return scenario(
      name: "cache_hit_refresh",
      requests: Array(transport.capturedRequests.dropFirst(warmupRequestCount)),
      metrics: collector.events
    )
  }

  private func cacheExpiredRefreshScenario() throws -> RefreshBenchmarkScenario {
    let collector = RefreshMetricsCollector()
    let transport = FixtureGitHubAPITransport(
      responses: [
        response(repositoryDiscoveryData(), eTag: #""repos-v1""#),
        response(authenticatedUserData(), eTag: #""user-v1""#),
        response(organizationsData(), eTag: #""orgs-v1""#),
        response(graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z")),
        notModified(eTag: #""repos-v1""#),
        notModified(eTag: #""user-v1""#),
        notModified(eTag: #""orgs-v1""#),
        response(graphQLMergedPullRequestData(mergedAt: "2026-04-27T12:00:00.000Z")),
      ]
    )
    let provider = provider(transport: transport, metrics: collector)

    _ = try provider.load(now: try date("2026-05-02T18:00:00Z"))
    let warmupRequestCount = transport.capturedRequests.count
    collector.reset()
    _ = try provider.load(now: try date("2026-05-02T18:16:00Z"))

    return scenario(
      name: "cache_expired_refresh",
      requests: Array(transport.capturedRequests.dropFirst(warmupRequestCount)),
      metrics: collector.events
    )
  }

  private func persistedCacheRefreshScenario() throws -> RefreshBenchmarkScenario {
    let defaults = UserDefaults(suiteName: "RefreshBenchmarkPersistedCache")!
    defaults.removePersistentDomain(forName: "RefreshBenchmarkPersistedCache")
    let cacheStore = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)
    let firstTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
      ]
    )
    let firstProvider = provider(
      transport: firstTransport,
      metrics: RefreshMetricsCollector(),
      cacheStore: cacheStore
    )

    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let collector = RefreshMetricsCollector()
    let secondTransport = FixtureGitHubAPITransport(
      responses: [
        repositoryDiscoveryData(),
        authenticatedUserData(),
        organizationsData(),
        graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z"),
      ]
    )
    let restartedProvider = provider(
      transport: secondTransport,
      metrics: collector,
      cacheStore: cacheStore
    )

    _ = try restartedProvider.load(now: try date("2026-05-02T18:05:00Z"))

    return scenario(
      name: "persisted_cache_refresh",
      requests: secondTransport.capturedRequests,
      metrics: collector.events
    )
  }

  private func persistedDiscoveryCacheRefreshScenario() throws -> RefreshBenchmarkScenario {
    let defaults = UserDefaults(suiteName: "RefreshBenchmarkPersistedDiscoveryCache")!
    defaults.removePersistentDomain(forName: "RefreshBenchmarkPersistedDiscoveryCache")
    let pullRequestCacheStore = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)
    let discoveryCacheStore = UserDefaultsGitHubDiscoveryCacheStore(defaults: defaults)
    let firstProvider = provider(
      transport: FixtureGitHubAPITransport(
        responses: [
          repositoryDiscoveryData(),
          authenticatedUserData(),
          organizationsData(),
          graphQLMergedPullRequestData(mergedAt: "2026-04-26T12:00:00.000Z"),
        ]
      ),
      metrics: RefreshMetricsCollector(),
      cacheStore: pullRequestCacheStore,
      discoveryCacheStore: discoveryCacheStore
    )
    _ = try firstProvider.load(now: try date("2026-05-02T18:00:00Z"))

    let collector = RefreshMetricsCollector()
    let transport = FixtureGitHubAPITransport(
      responses: [
        graphQLMergedPullRequestData(mergedAt: "2026-05-02T18:04:00.000Z")
      ]
    )
    let restartedProvider = provider(
      transport: transport,
      metrics: collector,
      cacheStore: pullRequestCacheStore,
      discoveryCacheStore: discoveryCacheStore
    )
    _ = try restartedProvider.load(now: try date("2026-05-02T18:05:00Z"))

    return scenario(
      name: "persisted_discovery_cache_refresh",
      requests: transport.capturedRequests,
      metrics: collector.events
    )
  }

  private func provider(
    transport: FixtureGitHubAPITransport,
    metrics: RefreshMetricsCollector,
    cacheStore: GitHubMergedPullRequestCacheStoring? = nil,
    discoveryCacheStore: GitHubDiscoveryCacheStoring? = nil
  ) -> GitHubPRActivityProvider {
    GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
      mergedPullRequestCacheStore: cacheStore,
      discoveryCacheStore: discoveryCacheStore,
      metrics: metrics
    )
  }

  private func scenario(
    name: String,
    requests: [URLRequest],
    metrics: [RefreshMetricEvent]
  ) -> RefreshBenchmarkScenario {
    RefreshBenchmarkScenario(
      name: name,
      requestCount: requests.count,
      requestsByPath: Dictionary(grouping: requests.compactMap(\.url?.path)) { $0 }
        .mapValues(\.count),
      metrics: metrics
    )
  }

  private func response(_ data: Data, eTag: String? = nil) -> GitHubAPIResponse {
    GitHubAPIResponse(data: data, eTag: eTag, statusCode: 200)
  }

  private func notModified(eTag: String) -> GitHubAPIResponse {
    GitHubAPIResponse(data: Data(), eTag: eTag, statusCode: 304)
  }

  private func benchmarkReportURL() -> URL {
    if let path = ProcessInfo.processInfo.environment["PR_MENU_BAR_REFRESH_BENCHMARK_REPORT"] {
      return URL(fileURLWithPath: path)
    }
    return URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("build/refresh-benchmark.json")
  }
}
