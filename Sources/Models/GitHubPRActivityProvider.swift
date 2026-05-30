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
  let repositoryPageSize = 100
  private let graphQLPageSize = 100
  let discoveryCacheDuration: TimeInterval
  let incrementalSearchOverlap: TimeInterval
  let mergedPullRequestCacheStore: GitHubMergedPullRequestCacheStoring?
  let discoveryCacheStore: GitHubDiscoveryCacheStoring?
  var discoveryCache: GitHubDiscoveryCache?
  var discoveryResponseCache: [String: GitHubCachedAPIResponse] = [:]
  var mergedPullRequestCache: GitHubMergedPullRequestCache?

  init(
    token: String,
    transport: GitHubAPITransport,
    bucketLabels: [String],
    defaultWindow: ActivityWindow = .oneWeek,
    discoveryCacheDuration: TimeInterval = 15 * 60,
    incrementalSearchOverlap: TimeInterval = 30 * 60,
    mergedPullRequestCacheStore: GitHubMergedPullRequestCacheStoring? = nil,
    discoveryCacheStore: GitHubDiscoveryCacheStoring? = nil,
    metrics: RefreshMetricsRecording? = nil
  ) {
    self.token = token
    self.transport = transport
    self.bucketLabels = bucketLabels
    self.defaultWindow = defaultWindow
    self.discoveryCacheDuration = discoveryCacheDuration
    self.incrementalSearchOverlap = incrementalSearchOverlap
    self.mergedPullRequestCacheStore = mergedPullRequestCacheStore
    self.discoveryCacheStore = discoveryCacheStore
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
        repositoryIDs: pullableRepositories.map(\.fullName).sorted(),
        since: since,
        until: now,
        forceFullRefresh: false
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
      dailyBucketCount: dailyBucketCount,
      isIncluded: false
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

struct GitHubDiscoveryResult {
  var cache: GitHubDiscoveryCache
  var cacheHit: Bool
}

struct GitHubDiscoveryCache: Codable, Equatable {
  var createdAt: Date
  var authenticatedUser: GitHubAuthenticatedUser
  var searchOwners: [GitHubSearchOwner]
  var pullableRepositories: [GitHubRepository]
}
