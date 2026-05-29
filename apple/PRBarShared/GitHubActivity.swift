import Foundation

enum GitHubActivityError: Error, Equatable {
  case missingSession
  case invalidURL
  case invalidResponse
}

struct GitHubActivitySnapshot: Codable, Equatable, Sendable {
  var pullRequests: [PullRequest]
  var releases: [ReleaseMoment]
  var anchorDate: Date
  var repositoryIssues: [ActivityRepositoryIssue]

  init(
    pullRequests: [PullRequest],
    releases: [ReleaseMoment],
    anchorDate: Date,
    repositoryIssues: [ActivityRepositoryIssue] = []
  ) {
    self.pullRequests = pullRequests
    self.releases = releases
    self.anchorDate = anchorDate
    self.repositoryIssues = repositoryIssues
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    pullRequests = try container.decode([PullRequest].self, forKey: .pullRequests)
    releases = try container.decode([ReleaseMoment].self, forKey: .releases)
    anchorDate = try container.decode(Date.self, forKey: .anchorDate)
    repositoryIssues = try container.decodeIfPresent([ActivityRepositoryIssue].self, forKey: .repositoryIssues) ?? []
  }
}

protocol GitHubActivityProviding: Sendable {
  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot
  func activityAsync(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) async throws -> GitHubActivitySnapshot
  func activityAsync(
    for repositories: [Repository],
    endingAt endDate: Date,
    lookbackDays: Int,
    progress: (@MainActor (ActivityRefreshProgress) -> Void)?
  ) async throws -> GitHubActivitySnapshot
}

extension GitHubActivityProviding {
  func activityAsync(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) async throws -> GitHubActivitySnapshot {
    try activity(for: repositories, endingAt: endDate, lookbackDays: lookbackDays)
  }

  func activityAsync(
    for repositories: [Repository],
    endingAt endDate: Date,
    lookbackDays: Int,
    progress: (@MainActor (ActivityRefreshProgress) -> Void)?
  ) async throws -> GitHubActivitySnapshot {
    let snapshot = try activity(for: repositories, endingAt: endDate, lookbackDays: lookbackDays)
    await progress?(
      ActivityRefreshProgress(
        totalRepositories: repositories.count,
        completedRepositories: repositories.count,
        currentRepositoryName: nil,
        pullRequestCount: snapshot.pullRequests.count,
        releaseCount: snapshot.releases.count
      )
    )
    return snapshot
  }
}

struct StaticGitHubActivityProvider: GitHubActivityProviding {
  var snapshot: GitHubActivitySnapshot

  init(snapshot: GitHubActivitySnapshot = SampleData.activitySnapshot) {
    self.snapshot = snapshot
  }

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    let includedIDs = Set(repositories.map(\.id))
    return GitHubActivitySnapshot(
      pullRequests: snapshot.pullRequests.filter { includedIDs.contains($0.repoID) },
      releases: snapshot.releases.filter { includedIDs.contains($0.repoID) },
      anchorDate: snapshot.anchorDate,
      repositoryIssues: snapshot.repositoryIssues.filter { includedIDs.contains($0.repositoryID) }
    )
  }
}

final class SequencedGitHubActivityProvider: GitHubActivityProviding, @unchecked Sendable {
  private var snapshots: [GitHubActivitySnapshot]
  private let lock = NSLock()

  init(snapshots: [GitHubActivitySnapshot]) {
    self.snapshots = snapshots
  }

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    lock.lock()
    defer { lock.unlock() }

    guard snapshots.isEmpty == false else {
      return GitHubActivitySnapshot(pullRequests: [], releases: [], anchorDate: endDate)
    }

    let snapshot = snapshots.removeFirst()
    let includedIDs = Set(repositories.map(\.id))
    return GitHubActivitySnapshot(
      pullRequests: snapshot.pullRequests.filter { includedIDs.contains($0.repoID) },
      releases: snapshot.releases.filter { includedIDs.contains($0.repoID) },
      anchorDate: snapshot.anchorDate,
      repositoryIssues: snapshot.repositoryIssues.filter { includedIDs.contains($0.repositoryID) }
    )
  }
}

enum GitHubActivityRequest {
  static func pullRequests(repository: Repository, token: String, page: Int) throws -> URLRequest {
    try repositoryRequest(
      path: "pulls",
      query: "state=closed&sort=updated&direction=desc&per_page=100&page=\(page)",
      repository: repository,
      token: token
    )
  }

  static func releases(repository: Repository, token: String, page: Int) throws -> URLRequest {
    try repositoryRequest(
      path: "releases",
      query: "per_page=100&page=\(page)",
      repository: repository,
      token: token
    )
  }

