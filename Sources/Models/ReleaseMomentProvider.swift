import Foundation

protocol ReleaseMomentProvider {
  func fetchReleaseMoments(
    repositories: [RepositoryActivity],
    now: Date
  ) throws -> [ReleaseMoment]
}

struct SampleReleaseMomentProvider: ReleaseMomentProvider {
  func fetchReleaseMoments(
    repositories: [RepositoryActivity] = RepositoryActivity.samples,
    now: Date = Date()
  ) throws -> [ReleaseMoment] {
    [
      ReleaseMoment(
        id: "rel-deckchecker-140",
        repositoryID: "mean-weasel/deckchecker",
        title: "Live data polish",
        tag: "v1.4.0",
        date: now,
        notes:
          "Connects GitHub auth fallback, improves live data startup behavior, and preserves the last useful activity view.",
        url: URL(string: "https://github.com/mean-weasel/deckchecker/releases/tag/v1.4.0"),
        source: .githubRelease
      ),
      ReleaseMoment(
        id: "tag-seatify-100",
        repositoryID: "mean-weasel/seatify",
        title: "Launch workflow",
        tag: "v1.0.0",
        date: Calendar.prActivity.date(byAdding: .day, value: -2, to: now) ?? now,
        notes:
          "Generated from merged PRs around this tag: release smoke harness and launch notes template.",
        url: URL(string: "https://github.com/mean-weasel/seatify/releases/tag/v1.0.0"),
        source: .tag
      ),
      ReleaseMoment(
        id: "rel-redditreminder-092",
        repositoryID: "neonwatty/RedditReminder",
        title: "Reminder workflow hardening",
        tag: "v0.9.2",
        date: Calendar.prActivity.date(byAdding: .day, value: -5, to: now) ?? now,
        notes:
          "Improves reminder delivery checks and adds clearer recovery states for stale local data.",
        url: URL(string: "https://github.com/neonwatty/RedditReminder/releases/tag/v0.9.2"),
        source: .githubRelease
      ),
    ]
  }
}

final class GitHubReleaseMomentProvider: ReleaseMomentProvider {
  var token: String
  var transport: GitHubAPITransport
  private let pageSize = 1
  private let cacheDuration: TimeInterval
  private var cache: ReleaseMomentCache?

  init(
    token: String,
    transport: GitHubAPITransport,
    cacheDuration: TimeInterval = 15 * 60
  ) {
    self.token = token
    self.transport = transport
    self.cacheDuration = cacheDuration
  }

  func fetchReleaseMoments(
    repositories: [RepositoryActivity],
    now: Date = Date()
  ) throws -> [ReleaseMoment] {
    let includedRepositoryIDs = repositories.filter(\.isIncluded).map(\.id).sorted()
    if let cache,
      cache.repositoryIDs == includedRepositoryIDs,
      now.timeIntervalSince(cache.createdAt) < cacheDuration
    {
      return cache.releases
    }

    let releases =
      try repositories
      .filter(\.isIncluded)
      .compactMap { repository in
        try releaseMoment(for: repository, now: now)
      }
      .sorted { $0.date > $1.date }
    cache = ReleaseMomentCache(
      createdAt: now,
      repositoryIDs: includedRepositoryIDs,
      releases: releases
    )
    return releases
  }

  private func releaseMoment(
    for repository: RepositoryActivity,
    now: Date
  ) throws -> ReleaseMoment? {
    if let release = try latestRelease(for: repository.id) {
      return release.moment(repositoryID: repository.id)
    }

    guard let tag = try latestTag(for: repository.id) else {
      return nil
    }
    return tag.moment(repositoryID: repository.id, now: now)
  }

  private func latestRelease(for repositoryID: String) throws -> GitHubRelease? {
    let request = try GitHubAPIRequest.latestReleases(
      repositoryID: repositoryID,
      perPage: pageSize
    )
    .urlRequest(token: token)
    let releases = try decoder.decode(
      [GitHubRelease].self,
      from: transport.data(for: request)
    )
    return releases.first
  }

  private func latestTag(for repositoryID: String) throws -> GitHubTag? {
    let request = try GitHubAPIRequest.tags(
      repositoryID: repositoryID,
      perPage: pageSize
    )
    .urlRequest(token: token)
    let tags = try decoder.decode([GitHubTag].self, from: transport.data(for: request))
    return tags.first
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}

private struct GitHubRelease: Decodable {
  var id: Int
  var tagName: String
  var name: String?
  var body: String?
  var publishedAt: Date
  var htmlURL: URL?

  func moment(repositoryID: String) -> ReleaseMoment {
    ReleaseMoment(
      id: "release-\(repositoryID)-\(id)",
      repositoryID: repositoryID,
      title: name?.nonEmpty ?? "Release",
      tag: tagName,
      date: publishedAt,
      notes: body?.nonEmpty ?? "No release notes provided.",
      url: htmlURL,
      source: .githubRelease
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case tagName = "tag_name"
    case name
    case body
    case publishedAt = "published_at"
    case htmlURL = "html_url"
  }
}

private struct GitHubTag: Decodable {
  var name: String

  func moment(repositoryID: String, now: Date) -> ReleaseMoment {
    ReleaseMoment(
      id: "tag-\(repositoryID)-\(name)",
      repositoryID: repositoryID,
      title: "Tagged version",
      tag: name,
      date: now,
      notes: "Generated from the latest Git tag because this repository has no GitHub Releases.",
      url: URL(string: "https://github.com/\(repositoryID)/releases/tag/\(name)"),
      source: .tag
    )
  }
}

private struct ReleaseMomentCache {
  var createdAt: Date
  var repositoryIDs: [String]
  var releases: [ReleaseMoment]
}
