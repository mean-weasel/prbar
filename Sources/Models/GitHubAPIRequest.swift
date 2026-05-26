import Foundation

struct GitHubAPIRequest: Equatable {
  var path: String
  var queryItems: [URLQueryItem] = []

  func urlRequest(
    token: String,
    baseURL: URL = URL(string: "https://api.github.com")!,
    timeoutInterval: TimeInterval = 20,
    eTag: String? = nil
  ) throws
    -> URLRequest
  {
    let urlComponents = URLComponents(
      url: baseURL.appendingPathComponent(path),
      resolvingAgainstBaseURL: false
    )
    guard var components = urlComponents else {
      throw GitHubAPIRequestError.invalidURL
    }
    components.queryItems = queryItems.isEmpty ? nil : queryItems

    guard let url = components.url else {
      throw GitHubAPIRequestError.invalidURL
    }

    var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    if let eTag {
      request.setValue(eTag, forHTTPHeaderField: "If-None-Match")
    }
    return request
  }

  static func userRepositories(page: Int = 1, perPage: Int = 100) -> GitHubAPIRequest {
    GitHubAPIRequest(
      path: "/user/repos",
      queryItems: [
        URLQueryItem(name: "affiliation", value: "owner,collaborator,organization_member"),
        URLQueryItem(name: "sort", value: "pushed"),
        URLQueryItem(name: "direction", value: "desc"),
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "page", value: "\(page)"),
      ]
    )
  }

  static func authenticatedUser() -> GitHubAPIRequest {
    GitHubAPIRequest(path: "/user")
  }

  static func userOrganizations() -> GitHubAPIRequest {
    GitHubAPIRequest(path: "/user/orgs")
  }

  static func latestReleases(
    repositoryID: String,
    page: Int = 1,
    perPage: Int = 1
  ) -> GitHubAPIRequest {
    GitHubAPIRequest(
      path: "/repos/\(repositoryID)/releases",
      queryItems: [
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "page", value: "\(page)"),
      ]
    )
  }

  static func tags(
    repositoryID: String,
    page: Int = 1,
    perPage: Int = 1
  ) -> GitHubAPIRequest {
    GitHubAPIRequest(
      path: "/repos/\(repositoryID)/tags",
      queryItems: [
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "page", value: "\(page)"),
      ]
    )
  }

  static func mergedPullRequests(
    repositoryID: String,
    since: Date,
    until: Date,
    page: Int = 1,
    perPage: Int = 100
  ) -> GitHubAPIRequest {
    // GitHub Search API treats the end date as exclusive when using date-only
    // format, so add one day to include PRs merged on the `until` date itself.
    let inclusiveUntil =
      Calendar(identifier: .gregorian).date(
        byAdding: .day, value: 1, to: until
      ) ?? until
    let query = [
      "repo:\(repositoryID)",
      "is:pr",
      "is:merged",
      "merged:\(Self.dateString(since))..\(Self.dateString(inclusiveUntil))",
    ].joined(separator: " ")

    return GitHubAPIRequest(
      path: "/search/issues",
      queryItems: [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "sort", value: "updated"),
        URLQueryItem(name: "order", value: "desc"),
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "page", value: "\(page)"),
      ]
    )
  }

  static func mergedPullRequests(
    owner: String,
    since: Date,
    until: Date,
    page: Int = 1,
    perPage: Int = 100
  ) -> GitHubAPIRequest {
    let inclusiveUntil =
      Calendar(identifier: .gregorian).date(
        byAdding: .day, value: 1, to: until
      ) ?? until
    let query = [
      "user:\(owner)",
      "is:pr",
      "is:merged",
      "merged:\(Self.dateString(since))..\(Self.dateString(inclusiveUntil))",
    ].joined(separator: " ")

    return GitHubAPIRequest(
      path: "/search/issues",
      queryItems: [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "sort", value: "updated"),
        URLQueryItem(name: "order", value: "desc"),
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "page", value: "\(page)"),
      ]
    )
  }

  private static func dateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}

enum GitHubAPIRequestError: Error, Equatable {
  case invalidURL
}
