import Darwin
import SwiftUI

enum GrowthProviderFactory {
  static func provider(
    environment: [String: String],
    baseSnapshot: GrowthDashboardSnapshot = SampleData.growthDashboard
  ) -> GrowthDashboardProviding {
    guard let configuration = PostHogConfiguration.live(environment: environment) else {
      return StaticGrowthDashboardProvider(snapshot: baseSnapshot)
    }

    if configuration.dashboardID != nil {
      return PostHogDashboardGrowthProvider(configuration: configuration, baseSnapshot: baseSnapshot)
    }

    return PostHogGrowthProvider(configuration: configuration, baseSnapshot: baseSnapshot)
  }
}

@main
struct PRBarApp: App {
  @State private var store: PRBarStore

  init() {
    let authService: GitHubAuthServicing
    let repositoryProvider: GitHubRepositoryProviding
    let activityProvider: GitHubActivityProviding
    let repositorySelectionStore: RepositorySelectionStoring
    let repositoryColorStore: RepositoryColorStoring
    let activityCacheStore: GitHubActivityCacheStoring
    let growthProvider: GrowthDashboardProviding
    let arguments = ProcessInfo.processInfo.arguments
    let environment = ProcessInfo.processInfo.environment
    let isUITesting = arguments.contains("--ui-testing")
    let isUITestingBleepPostHogDashboard =
      arguments.contains("--ui-testing-bleep-posthog-dashboard") ||
      environment["PRBAR_UI_TESTING_BLEEP_POSTHOG_DASHBOARD"] == "1"
    let isLiveGitHubSmokeHeadless = arguments.contains("--live-github-smoke-headless")
    let liveGitHubSession = Self.uiTestingLiveGitHubSession(environment: environment)
    let usesPersistentUITestingState =
      arguments.contains("--ui-testing-seed-activity-cache") ||
      arguments.contains("--ui-testing-cached-activity")
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      let sessionStore = InMemoryGitHubSessionStore()
      if let liveGitHubSession {
        authService = StaticGitHubAuthService(sessionStore: sessionStore, session: liveGitHubSession)
        repositoryProvider = GitHubRepositoryClient(
          sessionStore: sessionStore,
          transport: URLSessionGitHubRepositoryTransport()
        )
        activityProvider = GitHubActivityClient(
          sessionStore: sessionStore,
          transport: URLSessionGitHubRepositoryTransport()
        )
      } else {
        if usesPersistentUITestingState {
          try? sessionStore.saveSession(.fixture)
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-device-auth") {
          authService = StaticGitHubAuthService(
            sessionStore: sessionStore,
            result: .failure(.authorizationPending(.fixture)),
            continuationResult: .success(.fixture)
          )
        } else {
          authService = StaticGitHubAuthService(sessionStore: sessionStore, session: .fixture)
        }
        repositoryProvider = StaticGitHubRepositoryProvider(repositories: SampleData.repositories)
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-refresh-failure") ||
          ProcessInfo.processInfo.arguments.contains("--ui-testing-cached-activity") {
          activityProvider = UITestingFailingGitHubActivityProvider(error: GitHubAPIError.networkUnavailable)
        } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-first-run-slow-sync") {
          activityProvider = UITestingSlowGitHubActivityProvider(snapshot: Self.uiTestingRefreshSnapshot)
        } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-seed-activity-cache") {
          activityProvider = StaticGitHubActivityProvider(snapshot: Self.uiTestingCachedSnapshot)
        } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-partial-sync") {
          activityProvider = StaticGitHubActivityProvider(snapshot: Self.uiTestingPartialSnapshot)
        } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-refresh-data") {
          activityProvider = SequencedGitHubActivityProvider(snapshots: [Self.uiTestingRefreshSnapshot, Self.uiTestingRefreshSnapshot])
        } else {
          activityProvider = StaticGitHubActivityProvider()
        }
      }
      repositorySelectionStore = usesPersistentUITestingState
        ? UserDefaultsRepositorySelectionStore(key: "ui-testing.github.includedRepositoryIDs")
        : InMemoryRepositorySelectionStore()
      repositoryColorStore = usesPersistentUITestingState
        ? UserDefaultsRepositoryColorStore(key: "ui-testing.github.repositoryColors")
        : InMemoryRepositoryColorStore()
      activityCacheStore = usesPersistentUITestingState
        ? FileGitHubActivityCacheStore(fileURL: Self.uiTestingActivityCacheURL)
        : InMemoryGitHubActivityCacheStore()
      if isUITestingBleepPostHogDashboard {
        growthProvider = StaticGrowthDashboardProvider(snapshot: Self.uiTestingBleepPostHogDashboardSnapshot)
      } else if arguments.contains("--growth-posthog-needs-attention") {
        growthProvider = StaticGrowthDashboardProvider(snapshot: Self.uiTestingPostHogNeedsAttentionGrowthSnapshot)
      } else {
        growthProvider = GrowthProviderFactory.provider(environment: environment)
      }
    } else {
      let sessionStore = KeychainGitHubSessionStore()
      if isLiveGitHubSmokeHeadless, let liveGitHubSession {
        try? sessionStore.saveSession(liveGitHubSession)
      }
      authService = GitHubDeviceFlowAuthService(
        configuration: .appDefault(),
        sessionStore: sessionStore
      )
      repositoryProvider = GitHubRepositoryClient(
        sessionStore: sessionStore,
        transport: URLSessionGitHubRepositoryTransport()
      )
      activityProvider = GitHubActivityClient(
        sessionStore: sessionStore,
        transport: URLSessionGitHubRepositoryTransport()
      )
      repositorySelectionStore = UserDefaultsRepositorySelectionStore()
      repositoryColorStore = UserDefaultsRepositoryColorStore()
      activityCacheStore = FileGitHubActivityCacheStore()
      growthProvider = GrowthProviderFactory.provider(environment: environment)
    }

    if isLiveGitHubSmokeHeadless,
      let includedRepo = Self.normalizedLiveSmokeValue(environment["PRBAR_IOS_LIVE_REPOSITORY"]) {
      try? repositorySelectionStore.clearIncludedRepositoryIDs()
      try? repositoryColorStore.clearRepositoryColors()
      try? activityCacheStore.clear()
      try? repositorySelectionStore.saveIncludedRepositoryIDs([includedRepo])
    }

    if ProcessInfo.processInfo.arguments.contains("--ui-testing-seed-activity-cache") {
      try? repositorySelectionStore.clearIncludedRepositoryIDs()
      try? repositoryColorStore.clearRepositoryColors()
      try? activityCacheStore.clear()
      try? repositorySelectionStore.saveIncludedRepositoryIDs(["prbar"])
      try? activityCacheStore.save(
        GitHubActivityCacheRecord(
          githubLogin: GitHubAuthSession.fixture.user.login,
          includedRepositoryIDs: ["prbar"],
          snapshot: Self.uiTestingCachedSnapshot,
          lastRefreshedAt: SampleData.dateTime("2026-05-24T18:30:00Z")
        )
      )
    }

    let store = PRBarStore.sample(
      authService: authService,
      repositoryProvider: repositoryProvider,
      activityProvider: activityProvider,
      repositorySelectionStore: repositorySelectionStore,
      repositoryColorStore: repositoryColorStore,
      activityCacheStore: activityCacheStore,
      growthProvider: growthProvider
    )
    if isUITesting, isUITestingBleepPostHogDashboard {
      store.growthSnapshot = Self.uiTestingBleepPostHogDashboardSnapshot
    } else if isUITesting, arguments.contains("--growth-posthog-needs-attention") {
      store.growthSnapshot = Self.uiTestingPostHogNeedsAttentionGrowthSnapshot
    }
    if ProcessInfo.processInfo.arguments.contains("--signed-out") {
      store.routeState = .signedOut
      store.githubConnection = .signedOut
    } else if usesPersistentUITestingState {
      store.restoreGitHubSession()
    } else if isUITesting {
      store.routeState = .authenticated
      store.githubConnection = GitHubAuthSession.fixture.connection
      if ProcessInfo.processInfo.arguments.contains("--ui-testing-refresh-failure") {
        store.lastActivityRefreshAt = SampleData.dateTime("2026-05-24T08:00:00Z")
      }
    } else {
      store.restoreGitHubSession()
    }

    if isLiveGitHubSmokeHeadless {
      Self.startHeadlessLiveGitHubSmoke(
        store: store,
        expectedLogin: Self.normalizedLiveSmokeValue(environment["PRBAR_IOS_LIVE_GITHUB_LOGIN"]),
        includedRepo: Self.normalizedLiveSmokeValue(environment["PRBAR_IOS_LIVE_REPOSITORY"])
      )
    }
    _store = State(initialValue: store)
  }

  var body: some Scene {
    WindowGroup {
      RootTabView(store: store)
    }
  }
}

