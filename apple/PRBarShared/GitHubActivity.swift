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
      anchorDate: snapshot.anchorDate
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
      anchorDate: snapshot.anchorDate
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

    for repository in repositories where repository.access == .ready {
      pullRequests.append(contentsOf: try repositoryPullRequests(repository, token: session.accessToken, startDate: startDate))
      releases.append(contentsOf: try repositoryReleasesAndTags(repository, token: session.accessToken, startDate: startDate))
    }

    return GitHubActivitySnapshot(
      pullRequests: pullRequests.sorted { $0.mergedAt > $1.mergedAt },
      releases: releases.sorted { $0.date > $1.date },
      anchorDate: calendar.startOfDay(for: endDate)
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

    await progress?(
      ActivityRefreshProgress(
        totalRepositories: readyRepositories.count,
        completedRepositories: 0,
        currentRepositoryName: readyRepositories.first?.name,
        pullRequestCount: 0,
        releaseCount: 0
      )
    )

    for (index, repository) in readyRepositories.enumerated() {
      await progress?(
        ActivityRefreshProgress(
          totalRepositories: readyRepositories.count,
          completedRepositories: index,
          currentRepositoryName: repository.name,
          pullRequestCount: pullRequests.count,
          releaseCount: releases.count
        )
      )
      pullRequests.append(contentsOf: try repositoryPullRequests(repository, token: session.accessToken, startDate: startDate))
      releases.append(contentsOf: try repositoryReleasesAndTags(repository, token: session.accessToken, startDate: startDate))
      await progress?(
        ActivityRefreshProgress(
          totalRepositories: readyRepositories.count,
          completedRepositories: index + 1,
          currentRepositoryName: readyRepositories[safe: index + 1]?.name,
          pullRequestCount: pullRequests.count,
          releaseCount: releases.count
        )
      )
    }

    return GitHubActivitySnapshot(
      pullRequests: pullRequests.sorted { $0.mergedAt > $1.mergedAt },
      releases: releases.sorted { $0.date > $1.date },
      anchorDate: calendar.startOfDay(for: endDate)
    )
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