  static func tags(repository: Repository, token: String, page: Int) throws -> URLRequest {
    try repositoryRequest(
      path: "tags",
      query: "per_page=100&page=\(page)",
      repository: repository,
      token: token
    )
  }

  static func commit(url: URL, token: String) -> URLRequest {
    authorizedRequest(url: url, token: token)
  }

  private static func repositoryRequest(
    path: String,
    query: String,
    repository: Repository,
    token: String
  ) throws -> URLRequest {
    guard let url = URL(string: "https://api.github.com/repos/\(repository.owner)/\(repository.name)/\(path)?\(query)") else {
      throw GitHubActivityError.invalidURL
    }
    return authorizedRequest(url: url, token: token)
  }

  private static func authorizedRequest(url: URL, token: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    return request
  }
}

struct GitHubActivityClient: GitHubActivityProviding, @unchecked Sendable {
  var sessionStore: GitHubSessionStoring
  var transport: GitHubRepositoryTransport
  var maximumTagPages = 1
  var maximumConcurrentRepositories = 4
  var calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    guard let session = try sessionStore.loadSession() else {
      throw GitHubActivityError.missingSession
    }

    let startDate = calendar.date(byAdding: .day, value: -max(lookbackDays - 1, 0), to: calendar.startOfDay(for: endDate)) ?? endDate
    var pullRequests: [PullRequest] = []
    var releases: [ReleaseMoment] = []
    var repositoryIssues: [ActivityRepositoryIssue] = []

    for repository in repositories where repository.access == .ready {
      do {
        pullRequests.append(contentsOf: try repositoryPullRequests(repository, token: session.accessToken, startDate: startDate))
        releases.append(contentsOf: try repositoryReleasesAndTags(repository, token: session.accessToken, startDate: startDate))
      } catch {
        if isGlobalFailure(error) {
          throw error
        }
        repositoryIssues.append(repositoryIssue(for: error, repository: repository))
      }
    }

