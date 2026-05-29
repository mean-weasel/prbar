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
  var activityAnchorDate: Date
  var cardDraft: WorkCardDraft
  var routeState: AppRouteState
  var githubConnection: GitHubConnection
  var isRefreshingActivity = false
  var activityRefreshProgress: ActivityRefreshProgress?
  var activityRefreshIssue: AuthIssue?
  var lastActivityRefreshAt: Date?
  var lastActivityRefreshAttemptAt: Date?
  private let authService: GitHubAuthServicing
  private let repositoryProvider: GitHubRepositoryProviding
  private let activityProvider: GitHubActivityProviding
  private let repositorySelectionStore: RepositorySelectionStoring
  private let activityCacheStore: GitHubActivityCacheStoring
  private let currentDate: @Sendable () -> Date
  private static let maximumRestoredRepositorySelectionCount = 50

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
    activityAnchorDate: Date = SampleData.today,
    cardDraft: WorkCardDraft = WorkCardDraft(source: .shippingSnapshot, theme: .clean, side: .publicSide, showRepos: true, showHandle: true, exactCounts: true, showPrivateLabels: false),
    routeState: AppRouteState = .authenticated,
    githubConnection: GitHubConnection = GitHubConnection(status: .connected, user: GitHubUser(login: "neonwatty", displayName: "Neon Watty")),
    authService: GitHubAuthServicing = StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore()),
    repositoryProvider: GitHubRepositoryProviding = StaticGitHubRepositoryProvider(repositories: SampleData.repositories),
    activityProvider: GitHubActivityProviding = StaticGitHubActivityProvider(),
    repositorySelectionStore: RepositorySelectionStoring = InMemoryRepositorySelectionStore(),
    activityCacheStore: GitHubActivityCacheStoring = InMemoryGitHubActivityCacheStore(),
    currentDate: @escaping @Sendable () -> Date = Date.init
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
    self.activityAnchorDate = activityAnchorDate
    self.cardDraft = cardDraft
    self.routeState = routeState
    self.githubConnection = githubConnection
    self.authService = authService
    self.repositoryProvider = repositoryProvider
    self.activityProvider = activityProvider
    self.repositorySelectionStore = repositorySelectionStore
    self.activityCacheStore = activityCacheStore
    self.currentDate = currentDate
  }

  static func sample(
    authService: GitHubAuthServicing = StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore()),
    repositoryProvider: GitHubRepositoryProviding = StaticGitHubRepositoryProvider(repositories: SampleData.repositories),
    activityProvider: GitHubActivityProviding = StaticGitHubActivityProvider(),
    repositorySelectionStore: RepositorySelectionStoring = InMemoryRepositorySelectionStore(),
    activityCacheStore: GitHubActivityCacheStoring = InMemoryGitHubActivityCacheStore(),
    currentDate: @escaping @Sendable () -> Date = Date.init
  ) -> PRBarStore {
    PRBarStore(
      repositories: SampleData.repositories,
      pullRequests: SampleData.pullRequests,
      releases: SampleData.releases,
      selectedPRDate: SampleData.today,
      selectedReleaseDate: SampleData.today,
      activityAnchorDate: SampleData.today,
      authService: authService,
      repositoryProvider: repositoryProvider,
      activityProvider: activityProvider,
      repositorySelectionStore: repositorySelectionStore,
      activityCacheStore: activityCacheStore,
      currentDate: currentDate
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
        let hasStoredSelection = try loadRepositoriesForConnectedUser()
        if hasStoredSelection {
          _ = restoreCachedActivityForConnectedUser()
          routeState = .authenticated
        } else {
          routeState = .onboarding(.repositories)
        }
      } else {
        githubConnection = .signedOut
        routeState = .signedOut
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
      handleAuth(error)
    }
  }

  func continueGitHubAuthorization() {
    guard case let .authorizing(authorization) = routeState else {
      return
    }

    guard authorization.isExpired(at: currentDate()) == false else {
      githubConnection = .signedOut
      routeState = .issue(
        AuthIssue(
          id: "github-device-code-expired",
          title: "GitHub code expired",
          message: "GitHub device codes expire after a few minutes. Request a new code and try again."
        )
      )
      return
    }

    githubConnection = GitHubConnection(status: .signingIn, user: nil)
    do {
      githubConnection = try authService.continueDeviceAuthorization(authorization)
      try loadRepositoriesForConnectedUser()
      routeState = .onboarding(.repositories)
    } catch {
      handleAuth(error)
    }
  }

  @MainActor
  func pollGitHubAuthorization(_ authorization: GitHubDeviceAuthorization) async {
    while true {
      guard case let .authorizing(currentAuthorization) = routeState,
        currentAuthorization.deviceCode == authorization.deviceCode
      else {
        return
      }

      guard currentAuthorization.isExpired(at: currentDate()) == false else {
        return
      }

      let delayNanoseconds = UInt64(max(currentAuthorization.interval, 1)) * 1_000_000_000
      do {
        try await Task.sleep(nanoseconds: delayNanoseconds)
      } catch {
        return
      }

      guard case let .authorizing(latestAuthorization) = routeState,
        latestAuthorization.deviceCode == authorization.deviceCode,
        latestAuthorization.isExpired(at: currentDate()) == false
      else {
        return
      }

      continueGitHubAuthorization()
    }
  }

  func refreshGitHubAuthorization() {
    connectGitHub()
  }

  @MainActor
  @discardableResult
  func finishRepositorySetup() -> Task<Void, Never>? {
    persistIncludedRepositorySelection()

    routeState = .authenticated
    guard includedRepositories.isEmpty == false else {
      applyActivitySnapshot(GitHubActivitySnapshot(pullRequests: [], releases: [], anchorDate: activityAnchorDate))
      lastActivityRefreshAttemptAt = nil
      lastActivityRefreshAt = nil
      activityRefreshIssue = nil
      activityRefreshProgress = nil
      return nil
    }

    return Task {
      await refreshActivity()
    }
  }

  @MainActor
  func refreshActivity() async {
    guard isRefreshingActivity == false else {
      return
    }

    isRefreshingActivity = true
    activityRefreshIssue = nil
    activityRefreshProgress = ActivityRefreshProgress(
      totalRepositories: includedRepositories.count,
      completedRepositories: 0,
      currentRepositoryName: includedRepositories.first?.name,
      pullRequestCount: 0,
      releaseCount: 0
    )
    let attemptedAt = currentDate()
    lastActivityRefreshAttemptAt = attemptedAt
    let selectedPRDate = selectedPRDate
    let selectedReleaseDate = selectedReleaseDate
    let selectedReleaseID = selectedReleaseID
    let repositories = includedRepositories
    let anchorDate = activityAnchorDate
    let activityProvider = activityProvider

    defer {
      isRefreshingActivity = false
      activityRefreshProgress = nil
    }

    do {
      let snapshot = try await activityProvider.activityAsync(
        for: repositories,
        endingAt: anchorDate,
        lookbackDays: 30,
        progress: { progress in
          self.activityRefreshProgress = progress
        }
      )
      applyActivitySnapshot(snapshot)
      lastActivityRefreshAt = attemptedAt
      saveActivityCache(snapshot: snapshot, lastRefreshedAt: attemptedAt)
      self.selectedPRDate = selectedPRDate
      self.selectedReleaseDate = selectedReleaseDate
      if let selectedReleaseID, releases.contains(where: { $0.id == selectedReleaseID }) {
        self.selectedReleaseID = selectedReleaseID
      } else {
        self.selectedReleaseID = releases.first { CalendarDay.isSameDay($0.date, selectedReleaseDate) }?.id ?? releases.first?.id
      }
    } catch {
      activityRefreshIssue = authIssue(for: error).issue
    }
  }

  func disconnectGitHub() {
    try? authService.disconnect()
    try? repositorySelectionStore.clearIncludedRepositoryIDs()
    try? activityCacheStore.clear()
    githubConnection = .signedOut
    repositories = repositories.map { repository in
      var repository = repository
      repository.included = false
      return repository
    }
    routeState = .signedOut
  }

  func setRepositoryIncluded(_ repositoryID: Repository.ID, included: Bool) {
    guard let index = repositories.firstIndex(where: { $0.id == repositoryID }),
      repositories[index].access == .ready
    else {
      return
    }

    repositories[index].included = included
    persistIncludedRepositorySelection()
  }

  func setRepositoriesIncluded(_ repositoryIDs: Set<Repository.ID>, included: Bool) {
    var didUpdate = false
    for index in repositories.indices where repositoryIDs.contains(repositories[index].id) && repositories[index].access == .ready {
      repositories[index].included = included
      didUpdate = true
    }

    if didUpdate {
      persistIncludedRepositorySelection()
    }
  }

  @discardableResult
  private func loadRepositoriesForConnectedUser() throws -> Bool {
    let storedIDs = try repositorySelectionStore.loadIncludedRepositoryIDs()
    let fetchedRepositories = try repositoryProvider.repositories()
    if shouldResetStoredSelection(storedIDs, for: fetchedRepositories) {
      try? repositorySelectionStore.clearIncludedRepositoryIDs()
      try? activityCacheStore.clear()
      repositories = applyStoredSelection(to: fetchedRepositories, storedIDs: nil)
      return false
    }

    repositories = applyStoredSelection(to: fetchedRepositories, storedIDs: storedIDs)
    return storedIDs != nil
  }

  private func shouldResetStoredSelection(_ storedIDs: [Repository.ID]?, for repositories: [Repository]) -> Bool {
    guard let storedIDs else {
      return false
    }

    let availableRepositoryIDs = Set(repositories.filter { $0.access == .ready }.map(\.id))
    let restorableIDs = Set(storedIDs).intersection(availableRepositoryIDs)
    return restorableIDs.count > Self.maximumRestoredRepositorySelectionCount
  }

  private func refreshActivityForIncludedRepositories() throws {
    let attemptedAt = currentDate()
    lastActivityRefreshAttemptAt = attemptedAt
    let snapshot = try activityProvider.activity(
      for: includedRepositories,
      endingAt: activityAnchorDate,
      lookbackDays: 30
    )
    applyActivitySnapshot(snapshot)
    lastActivityRefreshAt = attemptedAt
    saveActivityCache(snapshot: snapshot, lastRefreshedAt: attemptedAt)
    activityRefreshIssue = nil
  }

  @discardableResult
  private func restoreCachedActivityForConnectedUser() -> Bool {
    guard let githubLogin = githubConnection.user?.login else {
      return false
    }

    let includedIDs = includedRepositories.map(\.id)
    guard let record = try? activityCacheStore.load(githubLogin: githubLogin, includedRepositoryIDs: includedIDs) else {
      return false
    }

    applyActivitySnapshot(record.snapshot)
    lastActivityRefreshAt = record.lastRefreshedAt
    lastActivityRefreshAttemptAt = nil
    activityRefreshIssue = nil
    return true
  }

  private func saveActivityCache(snapshot: GitHubActivitySnapshot, lastRefreshedAt: Date) {
    guard let githubLogin = githubConnection.user?.login else {
      return
    }

    let record = GitHubActivityCacheRecord(
      githubLogin: githubLogin,
      includedRepositoryIDs: includedRepositories.map(\.id),
      snapshot: snapshot,
      lastRefreshedAt: lastRefreshedAt
    )
    try? activityCacheStore.save(record)
  }

  private func persistIncludedRepositorySelection() {
    try? repositorySelectionStore.saveIncludedRepositoryIDs(includedRepositories.map(\.id))
  }

  private func applyActivitySnapshot(_ snapshot: GitHubActivitySnapshot) {
    pullRequests = snapshot.pullRequests
    releases = snapshot.releases
    activityAnchorDate = snapshot.anchorDate
    selectedPRDate = snapshot.anchorDate
    selectedReleaseDate = snapshot.anchorDate
    selectedReleaseID = snapshot.releases.first?.id
  }

  private func applyStoredSelection(to repositories: [Repository], storedIDs: [Repository.ID]?) -> [Repository] {
    return repositories.map { repository in
      var repository = repository
      if let storedIDs {
        repository.included = storedIDs.contains(repository.id)
      } else {
        repository.included = false
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
    } else if error is DecodingError {
      issue = AuthIssue(
        id: "github-response-changed",
        title: "GitHub response changed",
        message: "PRBar could not read the latest GitHub response. Try again after updating the app."
      )
    } else if let apiError = error as? GitHubAPIError {
      issue = authIssue(for: apiError)
    } else if error as? GitHubActivityError == .missingSession || error as? GitHubRepositoryError == .missingSession {
      issue = AuthIssue(
        id: "github-session-expired",
        title: "GitHub session expired",
        message: "Sign in to GitHub again to refresh PRs and releases."
      )
    } else {
      issue = AuthIssue(
        id: "github-sync-failed",
        title: "GitHub sync failed",
        message: "Try again. Existing PR and release data stays available while GitHub is unavailable."
      )
    }
    return .issue(issue)
  }

  private func authIssue(for apiError: GitHubAPIError) -> AuthIssue {
    switch apiError {
    case .unauthorized:
      return AuthIssue(
        id: "github-session-expired",
        title: "GitHub session expired",
        message: "Sign in to GitHub again to refresh PRs and releases."
      )
    case .forbidden, .ssoRequired:
      return AuthIssue(
        id: "github-access-blocked",
        title: "GitHub access needs attention",
        message: "Authorize SSO or check repository permissions, then refresh again."
      )
    case .rateLimited:
      return AuthIssue(
        id: "github-rate-limited",
        title: "GitHub rate limit reached",
        message: "GitHub is asking PRBar to slow down. Wait a bit, then refresh again."
      )
    case .notFound:
      return AuthIssue(
        id: "github-resource-unavailable",
        title: "GitHub data is unavailable",
        message: "A repository or release could not be found. Check repo access, then refresh again."
      )
    case .server:
      return AuthIssue(
        id: "github-server-error",
        title: "GitHub is having trouble",
        message: "GitHub returned a server error. Existing data stays available while you retry."
      )
    case .networkUnavailable, .timedOut:
      return AuthIssue(
        id: "github-network-unavailable",
        title: "GitHub is unreachable",
        message: "Check your connection and refresh again. Existing data stays available."
      )
    case .invalidResponse:
      return AuthIssue(
        id: "github-invalid-response",
        title: "GitHub sync failed",
        message: "GitHub returned an unexpected response. Existing data stays available while you retry."
      )
    }
  }

  private func handleAuth(_ error: Error) {
    if case let GitHubAuthError.authorizationPending(authorization) = error {
      routeState = .authorizing(authorization)
      return
    }

    githubConnection = .signedOut
    routeState = authIssue(for: error)
  }
}

private extension AppRouteState {
  var issue: AuthIssue? {
    if case let .issue(issue) = self {
      return issue
    }
    return nil
  }
}