private struct UITestingFailingGitHubActivityProvider: GitHubActivityProviding {
  var error: GitHubAPIError

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    throw error
  }
}

private struct UITestingSlowGitHubActivityProvider: GitHubActivityProviding {
  var snapshot: GitHubActivitySnapshot

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    filteredSnapshot(for: repositories)
  }

  func activityAsync(
    for repositories: [Repository],
    endingAt endDate: Date,
    lookbackDays: Int,
    progress: (@MainActor (ActivityRefreshProgress) -> Void)?
  ) async throws -> GitHubActivitySnapshot {
    let includedIDs = Set(repositories.map(\.id))
    let repoName = repositories.first?.name
    await progress?(
      ActivityRefreshProgress(
        totalRepositories: repositories.count,
        completedRepositories: 0,
        currentRepositoryName: repoName,
        pullRequestCount: 0,
        releaseCount: 0
      )
    )
    try await Task.sleep(nanoseconds: 12_000_000_000)

    let filtered = GitHubActivitySnapshot(
      pullRequests: snapshot.pullRequests.filter { includedIDs.contains($0.repoID) },
      releases: snapshot.releases.filter { includedIDs.contains($0.repoID) },
      anchorDate: snapshot.anchorDate
    )
    await progress?(
      ActivityRefreshProgress(
        totalRepositories: repositories.count,
        completedRepositories: repositories.count,
        currentRepositoryName: nil,
        pullRequestCount: filtered.pullRequests.count,
        releaseCount: filtered.releases.count
      )
    )
    return filtered
  }

  private func filteredSnapshot(for repositories: [Repository]) -> GitHubActivitySnapshot {
    let includedIDs = Set(repositories.map(\.id))
    return GitHubActivitySnapshot(
      pullRequests: snapshot.pullRequests.filter { includedIDs.contains($0.repoID) },
      releases: snapshot.releases.filter { includedIDs.contains($0.repoID) },
      anchorDate: snapshot.anchorDate
    )
  }
}

