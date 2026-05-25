import Foundation
import XCTest

@testable import PRMenuBar

final class RefreshBenchmarkTests: XCTestCase {
  func testFixtureBackedRefreshBenchmarkReport() throws {
    let report = try RefreshBenchmarkReport(
      generatedAt: "fixture-backed",
      scenarios: [
        coldRefreshScenario(),
        cacheHitRefreshScenario(),
        cacheExpiredRefreshScenario(),
      ]
    )

    XCTAssertEqual(report.scenarios[0].requestCount, 4)
    XCTAssertEqual(report.scenarios[1].requestCount, 1)
    XCTAssertEqual(report.scenarios[2].requestCount, 4)
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
      "2026-05-02T18:00:00Z"
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

  private func provider(
    transport: FixtureGitHubAPITransport,
    metrics: RefreshMetricsCollector
  ) -> GitHubPRActivityProvider {
    GitHubPRActivityProvider(
      token: "token",
      transport: transport,
      bucketLabels: ["W1"],
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

  private func repositoryDiscoveryData() -> Data {
    Data(
      """
      [
        {
          "full_name": "owner/visible",
          "name": "visible",
          "owner": { "login": "owner" },
          "permissions": { "pull": true }
        }
      ]
      """.utf8
    )
  }

  private func authenticatedUserData() -> Data {
    Data(#"{ "login": "owner" }"#.utf8)
  }

  private func organizationsData() -> Data {
    Data("[]".utf8)
  }

  private func graphQLMergedPullRequestData(mergedAt: String) -> Data {
    Data(
      """
      {
        "data": {
          "search": {
            "pageInfo": { "hasNextPage": false, "endCursor": null },
            "nodes": [
              {
                "id": "PR_\(mergedAt)",
                "title": "Merged",
                "mergedAt": "\(mergedAt)",
                "mergedBy": { "login": "owner" },
                "repository": { "nameWithOwner": "owner/visible" }
              }
            ]
          }
        }
      }
      """.utf8
    )
  }

  private func response(_ data: Data, eTag: String? = nil) -> GitHubAPIResponse {
    GitHubAPIResponse(data: data, eTag: eTag, statusCode: 200)
  }

  private func notModified(eTag: String) -> GitHubAPIResponse {
    GitHubAPIResponse(data: Data(), eTag: eTag, statusCode: 304)
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
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

private struct RefreshBenchmarkReport: Codable {
  var generatedAt: String
  var scenarios: [RefreshBenchmarkScenario]
}

private struct RefreshBenchmarkScenario: Codable {
  var name: String
  var requestCount: Int
  var requestsByPath: [String: Int]
  var metrics: [RefreshMetricEvent]

  var metricNames: [String] {
    metrics.map(\.name)
  }

  func metric(named name: String) -> RefreshMetricEvent? {
    metrics.first { $0.name == name }
  }
}

extension JSONEncoder {
  fileprivate static var prettyBenchmark: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }
}
