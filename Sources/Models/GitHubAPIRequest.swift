import Foundation

struct GitHubAPIRequest: Equatable {
  var path: String
  var queryItems: [URLQueryItem] = []

  func urlRequest(
    token: String,
    baseURL: URL = URL(string: "https://api.github.com")!,
    timeoutInterval: TimeInterval = 20
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

  static func mergedPullRequests(
    repositoryID: String,
    since: Date,
    until: Date,
    page: Int = 1,
    perPage: Int = 100
  ) -> GitHubAPIRequest {
    let query = [
      "repo:\(repositoryID)",
      "is:pr",
      "is:merged",
      "merged:\(Self.dateString(since))..\(Self.dateString(until))",
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
