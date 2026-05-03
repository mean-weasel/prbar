import Foundation

protocol GitHubAPITransport {
  func data(for request: URLRequest) throws -> Data
}

enum GitHubPRActivityProviderError: Error, Equatable {
  case incompleteSearchResults(repositoryID: String)
}

struct GitHubPRActivityProvider: PRActivityProviding {
  var token: String
  var transport: GitHubAPITransport
  var bucketLabels: [String]
  var defaultWindow: ActivityWindow = .twoWeeks
  private let repositoryPageSize = 100
  private let searchPageSize = 100

  func load(now: Date = Date()) throws -> PRActivityStore {
    let repositories = try repositories()
    let pullableRepositories = repositories.filter(\.canPull)
    let activities = try pullableRepositories.map { repository in
      try activity(for: repository, now: now)
    }
    let labels = PRActivityBucketSeries.weekly(
      mergedDates: [],
      bucketCount: bucketLabels.count,
      now: now
    )
    .labels

    return PRActivityStore(
      bucketLabels: labels,
      window: defaultWindow,
      refreshInterval: .daily,
      repositories: activities,
      refreshedAt: now
    )
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

  private func activity(for repository: GitHubRepository, now: Date) throws -> RepositoryActivity {
    let since = startDate(now: now)
    let mergedPullRequests = try mergedPullRequests(
      repositoryID: repository.fullName,
      since: since,
      until: now
    )
    let series = PRActivityBucketSeries.weekly(
      mergedDates: mergedPullRequests.map(\.mergedAt),
      bucketCount: bucketLabels.count,
      now: now
    )
    var activity = repository.activity(bucketCount: bucketLabels.count)
    activity.weeklyCounts = series.counts
    return activity
  }

  private func mergedPullRequests(repositoryID: String, since: Date, until: Date) throws
    -> [GitHubMergedPullRequest]
  {
    var page = 1
    var items: [GitHubMergedPullRequest] = []
    var totalCount = 0

    repeat {
      let request = try GitHubAPIRequest.mergedPullRequests(
        repositoryID: repositoryID,
        since: since,
        until: until,
        page: page,
        perPage: searchPageSize
      )
      .urlRequest(token: token)
      let data = try transport.data(for: request)
      let response = try JSONDecoder().decode(
        GitHubMergedPullRequestSearchResponse.self,
        from: data
      )
      guard response.incompleteResults == false else {
        throw GitHubPRActivityProviderError.incompleteSearchResults(repositoryID: repositoryID)
      }
      totalCount = response.totalCount
      items.append(contentsOf: response.items)
      page += 1
    } while items.count < totalCount

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