    return GitHubActivitySnapshot(
      pullRequests: pullRequests.sorted { $0.mergedAt > $1.mergedAt },
      releases: releases.sorted { $0.date > $1.date },
      anchorDate: calendar.startOfDay(for: endDate),
      repositoryIssues: repositoryIssues
    )
  }

  func activityAsync(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) async throws -> GitHubActivitySnapshot {
    try await activityAsync(for: repositories, endingAt: endDate, lookbackDays: lookbackDays, progress: nil)
  }

  func activityAsync(
    for repositories: [Repository],
    endingAt endDate: Date,
    lookbackDays: Int,
    progress: (@MainActor (ActivityRefreshProgress) -> Void)?
  ) async throws -> GitHubActivitySnapshot {
    guard let session = try sessionStore.loadSession() else {
      throw GitHubActivityError.missingSession
    }

    let startDate = calendar.date(byAdding: .day, value: -max(lookbackDays - 1, 0), to: calendar.startOfDay(for: endDate)) ?? endDate
    let readyRepositories = repositories.filter { $0.access == .ready }
    var pullRequests: [PullRequest] = []
    var releases: [ReleaseMoment] = []
    var repositoryIssues: [ActivityRepositoryIssue] = []

    await progress?(
      ActivityRefreshProgress(
        totalRepositories: readyRepositories.count,
        completedRepositories: 0,
        currentRepositoryName: readyRepositories.first?.name,
        pullRequestCount: 0,
        releaseCount: 0
      )
    )

    let repositoryLimit = min(max(1, maximumConcurrentRepositories), readyRepositories.count)
    var nextRepositoryIndex = 0
    var completedRepositories = 0
    var repositoryResults: [RepositoryActivityResult] = []

    try await withThrowingTaskGroup(of: RepositoryActivityResult.self) { group in
      while nextRepositoryIndex < repositoryLimit {
        let index = nextRepositoryIndex
        let repository = readyRepositories[index]
        nextRepositoryIndex += 1
        group.addTask {
          try Task.checkCancellation()
          return try repositoryActivityResult(repository, token: session.accessToken, startDate: startDate, index: index)
        }
      }

      while let result = try await group.next() {
        completedRepositories += 1
        repositoryResults.append(result)
        pullRequests.append(contentsOf: result.pullRequests)
        releases.append(contentsOf: result.releases)

        if nextRepositoryIndex < readyRepositories.count {
          let index = nextRepositoryIndex
          let repository = readyRepositories[index]
          nextRepositoryIndex += 1
          group.addTask {
            try Task.checkCancellation()
            return try repositoryActivityResult(repository, token: session.accessToken, startDate: startDate, index: index)
          }
        }

        await progress?(
          ActivityRefreshProgress(
            totalRepositories: readyRepositories.count,
            completedRepositories: completedRepositories,
            currentRepositoryName: readyRepositories[safe: nextRepositoryIndex]?.name,
            pullRequestCount: pullRequests.count,
            releaseCount: releases.count
          )
        )
      }
    }

    repositoryIssues = repositoryResults
      .sorted { $0.index < $1.index }
      .compactMap(\.issue)

    return GitHubActivitySnapshot(
      pullRequests: pullRequests.sorted { $0.mergedAt > $1.mergedAt },
      releases: releases.sorted { $0.date > $1.date },
      anchorDate: calendar.startOfDay(for: endDate),
      repositoryIssues: repositoryIssues
    )
  }

  private func repositoryActivityResult(
    _ repository: Repository,
    token: String,
    startDate: Date,
    index: Int
  ) throws -> RepositoryActivityResult {
    do {
      return RepositoryActivityResult(
        index: index,
        pullRequests: try repositoryPullRequests(repository, token: token, startDate: startDate),
        releases: try repositoryReleasesAndTags(repository, token: token, startDate: startDate),
        issue: nil
      )
    } catch {
      if isGlobalFailure(error) {
        throw error
      }
      return RepositoryActivityResult(
        index: index,
        pullRequests: [],
        releases: [],
        issue: repositoryIssue(for: error, repository: repository)
      )
    }
  }

  private func isGlobalFailure(_ error: Error) -> Bool {
    if error as? GitHubAPIError == .unauthorized {
      return true
    }
    if error as? GitHubActivityError == .missingSession || error as? GitHubRepositoryError == .missingSession {
      return true
    }
    return false
  }

  private func repositoryIssue(for error: Error, repository: Repository) -> ActivityRepositoryIssue {
    ActivityRepositoryIssue(
      repositoryID: repository.id,
      repositoryFullName: repository.fullName,
      title: "Repository needs attention",
      message: repositoryIssueMessage(for: error, repository: repository)
    )
  }

  private func repositoryIssueMessage(for error: Error, repository: Repository) -> String {
    if let apiError = error as? GitHubAPIError {
      switch apiError {
      case .ssoRequired:
        return "Authorize SSO for \(repository.fullName), then refresh again."
      case .forbidden:
        return "Check GitHub App access or repository permissions for \(repository.fullName), then refresh again."
      case .rateLimited:
        return "GitHub rate limited \(repository.fullName). Wait a bit, then refresh again."
      case .notFound:
        return "\(repository.fullName) was not available. Check GitHub App installation, SSO, or repository permissions."
      case .networkUnavailable, .timedOut:
        return "PRBar could not reach GitHub for \(repository.fullName). Check the connection, then refresh again."
      case .server:
        return "GitHub had trouble returning \(repository.fullName). Refresh again in a bit."
      case .invalidResponse:
        return "GitHub returned an unexpected response for \(repository.fullName). Refresh again after updating PRBar."
      case .unauthorized:
        return "Sign in to GitHub again to refresh \(repository.fullName)."
      }
    }

    if error is DecodingError {
      return "PRBar could not read GitHub data for \(repository.fullName). Refresh again after updating PRBar."
    }

    return "PRBar could not sync \(repository.fullName). Check access, then refresh again."
  }

  private func repositoryPullRequests(_ repository: Repository, token: String, startDate: Date) throws -> [PullRequest] {
    var page = 1
    var pullRequests: [PullRequest] = []
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    while true {
      let request = try GitHubActivityRequest.pullRequests(repository: repository, token: token, page: page)
      let data = try transport.data(for: request)
      let pageItems = try decoder.decode([GitHubPullRequestActivityPayload].self, from: data)
      pullRequests.append(contentsOf: pageItems.compactMap { $0.pullRequest(repositoryID: repository.id, startDate: startDate) })

      if pageItems.count < 100 || pageItems.allSatisfy({ $0.isStale(for: startDate) }) {
        break
      }
      page += 1
    }

    return pullRequests
  }

  private func repositoryReleasesAndTags(_ repository: Repository, token: String, startDate: Date) throws -> [ReleaseMoment] {
    let releasePayloads = try pagedReleases(repository, token: token, startDate: startDate)
    var releaseMoments = releasePayloads.compactMap { $0.release(repository: repository, startDate: startDate) }
    let releaseTags = Set(releaseMoments.map(\.tag))

    let tagPayloads = try pagedTags(repository, token: token)
    for tagPayload in tagPayloads where releaseTags.contains(tagPayload.name) == false {
      guard let tagMoment = try tagPayload.release(repository: repository, token: token, transport: transport, startDate: startDate) else {
        continue
      }
      releaseMoments.append(tagMoment)
    }

    return releaseMoments
  }

  private func pagedReleases(_ repository: Repository, token: String, startDate: Date) throws -> [GitHubReleaseActivityPayload] {
    var page = 1
    var releases: [GitHubReleaseActivityPayload] = []
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    while true {
      let request = try GitHubActivityRequest.releases(repository: repository, token: token, page: page)
      let data = try transport.data(for: request)
      let pageItems = try decoder.decode([GitHubReleaseActivityPayload].self, from: data)
      releases.append(contentsOf: pageItems)
      if pageItems.count < 100 || pageItems.allSatisfy({ $0.isStale(for: startDate) }) {
        break
      }
      page += 1
    }

    return releases
  }

  private func pagedTags(_ repository: Repository, token: String) throws -> [GitHubTagActivityPayload] {
    var page = 1
    var tags: [GitHubTagActivityPayload] = []

    while page <= maximumTagPages {
      let request = try GitHubActivityRequest.tags(repository: repository, token: token, page: page)
      let data = try transport.data(for: request)
      let pageItems = try JSONDecoder().decode([GitHubTagActivityPayload].self, from: data)
      tags.append(contentsOf: pageItems)
      if pageItems.count < 100 {
        break
      }
      page += 1
    }

    return tags
  }
}

