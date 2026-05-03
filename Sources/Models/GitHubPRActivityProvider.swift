import Foundation

protocol GitHubAPITransport {
  func data(for request: URLRequest) throws -> Data
}

struct GitHubPRActivityProvider: PRActivityProviding {
  var token: String
  var transport: GitHubAPITransport
  var bucketLabels: [String]
  var defaultWindow: ActivityWindow = .twoWeeks

  func load(now: Date = Date()) throws -> PRActivityStore {
    let request = try GitHubAPIRequest.userRepositories().urlRequest(token: token)
    let data = try transport.data(for: request)
    let repositories = try JSONDecoder().decode([GitHubRepository].self, from: data)
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

  private func activity(for repository: GitHubRepository, now: Date) throws -> RepositoryActivity {
    let since = startDate(now: now)
    let request = try GitHubAPIRequest.mergedPullRequests(
      repositoryID: repository.fullName,
      since: since,
      until: now
    )
    .urlRequest(token: token)
    let data = try transport.data(for: request)
    let response = try JSONDecoder().decode(
      GitHubMergedPullRequestSearchResponse.self,
      from: data
    )
    let series = PRActivityBucketSeries.weekly(
      mergedDates: response.items.map(\.mergedAt),
      bucketCount: bucketLabels.count,
      now: now
    )
    var activity = repository.activity(bucketCount: bucketLabels.count)
    activity.weeklyCounts = series.counts
    return activity
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
