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
    githubConnection: GitHubConnection = GitHubConnection(status: .connected, user: GitHubUser(login: "neonwatty", displayName: "Neon Watty"))
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
  }

  static func sample() -> PRBarStore {
    PRBarStore(
      repositories: SampleData.repositories,
      pullRequests: SampleData.pullRequests,
      releases: SampleData.releases,
      selectedPRDate: SampleData.today,
      selectedReleaseDate: SampleData.today
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

  func connectGitHubForPrototype() {
    githubConnection = GitHubConnection(status: .connected, user: GitHubUser(login: "neonwatty", displayName: "Neon Watty"))
    repositories = repositories.map { repository in
      var repository = repository
      repository.included = repository.recommended && repository.visibility == .public && repository.access == .ready
      return repository
    }
    routeState = .onboarding(.repositories)
  }

  func finishRepositorySetup() {
    routeState = .authenticated
  }

  func disconnectGitHub() {
    githubConnection = .signedOut
    repositories = repositories.map { repository in
      var repository = repository
      repository.included = false
      return repository
    }
    routeState = .signedOut
  }
}
