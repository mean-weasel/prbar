import Foundation

protocol GitHubAPITransport {
  func response(for request: URLRequest) throws -> GitHubAPIResponse
}

extension GitHubAPITransport {
  func data(for request: URLRequest) throws -> Data {
    try response(for: request).data
  }
}

struct GitHubAPIResponse: Equatable {
  var data: Data
  var eTag: String? = nil
  var statusCode: Int? = nil

  var isNotModified: Bool {
    statusCode == 304
  }
}

enum GitHubPRActivityProviderError: Error, Equatable {
  case graphQL(String)
  case notModifiedWithoutCachedData
}

final class GitHubPRActivityProvider: PRActivityProviding {
  var token: String
  var transport: GitHubAPITransport
  var bucketLabels: [String]
  var defaultWindow: ActivityWindow = .oneWeek
  weak var metrics: RefreshMetricsRecording?
  private let dailyBucketCount = 30
  private let repositoryPageSize = 100
  private let graphQLPageSize = 100
  private let discoveryCacheDuration: TimeInterval
  private var discoveryCache: GitHubDiscoveryCache?
  var discoveryResponseCache: [String: GitHubCachedAPIResponse] = [:]
  var mergedPullRequestCache: GitHubMergedPullRequestCache?

  init(
    token: String,
    transport: GitHubAPITransport,
    bucketLabels: [String],
    defaultWindow: ActivityWindow = .oneWeek,
    discoveryCacheDuration: TimeInterval = 15 * 60,
    metrics: RefreshMetricsRecording? = nil
  ) {
    self.token = token
    self.transport = transport
    self.bucketLabels = bucketLabels
    self.defaultWindow = defaultWindow
    self.discoveryCacheDuration = discoveryCacheDuration
    self.metrics = metrics
  }

  func load(now: Date = Date()) throws -> PRActivityStore {
    try measured("provider.load.total") {
      let discovery = try discovery(now: now)
      let pullableRepositories = discovery.cache.pullableRepositories
      guard pullableRepositories.isEmpty == false else {
        return store(activities: [], now: now)
      }
      let since = startDate(now: now)
      let mergedPullRequestsByRepository = try mergedPullRequestsByRepository(
        owners: discovery.cache.searchOwners,
        mergedBy: discovery.cache.authenticatedUser.login,
        since: since,
        until: now,
        forceFullRefresh: discovery.cacheHit == false
      )
      let activities = try measured("activity.bucket") {
        pullableRepositories.map { repository in
          activity(
            for: repository,
            mergedPullRequests: mergedPullRequestsByRepository[repository.fullName] ?? [],
            now: now
          )
        }
      }
      return store(activities: activities, now: now)
    }
  }

  private func discovery(now: Date) throws -> GitHubDiscoveryResult {
    if let discoveryCache,
      now.timeIntervalSince(discoveryCache.createdAt) < discoveryCacheDuration
    {
      recordMetric("discovery.cache_hit", metadata: ["cache": "hit"])
      return GitHubDiscoveryResult(cache: discoveryCache, cacheHit: true)
    }

    return try measured("discovery.total", metadata: ["cache": "miss"]) {
      let repositories = try repositories()
      let pullableRepositories = repositories.filter(\.canPull)
      if pullableRepositories.isEmpty {
        let discovery = GitHubDiscoveryCache(
          createdAt: now,
          authenticatedUser: GitHubAuthenticatedUser(login: ""),
          searchOwners: [],
          pullableRepositories: []
        )
        discoveryCache = discovery
        return GitHubDiscoveryResult(cache: discovery, cacheHit: false)
      }

      let authenticatedUser = try authenticatedUser()
      let discovery = GitHubDiscoveryCache(
        createdAt: now,
        authenticatedUser: authenticatedUser,
        searchOwners: try searchOwners(authenticatedUser: authenticatedUser),
        pullableRepositories: pullableRepositories
      )
      discoveryCache = discovery
      return GitHubDiscoveryResult(cache: discovery, cacheHit: false)
    }
  }

  private func store(activities: [RepositoryActivity], now: Date) -> PRActivityStore {
    let labels = PRActivityBucketSeries.weekly(
      mergedDates: [],
      bucketCount: bucketLabels.count,
      now: now
    )
    .labels
    let dailyLabels = PRActivityBucketSeries.daily(
      mergedDates: [],
      bucketCount: dailyBucketCount,
      now: now
    )
    .labels

    return PRActivityStore(
      bucketLabels: labels,
      dailyBucketLabels: dailyLabels,
      window: defaultWindow,
      bin: .day,
      refreshInterval: .daily,
      repositories: activities,
      refreshedAt: now
    )
  }

