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
  var metrics: RefreshMetricsRecording?
  private let pageSize = 1
  private let cacheDuration: TimeInterval
  private let maxConcurrentRequests: Int
  private var cache: ReleaseMomentCache?

  init(
    token: String,
    transport: GitHubAPITransport,
    cacheDuration: TimeInterval = 15 * 60,
    maxConcurrentRequests: Int = 6,
    metrics: RefreshMetricsRecording? = nil
  ) {
    self.token = token
    self.transport = transport
    self.cacheDuration = cacheDuration
    self.maxConcurrentRequests = max(1, maxConcurrentRequests)
    self.metrics = metrics
  }

  func fetchReleaseMoments(
    repositories: [RepositoryActivity],
    now: Date = Date()
  ) throws -> [ReleaseMoment] {
    let startedAt = Date()
    let includedRepositoryIDs = repositories.filter(\.isIncluded).map(\.id).sorted()
    if let cache,
      cache.repositoryIDs == includedRepositoryIDs,
      now.timeIntervalSince(cache.createdAt) < cacheDuration
    {
      recordFetchMetric(
        startedAt: startedAt,
        repositoryCount: includedRepositoryIDs.count,
        releaseRequestCount: 0,
        tagRequestCount: 0,
        momentCount: cache.releases.count,
        result: "cache_hit"
      )
      return cache.releases
    }

    let includedRepositories = repositories.filter(\.isIncluded)
    let counters = ReleaseMomentRequestCounters()
    let releases = try fetchReleaseMomentsConcurrently(
      repositories: includedRepositories,
      now: now,
      counters: counters
    )
    .sorted { $0.date > $1.date }
    cache = ReleaseMomentCache(
      createdAt: now,
      repositoryIDs: includedRepositoryIDs,
      releases: releases
    )
    recordFetchMetric(
      startedAt: startedAt,
      repositoryCount: includedRepositories.count,
      releaseRequestCount: counters.releaseRequestCount,
      tagRequestCount: counters.tagRequestCount,
      momentCount: releases.count,
      result: "fetched"
    )
    return releases
  }

  private func fetchReleaseMomentsConcurrently(
    repositories: [RepositoryActivity],
    now: Date,
    counters: ReleaseMomentRequestCounters
  ) throws -> [ReleaseMoment] {
    if maxConcurrentRequests == 1 {
      return try repositories.compactMap { repository in
        try releaseMoment(for: repository, now: now, counters: counters)
      }
    }

    let results = ReleaseMomentConcurrentResults(count: repositories.count)
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: maxConcurrentRequests)

    for (index, repository) in repositories.enumerated() {
      semaphore.wait()
      group.enter()
      DispatchQueue.global(qos: .utility).async {
        defer {
          semaphore.signal()
          group.leave()
        }
        do {
          let moment = try self.releaseMoment(
            for: repository,
            now: now,
            counters: counters
          )
          results.setMoment(moment, at: index)
        } catch {
          results.setErrorIfNeeded(error)
        }
      }
    }

    group.wait()
    if let error = results.error {
      recordFetchError(error, repositoryCount: repositories.count, counters: counters)
      throw error
    }
    return results.moments
  }

  private func releaseMoment(
    for repository: RepositoryActivity,
    now: Date,
    counters: ReleaseMomentRequestCounters
  ) throws -> ReleaseMoment? {
    if let release = try latestRelease(for: repository.id, counters: counters) {
      return release.moment(repositoryID: repository.id)
    }

    guard let tag = try latestTag(for: repository.id, counters: counters) else {
      return nil
    }
    return tag.moment(repositoryID: repository.id, now: now)
  }

  private func latestRelease(
    for repositoryID: String,
    counters: ReleaseMomentRequestCounters
  ) throws -> GitHubRelease? {
    let request = try GitHubAPIRequest.latestReleases(
      repositoryID: repositoryID,
      perPage: pageSize
    )
    .urlRequest(token: token)
    counters.incrementReleaseRequestCount()
    let releases = try decoder.decode(
      [GitHubRelease].self,
      from: transport.data(for: request)
    )
    return releases.first
  }

  private func latestTag(
    for repositoryID: String,
    counters: ReleaseMomentRequestCounters
  ) throws -> GitHubTag? {
    let request = try GitHubAPIRequest.tags(
      repositoryID: repositoryID,
      perPage: pageSize
    )
    .urlRequest(token: token)
    counters.incrementTagRequestCount()
    let tags = try decoder.decode([GitHubTag].self, from: transport.data(for: request))
    return tags.first
  }

  private func recordFetchError(
    _ error: Error,
    repositoryCount: Int,
    counters: ReleaseMomentRequestCounters
  ) {
    metrics?.record(
      RefreshMetricEvent(
        name: "release.fetch.error",
        durationMilliseconds: 0,
        metadata: [
          "repository_count": "\(repositoryCount)",
          "release_requests": "\(counters.releaseRequestCount)",
          "tag_requests": "\(counters.tagRequestCount)",
          "error": String(describing: type(of: error)),
        ]
      )
    )
  }

  private func recordFetchMetric(
    startedAt: Date,
    repositoryCount: Int,
    releaseRequestCount: Int,
    tagRequestCount: Int,
    momentCount: Int,
    result: String
  ) {
    metrics?.record(
      RefreshMetricEvent(
        name: "release.fetch.total",
        durationMilliseconds: Date().timeIntervalSince(startedAt) * 1_000,
        metadata: [
          "repository_count": "\(repositoryCount)",
          "release_requests": "\(releaseRequestCount)",
          "tag_requests": "\(tagRequestCount)",
          "moment_count": "\(momentCount)",
          "max_concurrent_requests": "\(maxConcurrentRequests)",
          "result": result,
        ]
      )
    )
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
