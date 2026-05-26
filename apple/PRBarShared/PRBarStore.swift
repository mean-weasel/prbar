import Foundation
import Observation

@Observable
final class PRBarStore {
  var repositories: [Repository]
  var pullRequests: [PullRequest]
  var releases: [ReleaseMoment]
  var selectedPRDate: Date
  var selectedReleaseDate: Date
  var prRange: ActivityRange
  var releaseRange: ActivityRange
  var selectedRepositoryID: Repository.ID?
  var selectedReleaseID: ReleaseMoment.ID?
  var cardDraft: WorkCardDraft
  var routeState: AppRouteState
  var githubConnection: GitHubConnection
  private let authService: GitHubAuthServicing
  private let repositoryProvider: GitHubRepositoryProviding
  private let repositorySelectionStore: RepositorySelectionStoring

  private static let fixtureCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()

  init(
    repositories: [Repository],
    pullRequests: [PullRequest],
    releases: [ReleaseMoment],
    selectedPRDate: Date,
    selectedReleaseDate: Date,
    prRange: ActivityRange = .week,
    releaseRange: ActivityRange = .week,
    selectedRepositoryID: Repository.ID? = nil,
    selectedReleaseID: ReleaseMoment.ID? = "rel-prbar-140",
    cardDraft: WorkCardDraft = WorkCardDraft(source: .shippingSnapshot, theme: .clean, side: .publicSide, showRepos: true, showHandle: true, exactCounts: true, showPrivateLabels: false),
    routeState: AppRouteState = .authenticated,
    githubConnection: GitHubConnection = GitHubConnection(status: .connected, user: GitHubUser(login: "neonwatty", displayName: "Neon Watty")),
    authService: GitHubAuthServicing = StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore()),
    repositoryProvider: GitHubRepositoryProviding = StaticGitHubRepositoryProvider(repositories: SampleData.repositories),
    repositorySelectionStore: RepositorySelectionStoring = InMemoryRepositorySelectionStore()
  ) {
    self.repositories = repositories
    self.pullRequests = pullRequests
    self.releases = releases
    self.selectedPRDate = selectedPRDate
    self.selectedReleaseDate = selectedReleaseDate
    self.prRange = prRange
    self.releaseRange = releaseRange
    self.selectedRepositoryID = selectedRepositoryID
    self.selectedReleaseID = selectedReleaseID
    self.cardDraft = cardDraft
    self.routeState = routeState
    self.githubConnection = githubConnection
    self.authService = authService
    self.repositoryProvider = repositoryProvider
    self.repositorySelectionStore = repositorySelectionStore
  }

  static func sample(
    authService: GitHubAuthServicing = StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore()),
    repositoryProvider: GitHubRepositoryProviding = StaticGitHubRepositoryProvider(repositories: SampleData.repositories),
    repositorySelectionStore: RepositorySelectionStoring = InMemoryRepositorySelectionStore()
  ) -> PRBarStore {
    PRBarStore(
      repositories: SampleData.repositories,
      pullRequests: SampleData.pullRequests,
      releases: SampleData.releases,
      selectedPRDate: SampleData.today,
      selectedReleaseDate: SampleData.today,
      authService: authService,
      repositoryProvider: repositoryProvider,
      repositorySelectionStore: repositorySelectionStore
    )
  }

  var includedRepositories: [Repository] {
    repositories.filter(\.included)
  }

  var filteredPullRequests: [PullRequest] {
    let includedIDs = Set(includedRepositories.map(\.id))
    return pullRequests.filter {
      includedIDs.contains($0.repoID) && Self.fixtureCalendar.isDate($0.mergedAt, inSameDayAs: selectedPRDate)
    }
  }

  var filteredReleases: [ReleaseMoment] {
    let includedIDs = Set(includedRepositories.map(\.id))
    return releases.filter {
      includedIDs.contains($0.repoID) && Self.fixtureCalendar.isDate($0.date, inSameDayAs: selectedReleaseDate)
    }
  }

  var cardHasPrivateEvidence: Bool {
    includedRepositories.contains { $0.visibility == .private }
  }

  func restoreGitHubSession() {
    do {
      if let connection = try authService.restoreConnection() {
        githubConnection = connection
        try loadRepositoriesForConnectedUser()
        routeState = .authenticated
      }
    } catch {
      routeState = authIssue(for: error)
    }
  }

  func connectGitHub() {
    githubConnection = GitHubConnection(status: .signingIn, user: nil)
    do {
      githubConnection = try authService.connect()
      try loadRepositoriesForConnectedUser()
      routeState = .onboarding(.repositories)
    } catch {
      githubConnection = .signedOut
      routeState = authIssue(for: error)
    }
  }

  func finishRepositorySetup() {
    try? repositorySelectionStore.saveIncludedRepositoryIDs(includedRepositories.map(\.id))
    routeState = .authenticated
  }

  func disconnectGitHub() {
    try? authService.disconnect()
    try? repositorySelectionStore.clearIncludedRepositoryIDs()
    githubConnection = .signedOut
    repositories = repositories.map { repository in
      var repository = repository
      repository.included = false
      return repository
    }
    routeState = .signedOut
  }

  private func loadRepositoriesForConnectedUser() throws {
    repositories = try applyStoredSelection(to: repositoryProvider.repositories())
  }

  private func applyStoredSelection(to repositories: [Repository]) throws -> [Repository] {
    let storedIDs = try repositorySelectionStore.loadIncludedRepositoryIDs()
    return repositories.map { repository in
      var repository = repository
      if let storedIDs {
        repository.included = storedIDs.contains(repository.id)
      } else {
        repository.included =
          repository.access == .ready &&
          repository.visibility == .public &&
          (repository.included || repository.recommended)
      }
      return repository
    }
  }

  private func authIssue(for error: Error) -> AppRouteState {
    let issue: AuthIssue
    if let authError = error as? GitHubAuthError, authError == .missingConfiguration {
      issue = AuthIssue(
        id: "github-auth-missing-configuration",
        title: "GitHub sign-in is not configured",
        message: "Add a GitHub OAuth client ID before using live GitHub sign-in. Sample data is still available."
      )
    } else {
      issue = AuthIssue(
        id: "github-auth-failed",
        title: "GitHub sign-in failed",
        message: "Try again, or continue with sample data while GitHub is unavailable."
      )
    }
    return .issue(issue)
  }
}
