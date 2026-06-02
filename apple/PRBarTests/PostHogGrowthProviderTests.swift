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

  func testPostHogConfigurationReadsDashboardIDFromEnvironment() {
    let configuration = PostHogConfiguration.live(
      environment: [
        "PRBAR_IOS_POSTHOG_PROJECT_ID": "12345",
        "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
        "PRBAR_IOS_POSTHOG_DASHBOARD_ID": " 1362888 ",
      ]
    )

    XCTAssertEqual(configuration?.dashboardID, 1_362_888)
  }

  func testPostHogConfigurationIgnoresInvalidDashboardID() {
    let configuration = PostHogConfiguration.live(
      environment: [
        "PRBAR_IOS_POSTHOG_PROJECT_ID": "12345",
        "PRBAR_IOS_POSTHOG_PERSONAL_API_KEY": "phx_live",
        "PRBAR_IOS_POSTHOG_DASHBOARD_ID": "not-a-dashboard",
      ]
    )

    XCTAssertNotNil(configuration)
    XCTAssertNil(configuration?.dashboardID)
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

  func testPostHogDashboardRequestsUseEnvironmentDashboardEndpoints() throws {
    let configuration = PostHogConfiguration(
      host: URL(string: "https://us.posthog.com")!,
      projectID: "324426",
      personalAPIKey: "phx_test",
      dashboardID: 1_362_888
    )

    let dashboardRequest = try PostHogDashboardRequest.dashboard(configuration: configuration)
    let runInsightsRequest = try PostHogDashboardRequest.runInsights(
      configuration: configuration,
      refresh: "blocking"
    )

    XCTAssertEqual(dashboardRequest.url?.absoluteString, "https://us.posthog.com/api/environments/324426/dashboards/1362888/")
    XCTAssertEqual(dashboardRequest.httpMethod, "GET")
    XCTAssertEqual(dashboardRequest.value(forHTTPHeaderField: "Authorization"), "Bearer phx_test")
    XCTAssertEqual(dashboardRequest.value(forHTTPHeaderField: "Accept"), "application/json")

    XCTAssertEqual(runInsightsRequest.url?.absoluteString, "https://us.posthog.com/api/environments/324426/dashboards/1362888/run_insights/?output_format=json&refresh=blocking")
    XCTAssertEqual(runInsightsRequest.httpMethod, "GET")
    XCTAssertEqual(runInsightsRequest.value(forHTTPHeaderField: "Authorization"), "Bearer phx_test")
    XCTAssertEqual(runInsightsRequest.value(forHTTPHeaderField: "Accept"), "application/json")
  }

  func testPostHogDashboardRunResponseDecodesTrendAndBreakdownTiles() throws {
    let data = Data(
      """
      {
        "results": [
          {
            "id": 6536095,
            "order": 1,
            "insight": {
              "id": 7359527,
              "short_id": "abc123",
              "name": "Daily Pageviews",
              "derived_name": "Daily Pageviews",
              "result": [
                {
                  "data": [139, 179, 1036],
                  "days": ["2026-04-27", "2026-04-28", "2026-04-29"],
                  "count": 1314,
                  "label": "$pageview"
                }
              ]
            }
          },
          {
            "id": 6536096,
            "order": 2,
            "insight": {
              "id": 7359528,
              "name": "Top Pages",
              "result": [
                {
                  "data": [1087, 879],
                  "days": ["2026-04-26", "2026-05-03"],
                  "count": 1966,
                  "label": "/studio",
                  "breakdown_value": "/studio"
                }
              ]
            }
          }
        ]
      }
      """.utf8
    )

    let response = try PostHogDashboardRunResponse(data: data)

    XCTAssertEqual(response.results.count, 2)
    XCTAssertEqual(response.results[0].insight.name, "Daily Pageviews")
    XCTAssertEqual(response.results[0].insight.derivedName, "Daily Pageviews")
    XCTAssertEqual(response.results[0].insight.result[0].data, [139, 179, 1036])
    XCTAssertEqual(response.results[0].insight.result[0].count, 1314.0)
    XCTAssertEqual(response.results[1].insight.name, "Top Pages")
    XCTAssertEqual(response.results[1].insight.result[0].data, [1087, 879])
    XCTAssertEqual(response.results[1].insight.result[0].count, 1966.0)
    XCTAssertEqual(response.results[1].insight.result[0].breakdownValue, "/studio")
  }

  func testBleepBlogDashboardNormalizerMapsSupportedTilesToGrowthSnapshot() throws {
    let data = Data(
      """
      {
        "results": [
          {
            "id": 6536094,
            "order": 1,
            "insight": {
              "id": 7359526,
              "name": "Weekly Visitors",
              "result": [
                {
                  "data": [11, 13, 17],
                  "days": ["2026-05-12", "2026-05-19", "2026-05-26"],
                  "count": 41,
                  "label": "$pageview"
                }
              ]
            }
          },
          {
            "id": 6536095,
            "order": 2,
            "insight": {
              "id": 7359527,
              "name": "Daily Pageviews",
              "result": [
                {
                  "data": [139, 179, 1036],
                  "days": ["2026-04-27", "2026-04-28", "2026-04-29"],
                  "count": 1314,
                  "label": "$pageview"
                }
              ]
            }
          },
          {
            "id": 6536096,
            "order": 3,
            "insight": {
              "id": 7359528,
              "name": "Traffic Sources",
              "result": [
                {
                  "data": [12],
                  "days": ["2026-05-26"],
                  "count": 12,
                  "label": "github.com",
                  "breakdown_value": "github.com"
                },
                {
                  "data": [50],
                  "days": ["2026-05-26"],
                  "count": 50,
                  "label": "direct",
                  "breakdown_value": "direct"
                },
                {
                  "data": [33],
                  "days": ["2026-05-26"],
                  "count": 33,
                  "label": "newsletter",
                  "breakdown_value": "newsletter"
                },
                {
                  "data": [999],
                  "days": ["2026-05-26"],
                  "count": 999,
                  "label": "Other",
                  "breakdown_value": "__other__"
                }
              ]
            }
          },
          {
            "id": 6536097,
            "order": 4,
            "insight": {
              "id": 7359529,
              "name": "Top Pages",
              "result": [
                {
                  "data": [420],
                  "days": ["2026-05-26"],
                  "count": 420,
                  "label": "/blog",
                  "breakdown_value": "/blog"
                },
                {
                  "data": [9000],
                  "days": ["2026-05-26"],
                  "count": 9000,
                  "label": "Other",
                  "breakdown_value": "$$_posthog_breakdown_other_$$"
                },
                {
                  "data": [5],
                  "days": ["2026-05-26"],
                  "count": 5,
                  "label": "/pricing",
                  "breakdown_value": "/pricing"
                },
                {
                  "data": [1966],
                  "days": ["2026-05-26"],
                  "count": 1966,
                  "label": "/studio",
                  "breakdown_value": "/studio"
                },
                {
                  "data": [300],
                  "days": ["2026-05-26"],
                  "count": 300,
                  "label": "/docs",
                  "breakdown_value": "/docs"
                },
                {
                  "data": [100],
                  "days": ["2026-05-26"],
                  "count": 100,
                  "label": "/",
                  "breakdown_value": "/"
                },
                {
                  "data": [50],
                  "days": ["2026-05-26"],
                  "count": 50,
                  "label": "/about",
                  "breakdown_value": "/about"
                },
                {
                  "data": [25],
                  "days": ["2026-05-26"],
                  "count": 25,
                  "label": "/changelog",
                  "breakdown_value": "/changelog"
                }
              ]
            }
          },
          {
            "id": 6536098,
            "order": 5,
            "insight": {
              "id": 7359530,
              "name": "Blog -> Upload Activation",
              "result": []
            }
          },
          {
            "id": 6536099,
            "order": 6,
            "insight": {
              "id": 7359531,
              "derived_name": "Experimental Dashboard Tile",
              "result": []
            }
          }
        ]
      }
      """.utf8
    )

    let response = try PostHogDashboardRunResponse(data: data)
    let snapshot = BleepBlogDashboardNormalizer.snapshot(
      response: response,
      range: .month,
      anchorDate: SampleData.date("2026-05-26")
    )

    XCTAssertEqual(snapshot.dataSource, .livePostHog)
    XCTAssertEqual(snapshot.project.id, "bleep-that-sht")
    XCTAssertEqual(snapshot.project.name, "Bleep Blog KPI Dashboard")
    XCTAssertEqual(snapshot.connection(for: .postHog)?.status, .connected)
    XCTAssertEqual(snapshot.connection(for: .searchConsole)?.status, .notConnected)
    XCTAssertEqual(Array(snapshot.visibleMetrics.map(\.kind).prefix(2)), [.weeklyVisitors, .pageViews])
    XCTAssertEqual(snapshot.visibleMetrics.first { $0.kind == .weeklyVisitors }?.formattedValue, "41")
    XCTAssertEqual(snapshot.visibleMetrics.first { $0.kind == .pageViews }?.formattedValue, "1,314")
    XCTAssertEqual(snapshot.topEvents.map(\.title), ["direct", "newsletter", "github.com"])
    XCTAssertEqual(snapshot.topPages.map(\.title), ["/studio", "/blog", "/docs", "/", "/about"])
    XCTAssertTrue(snapshot.topQueries.isEmpty)
    XCTAssertEqual(snapshot.shippingContext.pullRequestCount, 0)
    XCTAssertEqual(snapshot.shippingContext.releaseCount, 0)
    XCTAssertTrue(snapshot.issues.contains { $0.detail.contains("Blog -> Upload Activation") })
    XCTAssertTrue(snapshot.issues.contains { $0.detail.contains("Experimental Dashboard Tile") })
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
    XCTAssertEqual(snapshot.dataSource, .livePostHog)
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
    XCTAssertEqual(snapshot.dataSource, .sampleFallback)
    XCTAssertFalse(snapshot.visibleMetrics.contains { $0.provider == .postHog })
    XCTAssertTrue(snapshot.visibleMetrics.contains { $0.provider == .searchConsole })
    XCTAssertEqual(snapshot.issues.first?.title, "PostHog needs attention")
  }
}
