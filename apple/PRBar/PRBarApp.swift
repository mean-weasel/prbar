import SwiftUI

@main
struct PRBarApp: App {
  @State private var store: PRBarStore

  init() {
    let authService: GitHubAuthServicing
    let repositoryProvider: GitHubRepositoryProviding
    let activityProvider: GitHubActivityProviding
    let repositorySelectionStore: RepositorySelectionStoring
    let activityCacheStore: GitHubActivityCacheStoring
    let arguments = ProcessInfo.processInfo.arguments
    let isUITesting = arguments.contains("--ui-testing")
    let usesPersistentUITestingState =
      arguments.contains("--ui-testing-seed-activity-cache") ||
      arguments.contains("--ui-testing-cached-activity")
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      let sessionStore = InMemoryGitHubSessionStore()
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
      } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-seed-activity-cache") {
        activityProvider = StaticGitHubActivityProvider(snapshot: Self.uiTestingCachedSnapshot)
      } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-refresh-data") {
        activityProvider = SequencedGitHubActivityProvider(snapshots: [Self.uiTestingRefreshSnapshot, Self.uiTestingRefreshSnapshot])
      } else {
        activityProvider = StaticGitHubActivityProvider()
      }
      repositorySelectionStore = usesPersistentUITestingState
        ? UserDefaultsRepositorySelectionStore(key: "ui-testing.github.includedRepositoryIDs")
        : InMemoryRepositorySelectionStore()
      activityCacheStore = usesPersistentUITestingState
        ? FileGitHubActivityCacheStore(fileURL: Self.uiTestingActivityCacheURL)
        : InMemoryGitHubActivityCacheStore()
    } else {
      let sessionStore = KeychainGitHubSessionStore()
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
      activityCacheStore = FileGitHubActivityCacheStore()
    }

    if ProcessInfo.processInfo.arguments.contains("--ui-testing-seed-activity-cache") {
      try? repositorySelectionStore.clearIncludedRepositoryIDs()
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
      activityCacheStore: activityCacheStore
    )
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

private extension PRBarApp {
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
}
