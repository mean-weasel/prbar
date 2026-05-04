import Foundation

protocol GitHubAPITransport {
  func data(for request: URLRequest) throws -> Data
}

enum GitHubPRActivityProviderError: Error, Equatable {
  case graphQL(String)
}

struct GitHubPRActivityProvider: PRActivityProviding {
  var token: String
  var transport: GitHubAPITransport
  var bucketLabels: [String]
  var defaultWindow: ActivityWindow = .oneWeek
  private let dailyBucketCount = 30
  private let repositoryPageSize = 100
  private let graphQLPageSize = 100

  func load(now: Date = Date()) throws -> PRActivityStore {
    let repositories = try repositories()
    let pullableRepositories = repositories.filter(\.canPull)
    guard pullableRepositories.isEmpty == false else {
      return store(activities: [], now: now)
    }
    let authenticatedUser = try authenticatedUser()
    let searchOwners = try searchOwners(authenticatedUser: authenticatedUser)
    let since = startDate(now: now)
    let mergedPullRequestsByRepository = try mergedPullRequestsByRepository(
      owners: searchOwners,
      mergedBy: authenticatedUser.login,
      since: since,
      until: now
    )
    let activities = pullableRepositories.map { repository in
      activity(
        for: repository,
        mergedPullRequests: mergedPullRequestsByRepository[repository.fullName] ?? [],
        now: now
      )
    }
    return store(activities: activities, now: now)
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
    let request = try GitHubAPIRequest.authenticatedUser().urlRequest(token: token)
    let data = try transport.data(for: request)
    return try JSONDecoder().decode(GitHubAuthenticatedUser.self, from: data)
  }

  private func organizations() throws -> [GitHubOrganization] {
    let request = try GitHubAPIRequest.userOrganizations().urlRequest(token: token)
    let data = try transport.data(for: request)
    return try JSONDecoder().decode([GitHubOrganization].self, from: data)
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
      let request = try GitHubAPIRequest.userRepositories(
        page: page,
        perPage: repositoryPageSize
      )
      .urlRequest(token: token)
      let data = try transport.data(for: request)
      pageRepositories = try JSONDecoder().decode([GitHubRepository].self, from: data)
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

  private func mergedPullRequestsByRepository(
    owners: [GitHubSearchOwner],
    mergedBy: String,
    since: Date,
    until: Date
  ) throws -> [String: [GitHubMergedPullRequest]] {
    var grouped: [String: [GitHubMergedPullRequest]] = [:]
    for owner in owners {
      for pullRequest in try mergedPullRequests(
        owner: owner,
        mergedBy: mergedBy,
        since: since,
        until: until
      ) {
        grouped[pullRequest.repositoryID, default: []].append(pullRequest)
      }
    }
    return grouped
  }

  private func mergedPullRequests(
    owner: GitHubSearchOwner,
    mergedBy: String,
    since: Date,
    until: Date
  ) throws -> [GitHubMergedPullRequest] {
    var after: String?
    var items: [GitHubMergedPullRequest] = []
    var hasNextPage = false

    repeat {
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
      let response = try JSONDecoder().decode(GitHubGraphQLSearchResponse.self, from: data)
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

final class FixtureGitHubAPITransport: GitHubAPITransport {
  var responses: [Data]
  private(set) var capturedRequests: [URLRequest] = []

  init(data: Data) {
    responses = [data]
  }

  init(responses: [Data]) {
    self.responses = responses
  }

  func data(for request: URLRequest) throws -> Data {
    capturedRequests.append(request)
    guard responses.isEmpty == false else {
      return Data()
    }
    return responses.removeFirst()
  }
}