private extension PRBarApp {
  static func normalizedLiveSmokeValue(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), value.isEmpty == false else {
      return nil
    }
    return value
  }

  static func uiTestingLiveGitHubSession(environment: [String: String]) -> GitHubAuthSession? {
    guard let token = environment["PRBAR_IOS_LIVE_GITHUB_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines),
      token.isEmpty == false
    else {
      return nil
    }

    let login = environment["PRBAR_IOS_LIVE_GITHUB_LOGIN"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let displayName = environment["PRBAR_IOS_LIVE_GITHUB_DISPLAY_NAME"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedLogin = login.flatMap { $0.isEmpty ? nil : $0 } ?? "neonwatty"

    return GitHubAuthSession(
      accessToken: token,
      tokenType: "bearer",
      scopes: [],
      user: GitHubUser(login: normalizedLogin, displayName: displayName.flatMap { $0.isEmpty ? nil : $0 } ?? normalizedLogin)
    )
  }

  static func startHeadlessLiveGitHubSmoke(store: PRBarStore, expectedLogin: String?, includedRepo: String?) {
    Task { @MainActor in
      let status = await runHeadlessLiveGitHubSmoke(
        store: store,
        expectedLogin: expectedLogin,
        includedRepo: includedRepo
      )
      fflush(stdout)
      fflush(stderr)
      exit(status)
    }
  }

  @MainActor
  static func runHeadlessLiveGitHubSmoke(store: PRBarStore, expectedLogin: String?, includedRepo: String?) async -> Int32 {
    guard let expectedLogin, let includedRepo else {
      fputs("PRBAR_LIVE_SMOKE_RESULT failure reason=missing-live-smoke-environment\n", stderr)
      return 64
    }

    print("PRBAR_LIVE_SMOKE_START login=\(expectedLogin) repo=\(includedRepo) driver=headless")

    guard let user = store.githubConnection.user else {
      fputs("PRBAR_LIVE_SMOKE_RESULT failure reason=missing-github-session login=\(expectedLogin) hint=set-PRBAR_IOS_LIVE_GITHUB_TOKEN\n", stderr)
      return 65
    }

    guard user.login == expectedLogin else {
      fputs("PRBAR_LIVE_SMOKE_RESULT failure reason=unexpected-github-login expected=\(expectedLogin) actual=\(user.login)\n", stderr)
      return 65
    }

    let includedRepositories = store.includedRepositories
    guard includedRepositories.map(\.id) == [includedRepo] else {
      let actual = includedRepositories.map(\.id).joined(separator: ",")
      fputs("PRBAR_LIVE_SMOKE_RESULT failure reason=unexpected-included-repositories expected=\(includedRepo) actual=\(actual)\n", stderr)
      return 65
    }

    await store.refreshActivity()

    if let issue = store.activityRefreshIssue {
      fputs("PRBAR_LIVE_SMOKE_RESULT failure reason=refresh-failed issue=\(issue.id) title=\"\(issue.title)\"\n", stderr)
      return 65
    }

    guard store.lastActivityRefreshAt != nil else {
      fputs("PRBAR_LIVE_SMOKE_RESULT failure reason=refresh-did-not-complete repo=\(includedRepo)\n", stderr)
      return 65
    }

    let prCount = store.pullRequests.filter { $0.repoID == includedRepo }.count
    let releaseCount = store.releases.filter { $0.repoID == includedRepo }.count
    print("PRBAR_LIVE_SMOKE_RESULT success login=\(user.login) repo=\(includedRepo) selected_repo_count=\(includedRepositories.count) pull_requests=\(prCount) releases=\(releaseCount)")
    return 0
  }

  static var uiTestingActivityCacheURL: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("PRBarUITesting", isDirectory: true)
      .appendingPathComponent("GitHubActivityCache.json")
  }

  static var uiTestingCachedSnapshot: GitHubActivitySnapshot {
    GitHubActivitySnapshot(
      pullRequests: [
        PullRequest(id: "prbar#424", title: "Cached relaunch PR", repoID: "prbar", number: 424, mergedAt: SampleData.dateTime("2026-05-24T19:30:00Z"))
      ],
      releases: [
        ReleaseMoment(id: "prbar@release:v4.2.4", repoID: "prbar", title: "Cached relaunch release", tag: "v4.2.4", date: SampleData.date("2026-05-24"), source: .release, notes: "Loaded from the persisted UI test activity cache.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v4.2.4")!)
      ],
      anchorDate: SampleData.date("2026-05-24")
    )
  }

  static var uiTestingRefreshSnapshot: GitHubActivitySnapshot {
    GitHubActivitySnapshot(
      pullRequests: [
        PullRequest(id: "prbar#999", title: "UI refresh merged PR", repoID: "prbar", number: 999, mergedAt: SampleData.dateTime("2026-05-24T18:00:00Z"))
      ],
      releases: [
        ReleaseMoment(id: "prbar@release:v9.9.9", repoID: "prbar", title: "UI refresh release", tag: "v9.9.9", date: SampleData.date("2026-05-24"), source: .release, notes: "Refresh data loaded from the deterministic UI test provider.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v9.9.9")!)
      ],
      anchorDate: SampleData.date("2026-05-24")
    )
  }

  static var uiTestingPartialSnapshot: GitHubActivitySnapshot {
    GitHubActivitySnapshot(
      pullRequests: [
        PullRequest(id: "prbar#1001", title: "Partial sync visible PR", repoID: "prbar", number: 1001, mergedAt: SampleData.dateTime("2026-05-24T18:10:00Z"))
      ],
      releases: [
        ReleaseMoment(id: "prbar@release:v10.0.1", repoID: "prbar", title: "Partial sync visible release", tag: "v10.0.1", date: SampleData.date("2026-05-24"), source: .release, notes: "Visible release from the accessible repo while another repo needs attention.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v10.0.1")!)
      ],
      anchorDate: SampleData.date("2026-05-24"),
      repositoryIssues: [
        ActivityRepositoryIssue(
          repositoryID: "client-api",
          repositoryFullName: "example/client-api",
          title: "Repository needs attention",
          message: "Authorize SSO for example/client-api, then refresh again."
        )
      ]
    )
  }

  static var uiTestingPostHogNeedsAttentionGrowthSnapshot: GrowthDashboardSnapshot {
    var snapshot = GrowthDashboardSnapshot.fixture(
      range: .week,
      connections: [
        GrowthConnection(
          id: "posthog-main",
          provider: .postHog,
          displayName: "PostHog",
          status: .needsAttention,
          lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
          issue: "PostHog API key needs attention"
        ),
        GrowthConnection(
          id: "gsc-main",
          provider: .searchConsole,
          displayName: "Search Console",
          status: .connected,
          lastRefreshedAt: SampleData.dateTime("2026-05-24T18:00:00Z"),
          issue: nil
        ),
      ]
    )
    snapshot.dataSource = .sampleFallback
    snapshot.issues = [
      GrowthDashboardIssue(
        id: "posthog-needs-attention",
        provider: .postHog,
        title: "PostHog needs attention",
        detail: "PostHog API key needs attention"
      )
    ]
    return snapshot
  }

  static var uiTestingBleepPostHogDashboardSnapshot: GrowthDashboardSnapshot {
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
                  "data": [12],
                  "days": ["2026-05-26"],
                  "count": 12,
                  "label": "github.com",
                  "breakdown_value": "github.com"
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
                  "data": [1966],
                  "days": ["2026-05-26"],
                  "count": 1966,
                  "label": "/studio",
                  "breakdown_value": "/studio"
                },
                {
                  "data": [420],
                  "days": ["2026-05-26"],
                  "count": 420,
                  "label": "/blog",
                  "breakdown_value": "/blog"
                },
                {
                  "data": [300],
                  "days": ["2026-05-26"],
                  "count": 300,
                  "label": "/docs",
                  "breakdown_value": "/docs"
                }
              ]
            }
          }
        ]
      }
      """.utf8
    )

    let response = try! PostHogDashboardRunResponse(data: data)
    return BleepBlogDashboardNormalizer.snapshot(
      response: response,
      range: .week,
      anchorDate: SampleData.date("2026-05-26")
    )
  }
}
