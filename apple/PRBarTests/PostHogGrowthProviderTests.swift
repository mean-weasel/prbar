import XCTest
@testable import PRBar

final class PostHogGrowthProviderTests: XCTestCase {
  func testPostHogConfigurationReadsLiveEnvironment() {
    let configuration = PostHogConfiguration.live(
      environment: [
        "PRBAR_IOS_POSTHOG_HOST": "https://eu.posthog.com",
        "PRBAR_IOS_POSTHOG_PROJECT_ID": "12345",
        "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
      ]
    )

    XCTAssertEqual(configuration?.host.absoluteString, "https://eu.posthog.com")
    XCTAssertEqual(configuration?.projectID, "12345")
    XCTAssertEqual(configuration?.personalAPIKey, "phx_live")
  }

  func testPostHogConfigurationDefaultsToUSHost() {
    let configuration = PostHogConfiguration.live(
      environment: [
        "PRBAR_IOS_POSTHOG_PROJECT_ID": "12345",
        "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
      ]
    )

    XCTAssertEqual(configuration?.host.absoluteString, "https://us.posthog.com")
  }

  func testPostHogConfigurationRequiresProjectIDAndPersonalAPIKey() {
    XCTAssertNil(
      PostHogConfiguration.live(
        environment: ["PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live"]
      )
    )
    XCTAssertNil(
      PostHogConfiguration.live(
        environment: ["PRBAR_IOS_POSTHOG_PROJECT_ID": "12345"]
      )
    )
    XCTAssertNil(
      PostHogConfiguration.live(
        environment: [
          "PRBAR_IOS_POSTHOG_PROJECT_ID": "  ",
          "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
        ]
      )
    )
  }

  func testPostHogDiagnosticsSummarizeConfiguredLiveConnection() {
    let snapshot = GrowthDashboardSnapshot.fixture(range: .week)
    let diagnostics = PostHogConnectionDiagnostics.current(
      environment: [
        "PRBAR_IOS_POSTHOG_HOST": "https://eu.posthog.com",
        "PRBAR_IOS_POSTHOG_PROJECT_ID": "12345",
        "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
      ],
      snapshot: snapshot
    )

    XCTAssertEqual(diagnostics.status, "Connected")
    XCTAssertEqual(diagnostics.configuration, "Configured")
    XCTAssertEqual(diagnostics.host, "https://eu.posthog.com")
    XCTAssertEqual(diagnostics.projectID, "12345")
    XCTAssertEqual(diagnostics.personalAPIKey, "Configured")
    XCTAssertNil(diagnostics.issue)
  }

  func testPostHogDiagnosticsSummarizeMissingLiveConfiguration() {
    let snapshot = GrowthDashboardSnapshot.fixture(
      range: .week,
      connections: [
        GrowthConnection(id: "posthog-main", provider: .postHog, displayName: "PostHog", status: .notConnected, lastRefreshedAt: nil, issue: nil),
        GrowthConnection(id: "gsc-main", provider: .searchConsole, displayName: "Search Console", status: .connected, lastRefreshedAt: nil, issue: nil),
      ]
    )
    let diagnostics = PostHogConnectionDiagnostics.current(environment: [:], snapshot: snapshot)

    XCTAssertEqual(diagnostics.status, "Not connected")
    XCTAssertEqual(diagnostics.configuration, "Missing")
    XCTAssertEqual(diagnostics.host, "Default")
    XCTAssertEqual(diagnostics.projectID, "Missing")
    XCTAssertEqual(diagnostics.personalAPIKey, "Missing")
  }

  func testPostHogQueryRequestUsesProjectQueryEndpointAndBearerToken() throws {
    let configuration = PostHogConfiguration(
      host: URL(string: "https://us.posthog.com")!,
      projectID: "12345",
      personalAPIKey: "phx_test"
    )

    let request = try PostHogQueryRequest.query(
      configuration: configuration,
      sql: "SELECT count() FROM events"
    )

    XCTAssertEqual(request.url?.absoluteString, "https://us.posthog.com/api/projects/12345/query/")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer phx_test")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    let body = try XCTUnwrap(request.httpBody)
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    let query = try XCTUnwrap(json?["query"] as? [String: Any])
    XCTAssertEqual(query["kind"] as? String, "HogQLQuery")
    XCTAssertEqual(query["query"] as? String, "SELECT count() FROM events")
  }

  func testPostHogGrowthProviderMapsDailyMetricsAndTopEvents() async throws {
    let transport = FixturePostHogQueryTransport(responses: [
      """
      {
        "results": [
          ["2026-05-18", 2, 5],
          ["2026-05-19", 4, 8],
          ["2026-05-20", 0, 0],
          ["2026-05-21", 5, 12],
          ["2026-05-22", 6, 13],
          ["2026-05-23", 7, 21],
          ["2026-05-24", 8, 34]
        ]
      }
      """,
      """
      {
        "results": [
          ["$pageview", 61],
          ["signup completed", 14]
        ]
      }
      """,
    ])
    let provider = PostHogGrowthProvider(
      configuration: .fixture,
      transport: transport,
      baseSnapshot: .fixture(range: .week)
    )

    let snapshot = try await provider.dashboard(
      projectID: "prbar-product",
      range: .week,
      anchorDate: SampleData.date("2026-05-24")
    )

    XCTAssertEqual(snapshot.connection(for: .postHog)?.status, .connected)
    XCTAssertEqual(snapshot.connection(for: .searchConsole)?.status, .notConnected)
    XCTAssertEqual(snapshot.visibleMetrics.map(\.kind), [.activeUsers, .keyEventCount])
    XCTAssertEqual(snapshot.visibleMetrics.first { $0.kind == .activeUsers }?.formattedValue, "32")
    XCTAssertEqual(snapshot.visibleMetrics.first { $0.kind == .keyEventCount }?.formattedValue, "93")
    XCTAssertEqual(snapshot.visibleMetrics.first { $0.kind == .activeUsers }?.series.count, 7)
    XCTAssertEqual(snapshot.topEvents.map(\.title), ["$pageview", "signup completed"])
    XCTAssertTrue(snapshot.topQueries.isEmpty)
    XCTAssertTrue(snapshot.topPages.isEmpty)
  }

  func testPostHogGrowthProviderKeepsSearchConsoleFixtureVisibleWhenPostHogFails() async throws {
    let provider = PostHogGrowthProvider(
      configuration: .fixture,
      transport: FixturePostHogQueryTransport(results: [.failure(PostHogAPIError.unauthorized)]),
      baseSnapshot: .fixture(range: .week)
    )

    let snapshot = try await provider.dashboard(
      projectID: "prbar-product",
      range: .week,
      anchorDate: SampleData.date("2026-05-24")
    )

    XCTAssertEqual(snapshot.connection(for: .postHog)?.status, .needsAttention)
    XCTAssertEqual(snapshot.connection(for: .searchConsole)?.status, .connected)
    XCTAssertFalse(snapshot.visibleMetrics.contains { $0.provider == .postHog })
    XCTAssertTrue(snapshot.visibleMetrics.contains { $0.provider == .searchConsole })
    XCTAssertEqual(snapshot.issues.first?.title, "PostHog needs attention")
  }
}
