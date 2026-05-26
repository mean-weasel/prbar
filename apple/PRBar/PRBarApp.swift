import SwiftUI

@main
struct PRBarApp: App {
  @State private var store: PRBarStore

  init() {
    let authService: GitHubAuthServicing
    let repositoryProvider: GitHubRepositoryProviding
    let repositorySelectionStore: RepositorySelectionStoring
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      authService = StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture)
      repositoryProvider = StaticGitHubRepositoryProvider(repositories: SampleData.repositories)
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
      repositorySelectionStore = UserDefaultsRepositorySelectionStore()
    }

    let store = PRBarStore.sample(
      authService: authService,
      repositoryProvider: repositoryProvider,
      repositorySelectionStore: repositorySelectionStore
    )
    if ProcessInfo.processInfo.arguments.contains("--signed-out") {
      store.routeState = .signedOut
      store.githubConnection = .signedOut
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
