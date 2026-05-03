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
    let activities =
      repositories
      .filter(\.canPull)
      .map { $0.activity(bucketCount: bucketLabels.count) }

    return PRActivityStore(
      bucketLabels: bucketLabels,
      window: defaultWindow,
      refreshInterval: .daily,
      repositories: activities,
      refreshedAt: now
    )
  }
}

final class FixtureGitHubAPITransport: GitHubAPITransport {
  var data: Data
  private(set) var capturedRequests: [URLRequest] = []

  init(data: Data) {
    self.data = data
  }

  func data(for request: URLRequest) throws -> Data {
    capturedRequests.append(request)
    return data
  }
}