  private func authenticatedUser() throws -> GitHubAuthenticatedUser {
    try measured("discovery.authenticated_user") {
      let data = try discoveryData(for: GitHubAPIRequest.authenticatedUser())
      return try JSONDecoder().decode(GitHubAuthenticatedUser.self, from: data)
    }
  }

  private func organizations() throws -> [GitHubOrganization] {
    try measured("discovery.organizations") {
      let data = try discoveryData(for: GitHubAPIRequest.userOrganizations())
      return try JSONDecoder().decode([GitHubOrganization].self, from: data)
    }
  }

  private func searchOwners(authenticatedUser: GitHubAuthenticatedUser) throws
    -> [GitHubSearchOwner]
  {
    let userOwner = GitHubSearchOwner(kind: .user, login: authenticatedUser.login)
    let organizationOwners = try organizations().map {
      GitHubSearchOwner(kind: .org, login: $0.login)
    }
    return ([userOwner] + organizationOwners).sorted {
      if $0.kind.rawValue == $1.kind.rawValue {
        return $0.login < $1.login
      }
      return $0.kind.rawValue < $1.kind.rawValue
    }
  }

  private func repositories() throws -> [GitHubRepository] {
    var page = 1
    var repositories: [GitHubRepository] = []
    var pageRepositories: [GitHubRepository]

    repeat {
      pageRepositories = try measured(
        "discovery.repositories.page",
        metadata: ["page": "\(page)"]
      ) {
        let apiRequest = GitHubAPIRequest.userRepositories(
          page: page,
          perPage: repositoryPageSize
        )
        let data = try discoveryData(for: apiRequest)
        return try JSONDecoder().decode([GitHubRepository].self, from: data)
      }
      repositories.append(contentsOf: pageRepositories)
      page += 1
    } while pageRepositories.count == repositoryPageSize

    return repositories
  }

  private func activity(
    for repository: GitHubRepository,
    mergedPullRequests: [GitHubMergedPullRequest],
    now: Date
  ) -> RepositoryActivity {
    let series = PRActivityBucketSeries.weekly(
      mergedDates: mergedPullRequests.map(\.mergedAt),
      bucketCount: bucketLabels.count,
      now: now
    )
    let dailySeries = PRActivityBucketSeries.daily(
      mergedDates: mergedPullRequests.map(\.mergedAt),
      bucketCount: dailyBucketCount,
      now: now
    )
    var activity = repository.activity(
      bucketCount: bucketLabels.count,
      dailyBucketCount: dailyBucketCount
    )
    activity.weeklyCounts = series.counts
    activity.dailyCounts = dailySeries.counts
    return activity
  }

  func mergedPullRequests(
    owner: GitHubSearchOwner,
    mergedBy: String,
    since: Date,
    until: Date
  ) throws -> [GitHubMergedPullRequest] {
    var after: String?
    var items: [GitHubMergedPullRequest] = []
    var hasNextPage = false

    repeat {
      let response = try measured(
        "graphql.page",
        metadata: [
          "owner_kind": owner.kind.rawValue,
          "page": "\(items.count / graphQLPageSize + 1)",
        ]
      ) {
        let request = try GitHubGraphQLSearch.mergedPullRequestsRequest(
          token: token,
          owner: owner,
          mergedBy: mergedBy,
          since: since,
          until: until,
          first: graphQLPageSize,
          after: after
        )
        let data = try transport.data(for: request)
        return try JSONDecoder().decode(GitHubGraphQLSearchResponse.self, from: data)
      }
      if let errorMessage = response.errorMessage {
        throw GitHubPRActivityProviderError.graphQL(errorMessage)
      }
      guard let search = response.search else {
        throw GitHubPRActivityProviderError.graphQL("Missing search data")
      }
      items.append(
        contentsOf: search.nodes
          .filter { $0.mergedBy?.login == mergedBy }
          .map { $0.mergedPullRequest() }
      )
      hasNextPage = search.pageInfo.hasNextPage
      after = search.pageInfo.endCursor
    } while hasNextPage && after != nil

    return items
  }

  private func startDate(now: Date) -> Date {
    Calendar.prActivity.date(
      byAdding: .weekOfYear,
      value: -bucketLabels.count,
      to: now
    ) ?? now
  }
}

private struct GitHubDiscoveryResult {
  var cache: GitHubDiscoveryCache
  var cacheHit: Bool
}

private struct GitHubDiscoveryCache {
  var createdAt: Date
  var authenticatedUser: GitHubAuthenticatedUser
  var searchOwners: [GitHubSearchOwner]
  var pullableRepositories: [GitHubRepository]
}
