import SwiftUI

@main
struct PRBarApp: App {
  @State private var store: PRBarStore

  init() {
    let authService: GitHubAuthServicing
    let repositoryProvider: GitHubRepositoryProviding
    let activityProvider: GitHubActivityProviding
    let repositorySelectionStore: RepositorySelectionStoring
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      let sessionStore = InMemoryGitHubSessionStore()
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
      if ProcessInfo.processInfo.arguments.contains("--ui-testing-refresh-failure") {
        activityProvider = UITestingFailingGitHubActivityProvider(error: GitHubAPIError.networkUnavailable)
      } else if ProcessInfo.processInfo.arguments.contains("--ui-testing-refresh-data") {
        activityProvider = SequencedGitHubActivityProvider(snapshots: [Self.uiTestingRefreshSnapshot, Self.uiTestingRefreshSnapshot])
      } else {
        activityProvider = StaticGitHubActivityProvider()
      }
      repositorySelectionStore = InMemoryRepositorySelectionStore()
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
    }

    let store = PRBarStore.sample(
      authService: authService,
      repositoryProvider: repositoryProvider,
      activityProvider: activityProvider,
      repositorySelectionStore: repositorySelectionStore
    )
    let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
    if ProcessInfo.processInfo.arguments.contains("--signed-out") {
      store.routeState = .signedOut
      store.githubConnection = .signedOut
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