private struct GitHubPullRequestActivityPayload: Decodable {
  var id: Int
  var number: Int
  var title: String
  var mergedAt: Date?
  var updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case number
    case title
    case mergedAt = "merged_at"
    case updatedAt = "updated_at"
  }

  func pullRequest(repositoryID: Repository.ID, startDate: Date) -> PullRequest? {
    guard let mergedAt, mergedAt >= startDate else {
      return nil
    }

    return PullRequest(
      id: "\(repositoryID)#\(number)",
      title: title,
      repoID: repositoryID,
      number: number,
      mergedAt: mergedAt
    )
  }

  func isStale(for startDate: Date) -> Bool {
    (updatedAt ?? mergedAt ?? Date.distantPast) < startDate
  }
}

private struct RepositoryActivityResult: Sendable {
  var index: Int
  var pullRequests: [PullRequest]
  var releases: [ReleaseMoment]
  var issue: ActivityRepositoryIssue?
}

private struct GitHubReleaseActivityPayload: Decodable {
  var id: Int
  var tagName: String
  var name: String?
  var body: String?
  var htmlURL: URL
  var publishedAt: Date?
  var createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case tagName = "tag_name"
    case name
    case body
    case htmlURL = "html_url"
    case publishedAt = "published_at"
    case createdAt = "created_at"
  }

  func release(repository: Repository, startDate: Date) -> ReleaseMoment? {
    let date = publishedAt ?? createdAt
    guard let date, date >= startDate else {
      return nil
    }

    return ReleaseMoment(
      id: "\(repository.id)@release:\(tagName)",
      repoID: repository.id,
      title: (name?.isEmpty == false ? name : nil) ?? tagName,
      tag: tagName,
      date: date,
      source: .release,
      notes: (body?.isEmpty == false ? body : nil) ?? "No release notes available.",
      url: htmlURL
    )
  }

  func isStale(for startDate: Date) -> Bool {
    (publishedAt ?? createdAt ?? Date.distantPast) < startDate
  }
}

private struct GitHubTagActivityPayload: Decodable {
  struct Commit: Decodable {
    var url: URL
  }

  var name: String
  var commit: Commit

  func release(
    repository: Repository,
    token: String,
    transport: GitHubRepositoryTransport,
    startDate: Date
  ) throws -> ReleaseMoment? {
    let request = GitHubActivityRequest.commit(url: commit.url, token: token)
    let data = try transport.data(for: request)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let commitPayload = try decoder.decode(GitHubCommitActivityPayload.self, from: data)
    guard let date = commitPayload.date, date >= startDate else {
      return nil
    }

    return ReleaseMoment(
      id: "\(repository.id)@tag:\(name)",
      repoID: repository.id,
      title: "Tagged \(name)",
      tag: name,
      date: date,
      source: .tag,
      notes: "No GitHub Release notes found. PRBar summarized this tag from GitHub commit metadata.",
      url: URL(string: "https://github.com/\(repository.owner)/\(repository.name)/releases/tag/\(name)") ?? commitPayload.htmlURL ?? commit.url
    )
  }
}

private struct GitHubCommitActivityPayload: Decodable {
  struct Commit: Decodable {
    struct Signature: Decodable {
      var date: Date?
    }

    var committer: Signature?
    var author: Signature?
  }

  var commit: Commit
  var htmlURL: URL?

  var date: Date? {
    commit.committer?.date ?? commit.author?.date
  }

  enum CodingKeys: String, CodingKey {
    case commit
    case htmlURL = "html_url"
  }
}

private extension Array {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
